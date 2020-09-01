# frozen_string_literal: true

module JiraConnect
  class SyncBranchWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    queue_namespace :jira_connect
    feature_category :integrations
    loggable_arguments 1, 2

    def perform(project_id, branch_name, commit_shas)
      project = Project.find_by_id(project_id)

      return unless project

      branches = [project.repository.find_branch(branch_name)] if branch_name.present?
      commits = project.commits_by(oids: commit_shas) if commit_shas.present?

      JiraConnect::SyncService.new(project).execute(commits: commits, branches: branches)
    end
  end
end
