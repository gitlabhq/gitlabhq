# frozen_string_literal: true

module Clusters
  module Agents
    class NotifyGitPushWorker
      include ApplicationWorker
      include ClusterAgentQueue

      deduplicate :until_executed, including_scheduled: true
      idempotent!

      urgency :low
      data_consistency :delayed

      def perform(project_id)
        return unless project = ::Project.find_by_id(project_id)

        Gitlab::Kas::Client.new.send_git_push_event(project: project)
      end
    end
  end
end
