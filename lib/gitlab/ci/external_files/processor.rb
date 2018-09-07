module Gitlab
  module Ci
    module ExternalFiles
      class Processor
        ExternalFileError = Class.new(StandardError)

        def initialize(values, project)
          @values = values
          @external_files = ::Gitlab::Ci::ExternalFiles::Mapper.new(values, project).process
        end

        def perform
          return values if external_files.empty?

          external_files.each do |external_file|
            validate_external_file(external_file)
            append_external_content(external_file)
          end

          remove_include_keyword
        end

        private

        attr_reader :values, :external_files

        def validate_external_file(external_file)
          unless external_file.valid?
            raise ExternalFileError, "External file: '#{external_file.value}' should be a valid local or remote file"
          end
        end

        def append_external_content(external_file)
          external_values = ::Gitlab::Ci::Config::Loader.new(external_file.content).load!
          @values.merge!(external_values)
        end

        def remove_include_keyword
          values.delete(:include)
          values
        end
      end
    end
  end
end
