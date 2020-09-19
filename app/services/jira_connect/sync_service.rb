# frozen_string_literal: true

module JiraConnect
  class SyncService
    def initialize(project)
      self.project = project
    end

    def execute(commits: nil, branches: nil, merge_requests: nil)
      JiraConnectInstallation.for_project(project).each do |installation|
        client = Atlassian::JiraConnect::Client.new(installation.base_url, installation.shared_secret)

        response = client.store_dev_info(project: project, commits: commits, branches: branches, merge_requests: merge_requests)

        log_response(response)
      end
    end

    private

    attr_accessor :project

    def log_response(response)
      message = {
        message: 'response from jira dev_info api',
        integration: 'JiraConnect',
        project_id: project.id,
        project_path: project.full_path,
        jira_response: response&.to_json
      }

      if response && response['errorMessages']
        logger.error(message)
      else
        logger.info(message)
      end
    end

    def logger
      Gitlab::ProjectServiceLogger
    end
  end
end
