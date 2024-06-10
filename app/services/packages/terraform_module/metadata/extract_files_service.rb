# frozen_string_literal: true

module Packages
  module TerraformModule
    module Metadata
      class ExtractFilesService
        MAX_FILE_SIZE = 3.megabytes
        MAX_PROCESSED_FILES_COUNT = 400
        README_FILES = %w[README.md README].freeze
        SUBMODULES_REGEX = /\bmodules\b/
        EXAMPLES_REGEX = /\bexamples\b/

        ExtractionError = Class.new(StandardError)

        def initialize(archive_file)
          @archive_file = archive_file
          @metadata = {}
        end

        def execute
          parse_file
          aggregate_metadata_into_root

          ServiceResponse.success(payload: metadata)
        end

        private

        attr_reader :archive_file, :metadata

        def parse_file
          Tempfile.create('extracted_terraform_module_metadata') do |tmp_file|
            process_archive do |entry|
              case entry
              when Gem::Package::TarReader::Entry
                process_tar_entry(tmp_file, entry)
              when Zip::Entry
                process_zip_entry(tmp_file, entry)
              end
            end
          end
        end

        def process_archive
          archive_file.each_with_index do |entry, index|
            raise ExtractionError, 'Too many files to process' if index >= MAX_PROCESSED_FILES_COUNT

            next unless entry.file? && entry.size <= MAX_FILE_SIZE

            yield(entry)
          end
        end

        def process_tar_entry(tmp_file, entry)
          module_type = module_type_from_path(entry.full_name)
          return unless module_type

          File.open(tmp_file.path, 'w+') do |file|
            IO.copy_stream(entry, file)
            file.rewind
            raise ExtractionError, 'metadata file has the wrong entry size' if File.size(file) > MAX_FILE_SIZE

            parse_and_merge_metadata(file, entry.full_name, module_type)
          end
        end

        def process_zip_entry(tmp_file, entry)
          module_type = module_type_from_path(entry.name)
          return unless module_type

          entry.extract(tmp_file.path) { true }
          File.open(tmp_file.path) do |file|
            parse_and_merge_metadata(file, entry.name, module_type)
          end
        rescue Zip::EntrySizeError => e
          raise ExtractionError, "metadata file has the wrong entry size: #{e.message}"
        end

        def module_type_from_path(path)
          return unless File.extname(path) == '.tf' || File.basename(path).in?(README_FILES)

          %i[root submodule example].detect do |type|
            method(:"#{type}?").call(path)
          end
        end

        def root?(path)
          File.dirname(path).exclude?('/') || (File.dirname(path).count('/') == 1 && path.start_with?('./'))
        end

        def submodule?(path)
          match_directory_pattern?(path, SUBMODULES_REGEX, 'modules')
        end

        def example?(path)
          match_directory_pattern?(path, EXAMPLES_REGEX, 'examples')
        end

        def match_directory_pattern?(path, regex, suffix)
          File.dirname(path).match?(regex) &&
            !File.dirname(path).end_with?(suffix) &&
            (File.dirname(path).count('/').in?([1, 2]) ||
            (File.dirname(path).count('/') == 3 && path.start_with?('./')))
        end

        def parse_and_merge_metadata(file, entry_name, module_type)
          parsed_content = ::Packages::TerraformModule::Metadata::ProcessFileService
                             .new(file, entry_name, module_type)
                             .execute
                             .payload

          deep_merge_metadata(parsed_content)
        end

        def deep_merge_metadata(parsed_content)
          return if parsed_content.empty?

          metadata.deep_merge!(parsed_content) do |_, old, new|
            [old, new].all?(Array) ? old.concat(new) : new
          end
        end

        def aggregate_metadata_into_root
          aggregate_submodules_and_examples(metadata[:submodules])
          aggregate_submodules_and_examples(metadata[:examples], clear_data: true)
        end

        def aggregate_submodules_and_examples(data, clear_data: false)
          return unless data

          ensure_root_metadata_exists

          data.each_value do |val|
            metadata[:root][:resources] |= val[:resources] || []
            metadata[:root][:dependencies][:modules] |= val.dig(:dependencies, :modules) || []
            metadata[:root][:dependencies][:providers] |= val.dig(:dependencies, :providers) || []

            val.except!(:resources, :dependencies) if clear_data
          end
        end

        def ensure_root_metadata_exists
          metadata[:root] ||= {}
          metadata[:root][:resources] ||= []
          metadata[:root][:dependencies] ||= {}
          metadata[:root][:dependencies][:modules] ||= []
          metadata[:root][:dependencies][:providers] ||= []
        end
      end
    end
  end
end
