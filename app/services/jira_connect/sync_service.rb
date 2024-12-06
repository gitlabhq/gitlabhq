# frozen_string_literal: true

module JiraConnect
  class SyncService
    def initialize(project)
      self.project = project
    end

    # Parameters: see Atlassian::JiraConnect::Client#send_info
    # Includes: update_sequence_id, commits, branches, merge_requests, pipelines
    def execute(**args)
      preload_reviewers_for_merge_requests(args[:merge_requests]) if args.key?(:merge_requests)

      JiraConnectInstallation.for_project(project).flat_map do |installation|
        client = Atlassian::JiraConnect::Client.new(installation.base_url, installation.shared_secret)

        responses = client.send_info(project: project, **args)

        responses.each { |r| log_response(r) }
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

      has_errors = response && (response['errorMessage'].present? || response['errorMessages'].present?)

      if has_errors
        logger.error(message)
      else
        logger.info(message)
      end
    end

    def logger
      Gitlab::IntegrationsLogger
    end

    def preload_reviewers_for_merge_requests(merge_requests)
      ActiveRecord::Associations::Preloader.new(
        records: merge_requests, associations: [:approvals, { merge_request_reviewers: :reviewer }]
      ).call
    end
  end
end

JiraConnect::SyncService.prepend_mod
