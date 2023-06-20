# frozen_string_literal: true

module QA
  module Vendor
    module Jira
      class JiraAPI
        include Scenario::Actable
        include Support::API

        DEFAULT_ISSUE_SUMMARY = 'REST ye merry gentlemen.'
        DEFAULT_ISSUE_DESCRIPTION = 'Creating of an issue using project keys and issue type names using the REST API'

        def base_url
          host = QA::Runtime::Env.jira_hostname || 'localhost'

          "http://#{host}:8080"
        end

        def api_url
          "#{base_url}/rest/api/2"
        end

        def fetch_issue(issue_key)
          response = get(
            "#{api_url}/issue/#{issue_key}",
            user: Runtime::Env.jira_admin_username,
            password: Runtime::Env.jira_admin_password
          )

          parse_body(response)
        end

        def create_project(project_key = "GL#{SecureRandom.hex(4)}".upcase)
          payload = {
            key: project_key,
            name: "Project #{project_key}",
            description: "New Project #{project_key}",
            lead: Runtime::Env.jira_admin_username,
            projectTypeKey: 'software'
          }
          response = post(
            "#{api_url}/project",
            payload.to_json,
            headers: { 'Content-Type' => 'application/json' },
            user: Runtime::Env.jira_admin_username,
            password: Runtime::Env.jira_admin_password)

          returned_project_key = parse_body(response)[:key]

          QA::Runtime::Logger.debug("Created JIRA project with key: '#{project_key}'")

          returned_project_key
        end

        def create_issue(
          jira_project_key,
          issue_type: 'Bug',
          summary: DEFAULT_ISSUE_SUMMARY,
          description: DEFAULT_ISSUE_DESCRIPTION
        )
          payload = {
            fields: {
              project: {
                key: jira_project_key
              },
              summary: summary,
              description: description,
              issuetype: {
                name: issue_type
              }
            }
          }

          response = post(
            "#{api_url}/issue",
            payload.to_json,
            headers: { 'Content-Type': 'application/json' },
            user: Runtime::Env.jira_admin_username,
            password: Runtime::Env.jira_admin_password)

          issue_key = parse_body(response)[:key]

          QA::Runtime::Logger.debug("Created JIRA issue with key: '#{issue_key}'")

          issue_key
        end
      end
    end
  end
end
