# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      class QueryPlan
        class BasePart
          attr_reader :definition, :configuration

          delegate :name, :type, to: :definition

          def initialize(definition, configuration)
            @definition = definition
            @configuration = configuration
          end

          def instance_key
            definition.instance_key(**configuration)
          end
        end
      end
    end
  end
end
