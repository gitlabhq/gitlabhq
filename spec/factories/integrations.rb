# frozen_string_literal: true

FactoryBot.define do
  factory :integration do
    project
    type { 'Integration' }
  end

  factory :custom_issue_tracker_integration, class: 'Integrations::CustomIssueTracker' do
    project
    active { true }
    issue_tracker
  end

  factory :jenkins_integration, class: 'Integrations::Jenkins' do
    project
    active { true }
    type { 'Integrations::Jenkins' }
    jenkins_url { 'http://jenkins.example.com/' }
    project_name { 'my-project' }
    username { 'jenkings-user' }
    password { 'passw0rd' }
  end

  factory :datadog_integration, class: 'Integrations::Datadog' do
    project
    active { true }
    api_key { 'secret' }
  end

  factory :emails_on_push_integration, class: 'Integrations::EmailsOnPush' do
    project
    type { 'Integrations::EmailsOnPush' }
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

  factory :gitlab_slack_application_integration, class: 'Integrations::GitlabSlackApplication' do
    project
    active { true }
    type { 'Integrations::GitlabSlackApplication' }
    slack_integration { association :slack_integration, integration: instance }

    transient do
      all_channels { true }
    end

    after(:build) do |integration, evaluator|
      next unless evaluator.all_channels

      integration.event_channel_names.each do |name|
        integration.send("#{name}=".to_sym, "##{name}")
      end
    end

    trait :all_features_supported do
      slack_integration { association :slack_integration, :all_features_supported, integration: instance }
    end
  end

  factory :packagist_integration, class: 'Integrations::Packagist' do
    project
    type { 'Integrations::Packagist' }
    active { true }
    properties do
      {
        username: 'username',
        token: 'test',
        server: 'https://packagist.example.com'
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
    type { 'Integrations::Jira' }

    transient do
      create_data { true }
      url { 'https://jira.example.com' }
      api_url { '' }
      username { 'jira_username' }
      password { 'jira_password' }
      jira_auth_type { 0 }
      jira_issue_transition_automatic { false }
      jira_issue_transition_id { '56-1' }
      issues_enabled { false }
      jira_issue_prefix { '' }
      jira_issue_regex { '' }
      project_key { nil }
      vulnerabilities_enabled { false }
      vulnerabilities_issuetype { nil }
      deployment_type { 'cloud' }
    end

    after(:build) do |integration, evaluator|
      if evaluator.create_data
        integration.jira_tracker_data = build(:jira_tracker_data,
          integration: integration, url: evaluator.url, api_url: evaluator.api_url,
          jira_auth_type: evaluator.jira_auth_type,
          jira_issue_transition_automatic: evaluator.jira_issue_transition_automatic,
          jira_issue_transition_id: evaluator.jira_issue_transition_id,
          username: evaluator.username, password: evaluator.password, issues_enabled: evaluator.issues_enabled,
          project_key: evaluator.project_key, vulnerabilities_enabled: evaluator.vulnerabilities_enabled,
          vulnerabilities_issuetype: evaluator.vulnerabilities_issuetype, deployment_type: evaluator.deployment_type
        )
      end
    end
  end

  factory :zentao_integration, class: 'Integrations::Zentao' do
    project
    active { true }
    type { 'Integrations::Zentao' }

    transient do
      create_data { true }
      url { 'https://jihudemo.zentao.net' }
      api_url { '' }
      api_token { 'ZENTAO_TOKEN' }
      zentao_product_xid { '3' }
    end

    after(:build) do |integration, evaluator|
      if evaluator.create_data
        integration.zentao_tracker_data = build(:zentao_tracker_data,
          integration: integration,
          url: evaluator.url,
          api_url: evaluator.api_url,
          api_token: evaluator.api_token,
          zentao_product_xid: evaluator.zentao_product_xid
        )
      end
    end
  end

  factory :shimo_integration, class: 'Integrations::Shimo' do
    project
    active { true }
    external_wiki_url { 'https://shimo.example.com/desktop' }
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
    type { 'Integrations::ExternalWiki' }
    active { true }
    external_wiki_url { 'http://external-wiki-url.com' }
  end

  trait :jira_cloud_service do
    url { 'https://mysite.atlassian.net' }
    username { 'jira_user' }
    password { 'my-secret-password' }
    jira_auth_type { 0 }
  end

  trait :chat_notification do
    sequence(:webhook) { |n| "https://example.com/webhook/#{n}" }
  end

  trait :inactive do
    active { false }
  end

  factory :mattermost_integration, class: 'Integrations::Mattermost' do
    chat_notification
    project
    type { 'Integrations::Mattermost' }
    active { true }
  end

  # avoids conflict with slack_integration factory
  factory :integrations_slack, class: 'Integrations::Slack' do
    chat_notification
    project
    active { true }
    type { 'Integrations::Slack' }
  end

  factory :slack_slash_commands_integration, class: 'Integrations::SlackSlashCommands' do
    project
    active { true }
    type { 'Integrations::SlackSlashCommands' }
  end

  factory :pipelines_email_integration, class: 'Integrations::PipelinesEmail' do
    project
    active { true }
    type { 'Integrations::PipelinesEmail' }
    recipients { 'test@example.com' }
  end

  factory :pivotaltracker_integration, class: 'Integrations::Pivotaltracker' do
    project
    active { true }
    token { 'test' }
  end

  factory :harbor_integration, class: 'Integrations::Harbor' do
    project
    active { true }
    type { 'Integrations::Harbor' }

    url { 'https://demo.goharbor.io' }
    project_name { 'testproject' }
    username { 'harborusername' }
    password { 'harborpassword' }
  end

  factory :apple_app_store_integration, class: 'Integrations::AppleAppStore' do
    project
    active { true }
    type { 'Integrations::AppleAppStore' }

    app_store_issuer_id { 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' }
    app_store_key_id { 'ABC1' }
    app_store_private_key_file_name { 'auth_key.p8' }
    app_store_private_key { File.read('spec/fixtures/auth_key.p8') }
  end

  factory :google_play_integration, class: 'Integrations::GooglePlay' do
    project
    active { true }
    type { 'Integrations::GooglePlay' }

    package_name { 'com.gitlab.foo.bar' }
    service_account_key_file_name { 'service_account.json' }
    service_account_key { File.read('spec/fixtures/service_account.json') }
  end

  factory :squash_tm_integration, class: 'Integrations::SquashTm' do
    project
    active { true }
    type { 'Integrations::SquashTm' }

    url { 'https://url-to-squash.com' }
    token { 'squash_tm_token' }
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

  trait :group do
    group
    project { nil }
  end

  trait :instance do
    project { nil }
    instance { true }
  end
end
