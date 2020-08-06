# frozen_string_literal: true

module Gitlab
  module Metrics
    module Dashboard
      module Validator
        class CustomFormats
          def format_handlers
            # Key is custom JSON Schema format name. Value is a proc that takes data and schema and handles
            # validations.
            @format_handlers ||= {
              "add_to_metric_id_cache" => ->(data, schema) { metric_ids_cache << data }
            }
          end

          def metric_ids_cache
            @metric_ids_cache ||= []
          end
        end
      end
    end
  end
end
