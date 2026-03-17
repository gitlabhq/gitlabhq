# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      module Authz
        # Detects `allow_action`, `be_allowed`, and `be_disallowed` assertions in policy specs
        # and suggests using `expect_allowed` / `expect_disallowed` from `PolicyHelpers`.
        #
        # Using the helpers wraps assertions in `aggregate_failures` and uses the
        # `allow_action` matcher, which prints a detailed debug trace on failure.
        # Multiple permissions can also be checked in a single call.
        #
        # @example
        #   # bad
        #   is_expected.to allow_action(:read_group)
        #   is_expected.not_to allow_action(:read_group)
        #   is_expected.to be_allowed(:read_group)
        #   is_expected.not_to be_allowed(:read_group)
        #   expect(policy).to be_disallowed(:read_group)
        #
        #   # good
        #   expect_allowed(:read_group)
        #   expect_disallowed(:read_group)
        #
        class UsePolicyHelpers < ::RuboCop::Cop::Base
          extend AutoCorrector

          MSG = 'Use `expect_allowed` or `expect_disallowed` from `PolicyHelpers` ' \
            'instead of using `allow_action`, `be_allowed`, or `be_disallowed` directly.'

          # Matches: is_expected.to allow_action(...)
          #          is_expected.not_to allow_action(...)
          #          is_expected.to be_allowed(...)
          #          is_expected.not_to be_allowed(...)
          #          is_expected.to be_disallowed(...)
          #          expect(policy).to be_disallowed(...)
          # @!method policy_permission_assertion?(node)
          def_node_matcher :policy_permission_assertion?, <<~PATTERN
            (send
              _
              {:to :not_to}
              (send nil? {:allow_action :be_allowed :be_disallowed} ...))
          PATTERN

          def on_send(node)
            return unless policy_permission_assertion?(node)

            add_offense(node.children[2].loc.selector) do |corrector|
              next unless expected_receiver?(node)

              matcher = node.children[2]
              permissions = matcher.children[2..].map(&:source).join(', ')
              disallowed = node.children[1] == :not_to || matcher.children[1] == :be_disallowed
              helper = disallowed ? 'expect_disallowed' : 'expect_allowed'
              corrector.replace(node, "#{helper}(#{permissions})")
            end
          end
          alias_method :on_csend, :on_send

          private

          def expected_receiver?(node)
            receiver = node.children[0]
            receiver.send_type? && receiver.children[1] == :is_expected
          end
        end
      end
    end
  end
end
