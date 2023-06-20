# frozen_string_literal: true

# This cop enforces the enum naming conventions from the enum style guide:
# https://docs.gitlab.com/ee/development/api_graphql_styleguide.html#enums
#
# @example
#
#   # bad
#   class FooBar < BaseEnum
#     value 'FOO'
#   end
#
#   class SubparEnum < BaseEnum
#   end
#
#   class UngoodEnum < BaseEnum
#     graphql_name 'UngoodEnum'
#   end
#
#   # good
#
#   class GreatEnum < BaseEnum
#     graphql_name 'Great'
#
#     value 'BAR'
#   end
#
#   class NiceEnum < BaseEnum
#     declarative_enum NiceDeclarativeEnum
#   end

module RuboCop
  module Cop
    module Graphql
      class EnumNames < RuboCop::Cop::Base
        SEE_SG_MSG = "See https://docs.gitlab.com/ee/development/api_graphql_styleguide.html#enums"
        CLASS_NAME_SUFFIX_MSG = "Enum class names must end with `Enum`. #{SEE_SG_MSG}".freeze
        GRAPHQL_NAME_MISSING_MSG = "A `graphql_name` must be defined for a GraphQL enum. #{SEE_SG_MSG}".freeze
        GRAPHQL_NAME_WITH_ENUM_MSG = "The `graphql_name` must not contain the string \"Enum\". #{SEE_SG_MSG}".freeze

        def_node_matcher :enum_subclass, <<~PATTERN
          (class $(const nil? _) (const {nil? cbase} /.*Enum$/) ...)
        PATTERN

        def_node_search :find_graphql_name, <<~PATTERN
          (... `(send nil? :graphql_name $(...)) ...)
        PATTERN

        def_node_search :declarative_enum?, <<~PATTERN
          (... (send nil? :declarative_enum ...) ...)
        PATTERN

        def on_class(node)
          const_node = enum_subclass(node)
          return unless const_node

          check_class_name(const_node)
          check_graphql_name(node)
        end

        private

        def check_class_name(const_node)
          return unless const_node&.const_name
          return if const_node.const_name.end_with?('Enum')

          add_offense(const_node, message: CLASS_NAME_SUFFIX_MSG)
        end

        def check_graphql_name(node)
          graphql_name_node = find_graphql_name(node)&.first

          if graphql_name_node
            return unless graphql_name_node&.str_content
            return unless graphql_name_node.str_content.downcase.include?('enum')

            add_offense(graphql_name_node, message: GRAPHQL_NAME_WITH_ENUM_MSG)
          else
            return if declarative_enum?(node)

            add_offense(node, message: GRAPHQL_NAME_MISSING_MSG)
          end
        end
      end
    end
  end
end
