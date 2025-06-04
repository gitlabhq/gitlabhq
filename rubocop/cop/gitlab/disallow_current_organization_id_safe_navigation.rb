# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # Discourages the use of `Current.organization&.id`.
      #
      # `Current.organization` is expected to be assigned in contexts where its ID is accessed.
      # If `Current.organization` is not assigned, attempting to access `id` directly
      # (i.e., `Current.organization.id`) will correctly raise a
      # `Current::OrganizationNotAssignedError`. Using the safe navigation operator (`&.id`)
      # prevents this error from being raised, potentially hiding issues where
      # `Current.organization` was not properly set up.
      #
      # This cop enforces the direct use of `Current.organization.id` to ensure
      # that `Current::OrganizationNotAssignedError` is raised if `Current.organization` is nil.
      #
      # @example
      #
      #   # bad
      #   id = Current.organization&.id
      #   id = ::Current.organization&.id
      #
      #   # good
      #   # If Current.organization is expected to be present (which it is),
      #   # this will raise Current::OrganizationNotAssignedError if it's unexpectedly nil,
      #   # making the underlying issue visible.
      #   id = Current.organization.id
      #
      class DisallowCurrentOrganizationIdSafeNavigation < RuboCop::Cop::Base
        extend AutoCorrector

        MSG = 'Use `Current.organization.id` instead of `Current.organization&.id`. ' \
          '`Current.organization` is expected to be assigned.'

        # @!method current_organization_safe_id?(node)
        def_node_matcher :current_organization_safe_id?, <<~PATTERN
          (csend
            (send
              (const {nil? | cbase} :Current) :organization) :id)
        PATTERN

        def on_csend(node)
          return unless current_organization_safe_id?(node)

          add_offense(node) do |corrector|
            operator_range = node.loc.operator

            if operator_range.nil? && node.receiver && node.loc.selector
              # Fallback: If node.loc.operator is nil, try to determine the range
              # by looking at the space between the receiver and the method selector.
              receiver_end_pos = node.receiver.source_range.end_pos
              selector_begin_pos = node.loc.selector.begin_pos

              if receiver_end_pos < selector_begin_pos
                # This range covers the characters between the end of the receiver
                # and the start of the selector, which should be the operator.
                operator_range = Parser::Source::Range.new(node.source_range.source_buffer,
                  receiver_end_pos,
                  selector_begin_pos)
              end
            end

            corrector.replace(operator_range, '.') if operator_range
          end
        end
      end
    end
  end
end
