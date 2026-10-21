# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    # No-op: issues are no longer imported. Kept so jobs queued during the deploy
    # drain and notify their waiter. See
    # https://gitlab.com/gitlab-org/gitlab/-/work_items/601064
    class ImportIssueWorker # rubocop:disable Scalability/IdempotentWorker
      include ApplicationWorker

      data_consistency :delayed

      feature_category :importers

      worker_has_external_dependencies!

      def perform(_project_id, _hash, notify_key)
        JobWaiter.notify(notify_key, jid)
      end
    end
  end
end
