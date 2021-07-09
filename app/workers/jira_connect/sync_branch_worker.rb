# frozen_string_literal: true

module JiraConnect
  class SyncBranchWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    sidekiq_options retry: 3

    queue_namespace :jira_connect
    feature_category :integrations
    data_consistency :delayed, feature_flag: :load_balancing_for_jira_connect_workers
    loggable_arguments 1, 2

    worker_has_external_dependencies!

    def perform(project_id, branch_name, commit_shas, update_sequence_id)
      project = Project.find_by_id(project_id)

      return unless project

      branches = [project.repository.find_branch(branch_name)] if branch_name.present?
      commits = project.commits_by(oids: commit_shas) if commit_shas.present?

      JiraConnect::SyncService.new(project).execute(commits: commits, branches: branches, update_sequence_id: update_sequence_id)
    end
  end
end
