# frozen_string_literal: true

module Packages
  module TerraformModule
    module Metadata
      class ExtractFilesService
        MAX_FILE_SIZE = 3.megabytes
        README_FILES = %w[README.md README].freeze

        ExtractionError = Class.new(StandardError)

        def initialize(archive_file)
          @archive_file = archive_file
          @metadata = {}
        end

        def execute
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

          ServiceResponse.success(payload: metadata)
        end

        private

        attr_reader :archive_file, :metadata

        def process_archive
          archive_file.each do |entry|
            next unless entry.file? && entry.size <= MAX_FILE_SIZE

            yield(entry)
          end
        end

        def process_tar_entry(tmp_file, entry)
          return unless metadata_file?(entry.full_name)

          File.open(tmp_file.path, 'w+') do |file|
            IO.copy_stream(entry, file)
            file.rewind
            raise ExtractionError, 'metadata file has the wrong entry size' if File.size(file) > MAX_FILE_SIZE

            parse_and_merge_metadata(file, entry.full_name)
          end
        end

        def process_zip_entry(tmp_file, entry)
          return unless metadata_file?(entry.name)

          entry.extract(tmp_file.path) { true }
          File.open(tmp_file.path) do |file|
            parse_and_merge_metadata(file, entry.name)
          end
        rescue Zip::EntrySizeError => e
          raise ExtractionError, "metadata file has the wrong entry size: #{e.message}"
        end

        def metadata_file?(entry_name)
          File.extname(entry_name) == '.tf' || File.basename(entry_name).in?(README_FILES)
        end

        def parse_and_merge_metadata(file, entry_name)
          # Here we would call the ParseFileService to parse the file and extract the metadata.
          # For now, we'll just return the file size & name as a placeholder.
          metadata[entry_name] = "Size: #{file.size}"
        end
      end
    end
  end
end
