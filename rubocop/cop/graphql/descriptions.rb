# frozen_string_literal: true

# This cop checks for missing GraphQL field descriptions.
#
# @example
#
#   # bad
#   class AwfulClass
#     field :some_field, GraphQL::STRING_TYPE
#   end
#
#   class TerribleClass
#     argument :some_argument, GraphQL::STRING_TYPE
#   end
#
#   class UngoodClass
#     field :some_argument,
#       GraphQL::STRING_TYPE,
#       description: "A description that does not end in a period"
#   end
#
#   # good
#   class GreatClass
#     argument :some_field,
#       GraphQL::STRING_TYPE,
#       description: "Well described - a superb description."
#
#     field :some_field,
#       GraphQL::STRING_TYPE,
#       description: "A thorough and compelling description."
#   end

module RuboCop
  module Cop
    module Graphql
      class Descriptions < RuboCop::Cop::Cop
        MSG_NO_DESCRIPTION = 'Please add a `description` property.'
        MSG_NO_PERIOD = '`description` strings must end with a `.`.'

        # ability_field and permission_field set a default description.
        def_node_matcher :field_or_argument?, <<~PATTERN
          (send nil? {:field :argument} ...)
        PATTERN

        def_node_matcher :description, <<~PATTERN
          (... (hash <(pair (sym :description) $_) ...>))
        PATTERN

        def on_send(node)
          return unless field_or_argument?(node)

          description = description(node)

          return add_offense(node, location: :expression, message: MSG_NO_DESCRIPTION) unless description

          add_offense(node, location: :expression, message: MSG_NO_PERIOD) if no_period?(description)
        end

        # Autocorrect missing periods at end of description.
        def autocorrect(node)
          lambda do |corrector|
            description = description(node)
            next unless description

            corrector.insert_after(before_end_quote(description), '.')
          end
        end

        private

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
