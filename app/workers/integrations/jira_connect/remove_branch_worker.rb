# frozen_string_literal: true

module Integrations
  module JiraConnect
    class RemoveBranchWorker # rubocop:disable Scalability/IdempotentWorker -- disabled in other JiraConnect workers
      include ApplicationWorker

      sidekiq_options retry: 3
      queue_namespace :jira_connect
      feature_category :integrations
      data_consistency :delayed
      loggable_arguments 1, 2
      urgency :low

      worker_has_external_dependencies!

      def perform(project_id, params = {})
        project = Project.find_by_id(project_id)

        return unless project

        params.symbolize_keys!
        branch_name = params[:branch_name]

        ::JiraConnect::SyncService.new(project).execute(
          remove_branch_info: branch_name
        )
      end
    end
  end
end
