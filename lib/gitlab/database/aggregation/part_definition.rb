# frozen_string_literal: true

module Gitlab
  module Database
    module Aggregation
      class PartDefinition
        IDENTIFIER_SEGMENT_FORMAT = /\A[a-z][a-z0-9_]*\z/

        attr_reader :name, :type, :expression, :secondary_expression, :description, :formatter, :authorize

        # @param name [Symbol] the name of the part
        # @param type [Symbol] part data type (integer, float, string etc)
        # @param expression [Proc] Arel expression for the part. Implementation specific
        # @param secondary_expression [Proc] Secondary arel expression for the part. Implementation specific
        # @param description [String] Description of the part
        # @param formatter [Proc] formatting block to apply after DB loading.
        # @param authorize [Symbol, #call] extra authorization required to use the part; an ability
        #   Symbol is converted to a callable checking `Ability.allowed?` against every resource, so
        #   `authorize` is always stored as a callable invoked with `(user, resources)`.
        #   Evaluated by `Gitlab::Database::Aggregation::Authorization`.
        def initialize(
          name, type, expression = nil, secondary_expression: nil, description: nil, formatter: nil,
          authorize: nil, **)
          @name = name
          @type = type
          @expression = expression
          @secondary_expression = secondary_expression
          @description = description
          @formatter = formatter
          @authorize = Authorization.ability_check(authorize)

          validate_name!
        end

        def format_value(val)
          formatter ? formatter.call(val) : val
        end

        def validate_part(_plan_part)
          # no-op by default
        end

        # definitions are not parameterized by default. use `ParameterizedDefinition` module
        # to enable parameters if needed
        def parameterized?
          false
        end

        # part identifier. Must be unique across all part definitions.
        def identifier
          name
        end

        # Segments of the identifier: one segment for a plain identifier,
        # two for a dotted identifier (`duration.max` => [:duration, :max]).
        def identifier_parts
          @identifier_parts ||= identifier.to_s.split('.', -1).map(&:to_sym)
        end

        # Returns unique key for each part configuration in given request.
        # For definitions without configration the key is static
        # For definitions with configuration the key depends on
        # the configuration parameters
        # Must be unique across all QueryPlan parts.
        def instance_key(_configuration)
          identifier_parts.join('__')
        end

        private

        # Only metric definitions support dotted names; dimensions and filters do not.
        def supports_dotted_identifier?
          false
        end

        def dotted_name?
          name.to_s.include?('.')
        end

        def validate_name!
          return unless dotted_name?

          unless supports_dotted_identifier?
            raise ArgumentError, "Dotted name `#{name}` is not supported for #{self.class.name}"
          end

          return if identifier_parts.size == 2 &&
            identifier_parts.all? { |segment| IDENTIFIER_SEGMENT_FORMAT.match?(segment.to_s) }

          raise ArgumentError,
            "Invalid dotted name `#{name}`: expected exactly two dot-separated segments " \
              "matching #{IDENTIFIER_SEGMENT_FORMAT.inspect}"
        end

        def source_column
          dotted_name? ? identifier_parts.first : name
        end
      end
    end
  end
end
