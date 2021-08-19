# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        module Validators
          class SchemaValidator
            class Schema
              def root_path
                File.join(__dir__, 'schemas')
              end

              def initialize(report_type)
                @report_type = report_type
              end

              delegate :validate, to: :schemer

              private

              attr_reader :report_type

              def schemer
                JSONSchemer.schema(pathname)
              end

              def pathname
                Pathname.new(schema_path)
              end

              def schema_path
                File.join(root_path, file_name)
              end

              def file_name
                "#{report_type}.json"
              end
            end

            def initialize(report_type, report_data)
              @report_type = report_type
              @report_data = report_data
            end

            def valid?
              errors.empty?
            end

            def errors
              @errors ||= schema.validate(report_data).map { |error| JSONSchemer::Errors.pretty(error) }
            end

            private

            attr_reader :report_type, :report_data

            def schema
              Schema.new(report_type)
            end
          end
        end
      end
    end
  end
end

Gitlab::Ci::Parsers::Security::Validators::SchemaValidator::Schema.prepend_mod_with("Gitlab::Ci::Parsers::Security::Validators::SchemaValidator::Schema")
