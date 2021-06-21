# frozen_string_literal: true

FactoryBot.define do
  factory :integration, aliases: [:service] do
    project
    type { 'Integration' }
  end

  factory :custom_issue_tracker_integration, class: 'Integrations::CustomIssueTracker' do
    project
    active { true }
    issue_tracker
  end

  factory :emails_on_push_integration, class: 'Integrations::EmailsOnPush' do
    project
    type { 'EmailsOnPushService' }
    active { true }
    push_events { true }
    tag_push_events { true }
    properties do
      {
        recipients: 'test@example.com',
        disable_diffs: true,
        send_from_committer_email: true
      }
    end
  end

  factory :prometheus_integration, class: 'Integrations::Prometheus' do
    project
    active { true }
    properties do
      {
        api_url: 'https://prometheus.example.com/',
        manual_configuration: true
      }
    end
  end

  factory :drone_ci_integration, class: 'Integrations::DroneCi' do
    project
    active { true }
    drone_url { 'https://bamboo.example.com' }
    token { 'test' }
  end

  factory :jira_integration, class: 'Integrations::Jira' do
    project
    active { true }
    type { 'JiraService' }

    transient do
      create_data { true }
      url { 'https://jira.example.com' }
      api_url { nil }
      username { 'jira_username' }
      password { 'jira_password' }
      jira_issue_transition_automatic { false }
      jira_issue_transition_id { '56-1' }
      issues_enabled { false }
      project_key { nil }
      vulnerabilities_enabled { false }
      vulnerabilities_issuetype { nil }
      deployment_type { 'cloud' }
    end

    after(:build) do |integration, evaluator|
      if evaluator.create_data
        integration.jira_tracker_data = build(:jira_tracker_data,
          integration: integration, url: evaluator.url, api_url: evaluator.api_url,
          jira_issue_transition_automatic: evaluator.jira_issue_transition_automatic,
          jira_issue_transition_id: evaluator.jira_issue_transition_id,
          username: evaluator.username, password: evaluator.password, issues_enabled: evaluator.issues_enabled,
          project_key: evaluator.project_key, vulnerabilities_enabled: evaluator.vulnerabilities_enabled,
          vulnerabilities_issuetype: evaluator.vulnerabilities_issuetype, deployment_type: evaluator.deployment_type
        )
      end
    end
  end

  factory :confluence_integration, class: 'Integrations::Confluence' do
    project
    active { true }
    confluence_url { 'https://example.atlassian.net/wiki' }
  end

  factory :bugzilla_integration, class: 'Integrations::Bugzilla' do
    project
    active { true }
    issue_tracker
  end

  factory :redmine_integration, class: 'Integrations::Redmine' do
    project
    active { true }
    issue_tracker
  end

  factory :youtrack_integration, class: 'Integrations::Youtrack' do
    project
    active { true }
    issue_tracker
  end

  factory :ewm_integration, class: 'Integrations::Ewm' do
    project
    active { true }
    issue_tracker
  end

  trait :issue_tracker do
    transient do
      create_data { true }
      project_url { 'http://issuetracker.example.com' }
      issues_url { 'http://issues.example.com/issues/:id' }
      new_issue_url { 'http://new-issue.example.com' }
    end

    after(:build) do |integration, evaluator|
      if evaluator.create_data
        integration.issue_tracker_data = build(:issue_tracker_data,
          integration: integration, project_url: evaluator.project_url,
          issues_url: evaluator.issues_url, new_issue_url: evaluator.new_issue_url
        )
      end
    end
  end

  factory :external_wiki_integration, class: 'Integrations::ExternalWiki' do
    project
    type { 'ExternalWikiService' }
    active { true }
    external_wiki_url { 'http://external-wiki-url.com' }
  end

  factory :open_project_service, class: 'Integrations::OpenProject' do
    project
    active { true }

    transient do
      url { 'http://openproject.example.com' }
      api_url { 'http://openproject.example.com/issues/:id' }
      token { 'supersecret' }
      closed_status_id { '15' }
      project_identifier_code { 'PRJ-1' }
    end

    after(:build) do |integration, evaluator|
      integration.open_project_tracker_data = build(:open_project_tracker_data,
        integration: integration, url: evaluator.url, api_url: evaluator.api_url, token: evaluator.token,
        closed_status_id: evaluator.closed_status_id, project_identifier_code: evaluator.project_identifier_code
      )
    end
  end

  trait :jira_cloud_service do
    url { 'https://mysite.atlassian.net' }
    username { 'jira_user' }
    password { 'my-secret-password' }
  end

  # avoids conflict with slack_integration factory
  factory :integrations_slack, class: 'Integrations::Slack' do
    project
    active { true }
    webhook { 'https://slack.service.url' }
    type { 'SlackService' }
  end

  factory :slack_slash_commands_integration, class: 'Integrations::SlackSlashCommands' do
    project
    active { true }
    type { 'SlackSlashCommandsService' }
  end

  factory :pipelines_email_integration, class: 'Integrations::PipelinesEmail' do
    project
    active { true }
    type { 'PipelinesEmailService' }
    recipients { 'test@example.com' }
  end

  # this is for testing storing values inside properties, which is deprecated and will be removed in
  # https://gitlab.com/gitlab-org/gitlab/issues/29404
  trait :without_properties_callback do
    jira_tracker_data { nil }
    issue_tracker_data { nil }
    create_data { false }

    after(:build) do
      Integrations::BaseIssueTracker.skip_callback(:validation, :before, :handle_properties)
    end

    to_create { |instance| instance.save!(validate: false) }

    after(:create) do
      Integrations::BaseIssueTracker.set_callback(:validation, :before, :handle_properties)
    end
  end

  trait :template do
    project { nil }
    template { true }
  end

  trait :instance do
    project { nil }
    instance { true }
  end
end
