# frozen_string_literal: true

module Gitlab
  module Metrics
    module Dashboard
      module Validator
        class Client
          # @param content [Hash] Representing a raw, unprocessed
          # dashboard object
          # @param schema_path [String] Representing path to dashboard schema file
          # @param dashboard_path[String] Representing path to dashboard content file
          # @param project [Project] Project to validate dashboard against
          def initialize(content, schema_path, dashboard_path: nil, project: nil)
            @content = content
            @schema_path = schema_path
            @dashboard_path = dashboard_path
            @project = project
          end

          def execute
            errors = validate_against_schema
            errors += post_schema_validator.validate

            errors.compact
          end

          private

          attr_reader :content, :schema_path, :project, :dashboard_path

          def custom_formats
            @custom_formats ||= CustomFormats.new
          end

          def post_schema_validator
            PostSchemaValidator.new(
              project:        project,
              metric_ids:     custom_formats.metric_ids_cache,
              dashboard_path: dashboard_path
            )
          end

          def schemer
            @schemer ||= ::JSONSchemer.schema(Pathname.new(schema_path), formats: custom_formats.format_handlers)
          end

          def validate_against_schema
            schemer.validate(content).map do |error|
              ::Gitlab::Metrics::Dashboard::Validator::Errors::SchemaValidationError.new(error)
            end
          end
        end
      end
    end
  end
end
