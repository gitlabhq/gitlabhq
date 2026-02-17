# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      class QueryPlan
        class BasePart
          include ActiveModel::Validations

          attr_reader :definition, :configuration

          delegate :name, :type, :identifier, to: :definition

          validate :validate_definition_presence
          validate -> { definition&.validate_part(self) }

          def initialize(definition, configuration)
            @definition = definition
            @configuration = configuration
          end

          def instance_key
            definition.instance_key(configuration)
          end

          private

          def validate_definition_presence
            return if definition

            errors.add(:base, format(s_("AggregationEngine|the specified identifier is not available: '%{identifier}'"),
              identifier: configuration[:identifier]))
          end
        end
      end
    end
  end
end
