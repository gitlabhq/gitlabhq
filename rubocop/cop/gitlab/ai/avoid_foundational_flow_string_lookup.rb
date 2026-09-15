# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      module Ai
        # Flags `Ai::Catalog::FoundationalFlow` lookups via `find_by_reference`,
        # `find_by(foundational_flow_reference: ...)`, or `[]`.
        #
        # A hardcoded reference string is error-prone: a typo returns `nil` silently
        # instead of failing fast. Use the generated named accessor instead
        # (e.g. `code_review_v1`), which raises `NoMethodError` on a typo.
        #
        # @example
        #   # bad
        #   FoundationalFlow.find_by_reference('code_review/v1')
        #   FoundationalFlow.find_by(foundational_flow_reference: 'code_review/v1')
        #   FoundationalFlow['code_review/v1']
        #   FoundationalFlow[workflow_definition]
        #
        #   # good
        #   FoundationalFlow.code_review_v1
        class AvoidFoundationalFlowStringLookup < RuboCop::Cop::Base
          MSG = 'Avoid looking up `FoundationalFlow` via `find_by_reference`, ' \
            '`find_by(foundational_flow_reference: ...)`, or `[]` -- a hardcoded reference typo silently ' \
            'returns nil. Use the generated named accessor instead (e.g. `FoundationalFlow.code_review_v1`).'

          # @!method foundational_flow_const?(node)
          def_node_matcher :foundational_flow_const?, <<~PATTERN
            (const _ :FoundationalFlow)
          PATTERN

          # @!method find_by_reference_call?(node)
          def_node_matcher :find_by_reference_call?, <<~PATTERN
            (send #foundational_flow_const? :find_by_reference _)
          PATTERN

          # @!method find_by_hash_call?(node)
          def_node_matcher :find_by_hash_call?, <<~PATTERN
            (send #foundational_flow_const? :find_by (hash <(pair (sym :foundational_flow_reference) _) ...>))
          PATTERN

          # @!method bracket_call?(node)
          def_node_matcher :bracket_call?, <<~PATTERN
            (send #foundational_flow_const? :[] _)
          PATTERN

          def on_send(node)
            offense = find_by_reference_call?(node) || find_by_hash_call?(node) || bracket_call?(node)

            add_offense(node) if offense
          end
          alias_method :on_csend, :on_send
        end
      end
    end
  end
end
