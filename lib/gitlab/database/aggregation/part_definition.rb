# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      class PartDefinition
        attr_reader :name, :type, :expression, :secondary_expression, :description, :formatter

        # @param name [Symbol] the name of the part
        # @param type [Symbol] part data type (integer, float, string etc)
        # @param expression [Proc] Arel expression for the part. Implementation specific
        # @param secondary_expression [Proc] Secondary arel expression for the part. Implementation specific
        # @param description [String] Description of the part
        # @param formatter [Proc] formatting block to apply after DB loading.
        def initialize(name, type, expression = nil, secondary_expression: nil, description: nil, formatter: nil, **)
          @name = name
          @type = type
          @expression = expression
          @secondary_expression = secondary_expression
          @description = description
          @formatter = formatter
        end

        def to_hash
          {
            identifier: identifier,
            name: name,
            type: type,
            description: description
          }
        end

        def format_value(val)
          formatter ? formatter.call(val) : val
        end

        # part identifier. Must be unique across all part definitions.
        def identifier
          name
        end

        # Returns unique key for each part configuration in given request.
        # For definitions without configration the key is static
        # For definitions with configuration the key depends on
        # the configuration parameters
        # Must be unique across all QueryPlan parts.
        def instance_key(_configuration)
          identifier.to_s
        end
      end
    end
  end
end
