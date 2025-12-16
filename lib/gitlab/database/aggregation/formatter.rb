# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      class Formatter
        def initialize(engine, plan)
          @engine = engine
          @plan = plan
        end

        def format_data(data)
          data.map { |row| format_row(row) }
        end

        private

        def format_row(row)
          row.to_h do |key, value|
            part = detect_part(key)

            formatted_value = part ? part.definition.format_value(value) : value

            [key, formatted_value]
          end
        end

        def detect_part(key)
          @plan.parts.detect { |p| p.instance_key == key }
        end
      end
    end
  end
end
