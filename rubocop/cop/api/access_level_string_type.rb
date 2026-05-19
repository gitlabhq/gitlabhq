# frozen_string_literal: true

module RuboCop
  module Cop
    module API
      # Checks that Grape API parameters for access levels do not use
      # `type: Integer` or `types: [Integer, ...]`. Use a string
      # representation or custom type instead.
      #
      # @example
      #
      #   # bad
      #   requires :access_level, type: Integer
      #   requires :access_level, types: [Integer, String]
      #
      #   # good
      #   requires :access_level, type: String
      #   requires :access_level, types: [String]
      #
      class AccessLevelStringType < RuboCop::Cop::Base
        MSG = 'Do not use `type: Integer` or `types: [Integer, ...]` for access level parameters. ' \
          'Use `type: String` or a custom type instead to maintain API consistency.'

        RESTRICT_ON_SEND = %i[requires optional].freeze

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

        def on_send(node)
          grape_api_param?(node) do |param_name, options|
            next unless access_level_param?(param_name)
            next unless options.is_a?(RuboCop::AST::HashNode)
            next unless options.pairs.any? { |pair| integer_type_pair?(pair) || integer_in_types_pair?(pair) }

            add_offense(node)
          end
        end
        alias_method :on_csend, :on_send

        private

        def access_level_param?(name)
          name.to_s.include?('access_level')
        end
      end
    end
  end
end
