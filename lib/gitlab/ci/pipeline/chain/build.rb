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
              tag: @command.tag_exists?,
              trigger_requests: Array(@command.trigger_request),
              user: @command.current_user,
              pipeline_schedule: @command.schedule,
              protected: @command.protected_ref?
            )

            @pipeline.set_config_source
          end

          def break?
            false
          end
        end
      end
    end
  end
end
