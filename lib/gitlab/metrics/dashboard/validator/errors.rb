# frozen_string_literal: true

module Gitlab
  module Metrics
    module Dashboard
      module Validator
        module Errors
          InvalidDashboardError = Class.new(StandardError)

          class SchemaValidationError < InvalidDashboardError
            def initialize(error = {})
              super(error_message(error))
            end

            private

            def error_message(error)
              if error.is_a?(Hash) && error.present?
                pretty(error)
              else
                "Dashboard failed schema validation"
              end
            end

            # based on https://github.com/davishmcclurg/json_schemer/blob/master/lib/json_schemer/errors.rb
            # with addition ability to translate error messages
            def pretty(error)
              data, data_pointer, type, schema = error.values_at('data', 'data_pointer', 'type', 'schema')
              location = data_pointer.empty? ? 'root' : data_pointer

              case type
              when 'required'
                keys = error.fetch('details').fetch('missing_keys').join(', ')
                _("%{location} is missing required keys: %{keys}") % { location: location, keys: keys }
              when 'null', 'string', 'boolean', 'integer', 'number', 'array', 'object'
                _("'%{data}' at %{location} is not of type: %{type}") % { data: data, location: location, type: type }
              when 'pattern'
                _("'%{data}' at %{location} does not match pattern: %{pattern}") % { data: data, location: location, pattern: schema.fetch('pattern') }
              when 'format'
                _("'%{data}' at %{location} does not match format: %{format}") % { data: data, location: location, format: schema.fetch('format') }
              when 'const'
                _("'%{data}' at %{location} is not: %{const}") % { data: data, location: location, const: schema.fetch('const').inspect }
              when 'enum'
                _("'%{data}' at %{location} is not one of: %{enum}") % { data: data, location: location, enum: schema.fetch('enum') }
              else
                _("'%{data}' at %{location} is invalid: error_type=%{type}") % { data: data, location: location, type: type }
              end
            end
          end

          class DuplicateMetricIds < InvalidDashboardError
            def initialize
              super(_("metric_id must be unique across a project"))
            end
          end
        end
      end
    end
  end
end
