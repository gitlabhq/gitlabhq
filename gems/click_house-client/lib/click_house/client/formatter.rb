# frozen_string_literal: true

module ClickHouse
  module Client
    class Formatter
      DEFAULT = ->(value) { value }

      BASIC_TYPE_CASTERS = {
        'UInt64' => ->(value) { Integer(value) },
        "DateTime64(6, 'UTC')" => ->(value) { ActiveSupport::TimeZone['UTC'].parse(value) },
        "IntervalSecond" => ->(value) { ActiveSupport::Duration.build(value.to_i) },
        "IntervalMillisecond" => ->(value) { ActiveSupport::Duration.build(value.to_i / 1000.0) }
      }.freeze

      TYPE_CASTERS = BASIC_TYPE_CASTERS.merge(
        BASIC_TYPE_CASTERS.transform_keys { |type| "Nullable(#{type})" }
          .transform_values { |caster| ->(value) { value.nil? ? nil : caster.call(value) } }
      )

      def self.format(result)
        name_type_mapping = result['meta'].each_with_object({}) do |column, hash|
          hash[column['name']] = column['type']
        end

        result['data'].map do |row|
          row.each_with_object({}) do |(column, value), casted_row|
            caster = TYPE_CASTERS.fetch(name_type_mapping[column], DEFAULT)

            casted_row[column] = caster.call(value)
          end
        end
      end
    end
  end
end
