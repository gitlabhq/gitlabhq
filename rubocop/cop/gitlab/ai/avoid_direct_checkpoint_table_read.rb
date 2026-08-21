# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      module Ai
        # Flags direct reads of the full-row `Ai::DuoWorkflows::Checkpoint` table
        # (`p_duo_workflows_checkpoints`) from outside the Workflow/Checkpoint models.
        #
        # `duo_workflow_write_incremental_only` stops writing that table, so these
        # reads silently return nil/empty once the flag is enabled for a workflow.
        # Use `Workflow#checkpoint_headers`, `#latest_checkpoint_header`, or
        # `#reconstructed_channel_values` instead, which fall back to the
        # incremental blob path.
        #
        # See https://gitlab.com/gitlab-org/gitlab/-/work_items/612557
        #
        # @example
        #   # bad
        #   workflow.checkpoints.latest
        #   workflow.checkpoints.earliest(checkpoint_ns: ns)
        #   workflow.checkpoints.order_by_created_at_desc
        #   workflow.basic_checkpoints.empty?
        #
        #   # good
        #   workflow.latest_checkpoint_header
        #   workflow.reconstructed_channel_values(header)
        class AvoidDirectCheckpointTableRead < RuboCop::Cop::Base
          MSG = 'Avoid reading the full-row `Ai::DuoWorkflows::Checkpoint` table directly outside the ' \
            'Workflow/Checkpoint models -- `duo_workflow_write_incremental_only` stops writing this table, ' \
            'so this will silently return nil/empty. Use `Workflow#checkpoint_headers`, ' \
            '`#latest_checkpoint_header`, or `#reconstructed_channel_values` instead. ' \
            'See https://gitlab.com/gitlab-org/gitlab/-/work_items/612557.'

          RESTRICTED_CHECKPOINTS_METHODS = %i[
            latest earliest order_by_created_at_desc ordered_with_writes with_checkpoint_writes
          ].freeze

          # @!method checkpoints_chain_call(node)
          def_node_matcher :checkpoints_chain_call, <<~PATTERN
            (call (call _ :checkpoints) $_method ...)
          PATTERN

          # @!method basic_checkpoints_call?(node)
          def_node_matcher :basic_checkpoints_call?, <<~PATTERN
            (call _ :basic_checkpoints)
          PATTERN

          def on_send(node)
            method_name = checkpoints_chain_call(node)

            offense = (method_name && RESTRICTED_CHECKPOINTS_METHODS.include?(method_name)) ||
              basic_checkpoints_call?(node)

            add_offense(node) if offense
          end
          alias_method :on_csend, :on_send
        end
      end
    end
  end
end
