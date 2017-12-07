module Gitlab
  module Ci
    module Pipeline
      module Chain
        class Build < Chain::Base
          include Chain::Helpers

          def perform!
            @pipeline.assign_attributes(
              source: @command.source,
              project: @project,
              ref: ref,
              sha: sha,
              before_sha: before_sha,
              tag: tag_exists?,
              trigger_requests: Array(@command.trigger_request),
              user: @current_user,
              pipeline_schedule: @command.schedule,
              protected: protected_ref?
            )

            @pipeline.set_config_source
          end

          def break?
            false
          end

          private

          def ref
            @ref ||= Gitlab::Git.ref_name(origin_ref)
          end

          def sha
            @project.commit(origin_sha || origin_ref).try(:id)
          end

          def origin_ref
            @command.origin_ref
          end

          def origin_sha
            @command.checkout_sha || @command.after_sha
          end

          def before_sha
            @command.checkout_sha || @command.before_sha || Gitlab::Git::BLANK_SHA
          end

          def protected_ref?
            @project.protected_for?(ref)
          end
        end
      end
    end
  end
end
