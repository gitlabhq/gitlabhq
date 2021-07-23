# frozen_string_literal: true

# This cop checks for missing GraphQL descriptions and enforces the description style guide:
# https://docs.gitlab.com/ee/development/api_graphql_styleguide.html#description-style-guide
#
# @examples
#
#   # bad
#   class AwfulType
#     field :some_field, GraphQL::Types::String
#   end
#
#   class TerribleType
#     argument :some_argument, GraphQL::Types::String
#   end
#
#   class UngoodType
#     field :some_argument,
#       GraphQL::Types::String,
#       description: "A description that does not end in a period"
#   end
#
#   class BadEnum
#     value "some_value"
#   end
#
#   # good
#   class GreatType
#     argument :some_field,
#       GraphQL::Types::String,
#       description: "Well described - a superb description."
#
#     field :some_field,
#       GraphQL::Types::String,
#       description: "A thorough and compelling description."
#   end
#
#   class GoodEnum
#     value "some_value", "Good description."
#   end

module RuboCop
  module Cop
    module Graphql
      class Descriptions < RuboCop::Cop::Cop
        MSG_NO_DESCRIPTION = 'Please add a `description` property.'
        MSG_NO_PERIOD = '`description` strings must end with a `.`.'

        def_node_matcher :graphql_describable?, <<~PATTERN
          (send nil? {:field :argument :value} ...)
        PATTERN

        def_node_matcher :enum?, <<~PATTERN
          (send nil? :value ...)
        PATTERN

        def_node_matcher :resolver_kwarg, <<~PATTERN
          (... (hash <(pair (sym :resolver) $_) ...>))
        PATTERN

        def_node_matcher :description_kwarg, <<~PATTERN
          (... (hash <(pair (sym :description) $_) ...>))
        PATTERN

        def_node_matcher :enum_style_description, <<~PATTERN
          (send nil? :value _ $str ...)
        PATTERN

        def on_send(node)
          return unless graphql_describable?(node)
          return if resolver_kwarg(node) # Fields may inherit the description from their resolvers.

          description = locate_description(node)

          return add_offense(node, location: :expression, message: MSG_NO_DESCRIPTION) unless description

          add_offense(node, location: :expression, message: MSG_NO_PERIOD) if no_period?(description)
        end

        # Autocorrect missing periods at end of description.
        def autocorrect(node)
          lambda do |corrector|
            description = locate_description(node)
            next unless description

            corrector.insert_after(before_end_quote(description), '.')
          end
        end

        private

        # Fields and arguments define descriptions using a `description` keyword argument.
        # Enums may define descriptions this way, or as a second `String` param.
        def locate_description(node)
          description = description_kwarg(node)

          return description unless description.nil? && enum?(node)

          enum_style_description(node)
        end

        def no_period?(description)
          # Test that the description node is a `:str` (as opposed to
          # a `#copy_field_description` call) before checking.
          description.type == :str && !description.value.strip.end_with?('.')
        end

        # Returns a Parser::Source::Range that ends just before the final String delimiter.
        def before_end_quote(string)
          return string.source_range.adjust(end_pos: -1) unless string.heredoc?

          heredoc_source = string.location.heredoc_body.source
          adjust = heredoc_source.index(/\s+\Z/) - heredoc_source.length
          string.location.heredoc_body.adjust(end_pos: adjust)
        end
      end
    end
  end
end
