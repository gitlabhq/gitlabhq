# frozen_string_literal: true

module RuboCop
  module Cop
    module API
      # Enforces a compliant `desc:` on any Grape API parameter using `same_as:`
      #
      #  https://github.com/ruby-grape/grape#same_as
      #
      # @example
      #
      #   # bad
      #   requires :other_id, type: Integer, same_as: :id, desc: "Another id"
      #
      #   # good
      #   requires :other_id, type: Integer, same_as: :id, desc: "Must match the 'id' parameter"

      class SameAsDescription < RuboCop::Cop::Base
        extend AutoCorrector

        MSG = 'Parameter uses `same_as:` validation but `desc:` is missing the required phrase. ' \
          "Add \"Must match the '<param-name>' parameter\" to the desc."
        RESTRICT_ON_SEND = %i[requires optional].freeze

        # @!method grape_api_param_block?(node)
        def_node_matcher :grape_api_param_block?, <<~PATTERN
          (send _ {:requires :optional}
            (sym $_)
            $_)
        PATTERN

        # @!method same_as_pair(node)
        def_node_matcher :same_as_pair, <<~PATTERN
          (hash <$(pair (sym :same_as) (sym _))...>)
        PATTERN

        # @!method same_as_value(node)
        def_node_matcher :same_as_value, <<~PATTERN
          (hash <(pair (sym :same_as) (sym $_)) ...>)
        PATTERN

        # Captures the desc value node (literal or non-literal)
        # @!method desc_any_value(node)
        def_node_matcher :desc_any_value, <<~PATTERN
          (hash <(pair (sym :desc) $_) ...>)
        PATTERN

        def on_send(node)
          _, match = grape_api_param_block?(node)
          return unless match.is_a?(RuboCop::AST::Node) && match.hash_type?

          same_as = same_as_value(match)
          return unless same_as

          desc_node = desc_any_value(match)

          if desc_node&.str_type?
            return if desc_node.value.include?("Must match the '#{same_as}' parameter")

            add_offense(node) do |corrector|
              corrector.replace(desc_node, "\"#{desc_node.value}. Must match the '#{same_as}' parameter\"")
            end
          elsif desc_node
            # non-literal: check inner string content, no auto-correct
            str_content = desc_node.each_descendant(:str).map(&:value).join
            return if str_content.include?("Must match the '#{same_as}' parameter")

            add_offense(node)
          else
            add_offense(node) do |corrector|
              corrector.insert_after(same_as_pair(match), ", desc: \"Must match the '#{same_as}' parameter\"")
            end
          end
        end
        alias_method :on_csend, :on_send
      end
    end
  end
end
