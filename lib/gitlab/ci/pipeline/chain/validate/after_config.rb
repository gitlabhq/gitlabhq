# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Validate
          class AfterConfig < Chain::Base
            include Chain::Helpers

            ERROR_MESSAGE = 'This pipeline did not run because the code should be reviewed by a non-AI user first. ' \
              'Please verify this change is okay before running a new pipeline.'

            def perform!
              if !@pipeline.project.allow_composite_identities_to_run_pipelines &&
                  current_user.has_composite_identity?

                error(ERROR_MESSAGE, failure_reason: :composite_identity_forbidden)
              end
            end

            def break?
              @pipeline.errors.any?
            end
          end
        end
      end
    end
  end
end

Gitlab::Ci::Pipeline::Chain::Validate::AfterConfig.prepend_mod_with('Gitlab::Ci::Pipeline::Chain::Validate::AfterConfig')
