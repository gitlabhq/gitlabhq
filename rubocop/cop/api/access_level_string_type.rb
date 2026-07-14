# frozen_string_literal: true

module RuboCop
  module Cop
    module API
      # Checks that Grape API parameters and entity attributes for access
      # levels do not use an integer type. Use a string representation or
      # custom type instead.
      #
      # @example
      #
      #   # bad
      #   requires :access_level, type: Integer
      #   requires :access_level, types: [Integer, String]
      #   expose :access_level, documentation: { type: 'Integer' }
      #
      #   # good
      #   requires :access_level, type: String
      #   requires :access_level, types: [String]
      #   expose :access_level, documentation: { type: 'String' }
      #
      class AccessLevelStringType < RuboCop::Cop::Base
        PARAM_MSG = 'Do not use `type: Integer` or `types: [Integer, ...]` for access level parameters. ' \
          'Use `type: String` or a custom type instead to maintain API consistency.'

        EXPOSE_MSG = "Do not document access level entity attributes as `type: 'Integer'`. " \
          "Use `type: 'String'` or a custom type instead to maintain API consistency."

        RESTRICT_ON_SEND = %i[requires optional expose].freeze

        # @!method grape_api_param?(node)
        def_node_matcher :grape_api_param?, <<~PATTERN
          (call _ {:requires :optional}
            {(sym $_) (str $_)}
            $_ ...)
        PATTERN

        # @!method integer_type_pair?(node)
        def_node_matcher :integer_type_pair?, <<~PATTERN
          (pair (sym :type) (const {nil? cbase} :Integer))
        PATTERN

        # @!method integer_in_types_pair?(node)
        def_node_matcher :integer_in_types_pair?, <<~PATTERN
          (pair (sym :types) (array <(const {nil? cbase} :Integer) ...>))
        PATTERN

        # @!method grape_entity_expose?(node)
        def_node_matcher :grape_entity_expose?, <<~PATTERN
          (call _ :expose $...)
        PATTERN

        # @!method integer_documentation_pair?(node)
        def_node_matcher :integer_documentation_pair?, <<~PATTERN
          (pair (sym :documentation)
            (hash <(pair (sym :type) (str "Integer")) ...>))
        PATTERN

        # @!method as_pair?(node)
        def_node_matcher :as_pair?, <<~PATTERN
          (pair (sym :as) {(sym $_) (str $_)})
        PATTERN

        # @!method attribute_name?(node)
        def_node_matcher :attribute_name?, <<~PATTERN
          {(sym $_) (str $_)}
        PATTERN

        def on_send(node)
          if node.method?(:expose)
            check_expose(node)
          else
            check_param(node)
          end
        end
        alias_method :on_csend, :on_send

        private

        def check_param(node)
          grape_api_param?(node) do |param_name, options|
            next unless access_level_attribute?(param_name)
            next unless options.is_a?(RuboCop::AST::HashNode)
            next unless options.pairs.any? { |pair| integer_type_pair?(pair) || integer_in_types_pair?(pair) }

            add_offense(node, message: PARAM_MSG)
          end
        end

        def check_expose(node)
          grape_entity_expose?(node) do |*positional_args, options|
            next unless options.is_a?(RuboCop::AST::HashNode)
            next unless options.pairs.any? { |pair| integer_documentation_pair?(pair) }
            next unless access_level_expose?(positional_args, options)

            add_offense(node, message: EXPOSE_MSG)
          end
        end

        def access_level_expose?(positional_args, options)
          positional_args.each do |arg|
            name = attribute_name?(arg)
            return true if name && access_level_attribute?(name)
          end

          options.pairs.each do |pair|
            aliased_name = as_pair?(pair)
            return true if aliased_name && access_level_attribute?(aliased_name)
          end

          false
        end

        def access_level_attribute?(name)
          name.to_s.include?('access_level')
        end
      end
    end
  end
end
