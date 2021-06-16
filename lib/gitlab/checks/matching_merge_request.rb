# frozen_string_literal: true

module Gitlab
  module Checks
    class MatchingMergeRequest
      TOTAL_METRIC = :gitlab_merge_request_match_total
      STALE_METRIC = :gitlab_merge_request_match_stale_secondary

      def initialize(newrev, branch_name, project)
        @newrev = newrev
        @branch_name = branch_name
        @project = project
      end

      def match?
        if ::Gitlab::Database::LoadBalancing.enable?
          # When a user merges a merge request, the following sequence happens:
          #
          # 1. Sidekiq: MergeService runs and updates the merge request in a locked state.
          # 2. Gitaly: The UserMergeBranch RPC runs.
          # 3. Gitaly (gitaly-ruby): This RPC calls the pre-receive hook.
          # 4. Rails: This hook makes an API request to /api/v4/internal/allowed.
          # 5. Rails: This API check does a SQL query for locked merge
          #    requests with a matching SHA.
          #
          # Since steps 1 and 5 will happen on different database
          # sessions, replication lag could erroneously cause step 5 to
          # report no matching merge requests. To avoid this, we check
          # the write location to ensure the replica can make this query.
          track_session_metrics do
            ::Gitlab::Database::LoadBalancing::Sticking.select_valid_host(:project, @project.id)
          end
        end

        # rubocop: disable CodeReuse/ActiveRecord
        @project.merge_requests
          .with_state(:locked)
          .where(in_progress_merge_commit_sha: @newrev, target_branch: @branch_name)
          .exists?
        # rubocop: enable CodeReuse/ActiveRecord
      end

      private

      def track_session_metrics
        before = ::Gitlab::Database::LoadBalancing::Session.current.use_primary?

        yield

        after = ::Gitlab::Database::LoadBalancing::Session.current.use_primary?

        increment_attempt_count

        if !before && after
          increment_stale_secondary_count
        end
      end

      def increment_attempt_count
        total_counter.increment
      end

      def increment_stale_secondary_count
        stale_counter.increment
      end

      def total_counter
        @total_counter ||= ::Gitlab::Metrics.counter(TOTAL_METRIC, 'Total number of merge request match attempts')
      end

      def stale_counter
        @stale_counter ||= ::Gitlab::Metrics.counter(STALE_METRIC, 'Total number of merge request match attempts with lagging secondary')
      end
    end
  end
end
