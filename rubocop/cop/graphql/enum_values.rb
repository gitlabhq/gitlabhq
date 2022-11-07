# frozen_string_literal: true

# This cop enforces the enum value conventions from the enum style guide:
# https://docs.gitlab.com/ee/development/api_graphql_styleguide.html#enums
#
# @example
#
#   # bad
#   class BadEnum < BaseEnum
#     graphql_name 'Bad'
#
#     value 'foo'
#   end
#
#   class UngoodEnum < BaseEnum
#     graphql_name 'Ungood'
#
#     ['bar'].each do |val|
#       value val
#      end
#   end
#
#   # good
#   class GoodEnum < BaseEnum
#     graphql_name 'Good'
#
#     value 'FOO'
#   end
#
#   class GreatEnum < BaseEnum
#     graphql_name 'Great'
#
#     ['bar'].each do |val|
#       value val.upcase
#      end
#   end

module RuboCop
  module Cop
    module Graphql
      class EnumValues < RuboCop::Cop::Base
        MSG = "Enum values must either be an uppercase string literal or uppercased with the `upcase` method. " \
              "See https://docs.gitlab.com/ee/development/api_graphql_styleguide.html#enums"

        def_node_matcher :enum_value, <<~PATTERN
          (send nil? :value $_ $...)
        PATTERN

        def_node_search :deprecated?, <<~PATTERN
          (hash <(pair (sym :deprecated) _) ...>)
        PATTERN

        def_node_matcher :upcase_literal?, <<~PATTERN
          (str #upcase?)
        PATTERN

        def_node_matcher :upcase_method?, <<~PATTERN
          `(send _ :upcase)
        PATTERN

        def on_send(node)
          value_node, params = enum_value(node)

          return unless value_node
          return if params.any? { deprecated?(_1) }
          return if upcase_literal?(value_node) || upcase_method?(value_node)

          add_offense(value_node)
        end

        private

        def upcase?(str)
          str == str.upcase
        end
      end
    end
  end
end
