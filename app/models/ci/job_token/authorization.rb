# frozen_string_literal: true

# In this model we log all authorizations from CI_JOB_TOKEN where the scope is disabled.
# We log the source project (where the token comes from) and the target project being
# accessed.
# The purpose of this model is to assist project owners in enabling the job token scope
# and making informed decisions on what to add to the allowlist.

module Ci
  module JobToken
    class Authorization < Ci::ApplicationRecord
      extend Gitlab::InternalEventsTracking
      include EachBatch

      self.table_name = 'ci_job_token_authorizations'

      belongs_to :origin_project, class_name: 'Project' # where the job token came from
      belongs_to :accessed_project, class_name: 'Project' # what project the job token accessed

      REQUEST_CACHE_KEY = :job_token_authorizations
      CAPTURE_DELAY = 5.minutes

      scope :for_project, ->(accessed_project) { where(accessed_project: accessed_project) }
      scope :preload_origin_project, -> { includes(origin_project: :route) }

      # Record in SafeRequestStore a cross-project access attempt
      def self.capture(origin_project:, accessed_project:)
        label = origin_project == accessed_project ? 'same-project' : 'cross-project'
        track_internal_event(
          'authorize_job_token_with_disabled_scope',
          project: accessed_project,
          additional_properties: {
            label: label
          }
        )

        # Skip self-referential accesses as they are always allowed and don't need
        # to be logged neither added to the allowlist.
        return if label == 'same-project'

        # We are tracking an attempt of cross-project utilization but we
        # are not yet persisting this log until a request successfully
        # completes. We will do that in a middleware. This is because the policy
        # rule about job token scope may be satisfied but a subsequent rule in
        # the Declarative Policies may block the authorization.
        Gitlab::SafeRequestStore.fetch(REQUEST_CACHE_KEY) do
          { accessed_project_id: accessed_project.id, origin_project_id: origin_project.id }
        end
      end

      # Schedule logging of captured authorizations in a background worker.
      # We add a 5 minutes delay with deduplication logic so that we log the same authorization
      # at most every 5 minutes. Otherwise, in high traffic projects we could be logging
      # authorizations very frequently.
      def self.log_captures_async
        authorizations = captured_authorizations
        return unless authorizations

        accessed_project_id = authorizations[:accessed_project_id]
        Ci::JobToken::LogAuthorizationWorker # rubocop:disable CodeReuse/Worker -- This method is called from a middleware and it's better tested
          .perform_in(CAPTURE_DELAY, accessed_project_id, authorizations[:origin_project_id])
      end

      def self.log_captures!(accessed_project_id:, origin_project_id:)
        upsert({
          accessed_project_id: accessed_project_id,
          origin_project_id: origin_project_id,
          last_authorized_at: Time.current
        },
          unique_by: [:accessed_project_id, :origin_project_id],
          on_duplicate: :update)
      end

      def self.captured_authorizations
        Gitlab::SafeRequestStore[REQUEST_CACHE_KEY]
      end
    end
  end
end
