# frozen_string_literal: true

# This cop checks for missing GraphQL descriptions and enforces the description style guide:
# https://docs.gitlab.com/ee/development/api_graphql_styleguide.html#description-style-guide
#
# @safety
#   This cop is unsafe because not all cases of "this" can be substituted with
#   "the". This will require a technical writer to assist with the alternative,
#   proper grammar that can be used for that particular GraphQL descriptions.
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
#       description: "Thorough and compelling description."
#   end
#
#   class GoodEnum
#     value "some_value", "Good description."
#   end

module RuboCop
  module Cop
    module Graphql
      class Descriptions < RuboCop::Cop::Base
        extend RuboCop::Cop::AutoCorrector

        MSG_STYLE_GUIDE_LINK = 'See the description style guide: https://docs.gitlab.com/ee/development/api_graphql_styleguide.html#description-style-guide'
        MSG_NO_DESCRIPTION = "Please add a `description` property. #{MSG_STYLE_GUIDE_LINK}".freeze
        MSG_NO_PERIOD = "`description` strings must end with a `.`. #{MSG_STYLE_GUIDE_LINK}".freeze
        MSG_BAD_START = "`description` strings should not start with \"A...\" or \"The...\". "\
          "#{MSG_STYLE_GUIDE_LINK}".freeze
        MSG_CONTAINS_THIS = "`description` strings should not contain the demonstrative \"this\". "\
          "#{MSG_STYLE_GUIDE_LINK}".freeze

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

          message = if description.nil?
                      MSG_NO_DESCRIPTION
                    elsif no_period?(description)
                      MSG_NO_PERIOD
                    elsif bad_start?(description)
                      MSG_BAD_START
                    elsif contains_demonstrative_this?(description)
                      MSG_CONTAINS_THIS
                    end

          return unless message

          add_offense(node, message: message) do |corrector|
            next unless description

            corrector.insert_after(before_end_quote(description), '.') if no_period?(description)
            corrector.replace(locate_this(description), 'the') if contains_demonstrative_this?(description)
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
          string?(description) && !description.value.strip.end_with?('.')
        end

        def bad_start?(description)
          string?(description) && description.value.strip.downcase.start_with?('a ', 'the ')
        end

        def contains_demonstrative_this?(description)
          string?(description) && /\bthis\b/.match?(description.value.strip)
        end

        # Returns true if `description` node is a `:str` (as opposed to a `#copy_field_description` call)
        def string?(description)
          description.type == :str
        end

        # Returns a `Parser::Source::Range` that ends just before the final `String` delimiter.
        def before_end_quote(string)
          return string.source_range.adjust(end_pos: -1) unless string.heredoc?

          heredoc_source = string.location.heredoc_body.source
          adjust = heredoc_source.index(/\s+\Z/) - heredoc_source.length
          string.location.heredoc_body.adjust(end_pos: adjust)
        end

        # Returns a `Parser::Source::Range` of the first `this` encountered
        def locate_this(string)
          target = 'this'
          range = string.heredoc? ? string.location.heredoc_body : string.location.expression
          index = range.source.index(target)
          range.adjust(begin_pos: index, end_pos: (index + target.length) - range.length)
        end
      end
    end
  end
end
