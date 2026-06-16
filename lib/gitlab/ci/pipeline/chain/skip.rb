# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class Skip < Chain::Base
          include ::Gitlab::Utils::StrongMemoize

          SKIP_PATTERN = /\[(ci[ _-]skip|skip[ _-]ci)\]/i

          def perform!
            return unless skipped? && config_exists?

            if @command.save_incompleted && !@pipeline.readonly?
              # Project iid must be called outside a transaction, so we ensure it is set here
              # otherwise it may be set within the state transition transaction of the skip call
              # which it will lock the InternalId row for the whole transaction
              @pipeline.ensure_project_iid!

              @pipeline.skip
            end
          end

          def break?
            skipped?
          end

          private

          def skipped?
            !@command.ignore_skip_ci && (commit_message_skips_ci? || !!@command.push_options&.skips_ci?)
          end

          def commit_message_skips_ci?
            return false unless @pipeline.git_commit_message

            strong_memoize(:commit_message_skips_ci) do
              !!(@pipeline.git_commit_message =~ SKIP_PATTERN)
            end
          end

          def config_exists?
            pipeline_config = ::Gitlab::Ci::ProjectConfig.new(
              project: project,
              sha: @pipeline.sha,
              custom_content: @command.content,
              pipeline_source: @command.source,
              pipeline_source_bridge: @command.bridge,
              triggered_for_branch: @pipeline.branch?,
              ref: @pipeline.ref,
              source_branch: @command.merge_request&.source_branch || @pipeline.ref,
              pipeline_policy_context: @command.pipeline_policy_context,
              inputs: @command.inputs
            )

            pipeline_config.exists?
          end
        end
      end
    end
  end
end

Gitlab::Ci::Pipeline::Chain::Skip.prepend_mod
