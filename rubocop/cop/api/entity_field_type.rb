# frozen_string_literal: true

require_relative '../../code_reuse_helpers'

module RuboCop
  module Cop
    module API
      # Checks that in API Entity fields define a valid type.
      # Types must be strings and can be defined in the documentation hash or `using:` option
      #
      # @example
      #
      #   # bad
      #     expose :relation, documentation: { type: 'string', example: 'label' }
      #
      #   # bad
      #     expose :relation, documentation: { type: :string, example: 'label' }
      #
      #   # bad
      #     expose :relation, documentation: { type: :string, example: 'label' }
      #
      #   # bad
      #     expose :relation, documentation: { example: 'label' }
      #
      #   # bad
      #     expose :relation, documentation: { type: String, example: 'label' }
      #
      #   # bad
      #     expose :relation, documentation: { type: 'UnknownClass', example: 'label' }
      #
      #   # bad
      #     expose :relation, using: API::Entities::SomeType, documentation: { example: 'label' }
      #
      #   # good
      #     expose :relation, documentation: { type: 'String', example: 'label' }
      #
      #   # good
      #     expose :relation, using: 'API::Entities::SomeType', documentation: { example: 'label' }
      #
      #   # good
      #     expose :relation, documentation: { type: 'API::Entities::SomeType', example: 'label' }
      #
      class EntityFieldType < RuboCop::Cop::Base
        include CodeReuseHelpers
        extend AutoCorrector

        # Valid primitive types that can be used as constants or strings
        PRIMITIVES = %w[Integer Float BigDecimal Numeric Date DateTime Time String Symbol Boolean].freeze
        STRUCTURES = %w[Hash Array Set].freeze
        SPECIAL = %w[JSON File].freeze
        VALID_TYPES = (PRIMITIVES + STRUCTURES + SPECIAL).freeze

        MSG = 'Invalid type for entity field. https://docs.gitlab.com/development/api_styleguide#defining-entity-fields.'
        MISSING_TYPE = 'Entity field is missing type declaration. https://docs.gitlab.com/development/api_styleguide#defining-entity-fields.'

        RESTRICT_ON_SEND = %i[expose].freeze

        # @!method documentation_type(node)
        def_node_matcher :documentation_type, <<~PATTERN
          (send nil? :expose _
            (hash <(pair (sym :documentation)
              (hash <(pair (sym :type) $_) ...>)
            ) ...>)
          )
        PATTERN

        # @!method using_value(node)
        def_node_matcher :using_value, <<~PATTERN
          (send nil? :expose _
            (hash <(pair (sym :using) $_) ...>)
          )
        PATTERN

        # @!method api_entity_string_type?(node)
        def_node_matcher :api_entity_string_type?, '(str /^(::)?API::Entities::/)'

        def on_send(node)
          using_node = using_value(node)
          type_node = documentation_type(node)

          if using_node
            unless valid_using_type?(using_node)
              add_offense(using_node) do |corrector|
                corrected_value = corrected_using_value(using_node)
                corrector.replace(using_node, "'#{corrected_value}'") if corrected_value
              end
            end
          elsif type_node.nil?
            add_offense(node, message: MISSING_TYPE)
          elsif invalid_type?(type_node)
            add_offense(type_node) do |corrector|
              corrected_value = corrected_type_value(type_node)
              corrector.replace(type_node, "'#{corrected_value}'") if corrected_value
            end
          end
        end
        alias_method :on_csend, :on_send

        private

        def valid_using_type?(node)
          api_entity_string_type?(node)
        end

        def invalid_type?(node)
          !node.str_type? || !valid_string_type?(node)
        end

        def valid_string_type?(node)
          VALID_TYPES.include?(node.value) || api_entity_string_type?(node)
        end

        def corrected_type_value(node)
          case node.type
          when :str
            # Handle lowercase string like 'string' -> 'String'
            capitalized = node.value.capitalize
            return capitalized if VALID_TYPES.include?(capitalized)
          when :sym
            # Handle symbol like :string -> 'String'
            capitalized = node.value.to_s.capitalize
            return capitalized if VALID_TYPES.include?(capitalized)
          when :const
            # Handle constant like String -> 'String'
            const_name = node.source.split('::').last
            return const_name if VALID_TYPES.include?(const_name)

            # Handle API::Entities::SomeType -> 'API::Entities::SomeType'
            return node.source if node.source.match?(/\A(::)?API::Entities::/)
          end

          nil
        end

        def corrected_using_value(node)
          # using: can only be API::Entities constants converted to strings
          return node.source if node.const_type? && node.source.match?(/\A(::)?API::Entities::/)

          nil
        end
      end
    end
  end
end
