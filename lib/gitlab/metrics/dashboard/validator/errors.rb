# frozen_string_literal: true

module Gitlab
  module Metrics
    module Dashboard
      module Validator
        module Errors
          InvalidDashboardError = Class.new(StandardError)

          class SchemaValidationError < InvalidDashboardError
            def initialize(error = {})
              if error.is_a?(Hash) && error.present?
                data            = error["data"]
                data_pointer    = error["data_pointer"]
                schema          = error["schema"]
                schema_pointer  = error["schema_pointer"]

                msg = _("'%{data}' is invalid at '%{data_pointer}'. Should be '%{schema}' due to schema definition at '%{schema_pointer}'") %
                  { data: data, data_pointer: data_pointer, schema: schema, schema_pointer: schema_pointer }
              else
                msg = "Dashboard failed schema validation"
              end

              super(msg)
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
