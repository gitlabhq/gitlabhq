# frozen_string_literal: true

module Packages
  module TerraformModule
    module Metadata
      class ProcessFileService
        README_FILES = %w[README.md README].freeze

        def initialize(file, path, module_type)
          @file = file
          @path = path
          @module_type = module_type
        end

        def execute
          result = README_FILES.include?(file_name) ? parse_readme : parse_tf_file

          ServiceResponse.success(payload: result)
        rescue StandardError => e
          Gitlab::ErrorTracking.track_exception(
            e,
            class: self.class.name
          )

          ServiceResponse.error(message: "Error processing #{file_name}")
        end

        private

        attr_reader :file, :path, :module_type

        def file_name
          File.basename(path)
        end

        def module_name
          File.basename(dirname)
        end

        def dirname
          File.dirname(path)
        end

        def parse_readme
          build_module_type_hash(:readme, file.read)
        end

        def parse_tf_file
          parsed_hcl = ::Packages::TerraformModule::Metadata::ParseHclFileService.new(file).execute.payload

          merge_module_type_hashes(parsed_hcl)
        end

        def merge_module_type_hashes(parsed_hcl)
          build_module_type_hash(:resources, parsed_hcl[:resources])
            .deep_merge(build_module_type_hash(:dependencies,
              { providers: parsed_hcl[:providers], modules: parsed_hcl[:modules] }))
            .deep_merge(build_module_type_hash(:inputs, parsed_hcl[:variables]))
            .deep_merge(build_module_type_hash(:outputs, parsed_hcl[:outputs]))
        end

        def build_module_type_hash(key, content)
          case module_type
          when :root
            { root: { key => content } }
          when :submodule
            { submodules: { module_name => { key => content } } }
          when :example
            { examples: { module_name => { key => content } } }
          end
        end
      end
    end
  end
end
