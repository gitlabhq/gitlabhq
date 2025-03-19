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

      attribute :job_token_policies, ::Gitlab::Database::Type::SymbolizedJsonb.new
      validates :job_token_policies, json_schema: {
        filename: 'ci_job_token_authorizations_policies', detail_errors: true
      }

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
        add_to_request_store_hash(accessed_project_id: accessed_project.id, origin_project_id: origin_project.id)
      end

      def self.capture_job_token_policies(policies)
        add_to_request_store_hash(policies: policies)
      end

      # Schedule logging of captured authorizations in a background worker.
      # We add a 5 minutes delay with deduplication logic so that we log the same authorization
      # at most every 5 minutes. Otherwise, in high traffic projects we could be logging
      # authorizations very frequently.
      def self.log_captures_async
        authorizations = captured_authorizations
        return unless authorizations

        accessed_project_id = authorizations[:accessed_project_id]
        origin_project_id = authorizations[:origin_project_id]
        return unless accessed_project_id && origin_project_id

        policies = authorizations.fetch(:policies, []).map(&:to_s)
        Ci::JobToken::LogAuthorizationWorker # rubocop:disable CodeReuse/Worker -- This method is called from a middleware and it's better tested
          .perform_in(CAPTURE_DELAY, accessed_project_id, origin_project_id, policies)
      end

      def self.log_captures!(accessed_project_id:, origin_project_id:, policies: [])
        current_time = Time.current
        attributes = {
          accessed_project_id: accessed_project_id,
          origin_project_id: origin_project_id,
          last_authorized_at: current_time
        }

        transaction do
          if policies.present?
            auth_log = lock.find_by(
              accessed_project_id: accessed_project_id,
              origin_project_id: origin_project_id
            )
            policies = policies.index_with(current_time)
            attributes[:job_token_policies] = auth_log ? auth_log.job_token_policies.merge(policies) : policies
          end

          upsert(attributes, unique_by: [:accessed_project_id, :origin_project_id], on_duplicate: :update)
        end
      end

      def self.add_to_request_store_hash(hash)
        new_hash = captured_authorizations.present? ? captured_authorizations.merge(hash) : hash
        Gitlab::SafeRequestStore[REQUEST_CACHE_KEY] = new_hash
      end

      def self.captured_authorizations
        Gitlab::SafeRequestStore[REQUEST_CACHE_KEY]
      end
    end
  end
end
