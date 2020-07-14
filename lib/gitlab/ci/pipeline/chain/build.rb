# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class Build < Chain::Base
          def perform!
            @pipeline.assign_attributes(
              source: @command.source,
              project: @command.project,
              ref: @command.ref,
              sha: @command.sha,
              before_sha: @command.before_sha,
              source_sha: @command.source_sha,
              target_sha: @command.target_sha,
              tag: @command.tag_exists?,
              trigger_requests: Array(@command.trigger_request),
              user: @command.current_user,
              pipeline_schedule: @command.schedule,
              merge_request: @command.merge_request,
              external_pull_request: @command.external_pull_request,
              variables_attributes: Array(@command.variables_attributes),
              # This should be removed and set on the database column default
              # level when the keep_latest_artifacts_for_ref feature flag is
              # removed.
              locked: ::Gitlab::Ci::Features.keep_latest_artifacts_for_ref_enabled?(@command.project) ? :artifacts_locked : :unlocked
            )
          end

          def break?
            false
          end
        end
      end
    end
  end
end
