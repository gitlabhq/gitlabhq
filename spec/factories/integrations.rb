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
    datadog_ci_visibility { false }
    datadog_site { 'datadoghq.com' }
    datadog_tags { 'key:value' }
    api_key { 'secret' }
  end

  factory :diffblue_cover_integration, class: 'Integrations::DiffblueCover' do
    project
    active { true }
    diffblue_license_key { '1234-ABCD-DCBA-4321' }
    diffblue_access_token_name { 'Diffblue CI' }
    diffblue_access_token_secret { 'glpat-00112233445566778899' } # gitleaks:allow
  end

  factory :emails_on_push_integration, class: 'Integrations::EmailsOnPush' do
    project
    type { 'Integrations::EmailsOnPush' }
    active { true }
    push_events { true }
    tag_push_events { true }
    recipients { 'foo@bar.com' }
    disable_diffs { true }
    send_from_committer_email { true }
    branches_to_be_notified { 'all' }
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
    username { 'username' }
    token { 'secrettoken' }
    server { 'https://packagist.example.comp' }
  end

  factory :phorge_integration, class: 'Integrations::Phorge' do
    project
    active { true }
    project_url { 'http://phorge.example.com' }
    issues_url { 'http://phorge.example.com/issues/:id' }
  end

  factory :prometheus_integration, class: 'Integrations::Prometheus' do
    project
    active { true }
    api_url { 'https://prometheus.example.com/' }
    manual_configuration { true }
    google_iap_audience_client_id { 'IAP_CLIENT_ID.apps.googleusercontent.com' }
    google_iap_service_account_json { '{ type: "service_account", project_id: "123" }' }
  end

  factory :bamboo_integration, class: 'Integrations::Bamboo' do
    project
    active { true }
    bamboo_url { 'https://bamboo.example.com' }
    build_key { 'foo' }
    username { 'mic' }
    password { 'password' }
  end

  factory :drone_ci_integration, class: 'Integrations::DroneCi' do
    project
    active { true }
    drone_url { 'https://drone.example.com' }
    enable_ssl_verification { false }
    token { 'test' }
  end

  factory :jira_integration, class: 'Integrations::Jira' do
    project
    active { true }
    type { 'Integrations::Jira' }
    url { 'https://jira.example.com' }
    api_url { '' }
    username { 'jira_username' }
    password { 'jira_password' }
    jira_auth_type { 0 }

    transient do
      create_data { true }
      jira_issue_transition_automatic { false }
      jira_issue_transition_id { '56-1' }
      issues_enabled { false }
      jira_issue_prefix { '' }
      jira_issue_regex { '' }
      project_key { nil }
      project_keys { [] }
      vulnerabilities_enabled { false }
      vulnerabilities_issuetype { nil }
      deployment_type { 'cloud' }
    end

    trait :jira_cloud do
      url { 'https://mysite.atlassian.net' }
      username { 'jira_user' }
      password { 'my-secret-password' }
      jira_auth_type { 0 }
    end

    after(:build) do |integration, evaluator|
      integration.instance_variable_set(:@old_data_fields, nil)

      if evaluator.create_data
        integration.jira_tracker_data = build(:jira_tracker_data,
          integration: integration, url: evaluator.url, api_url: evaluator.api_url,
          jira_auth_type: evaluator.jira_auth_type,
          jira_issue_transition_automatic: evaluator.jira_issue_transition_automatic,
          jira_issue_transition_id: evaluator.jira_issue_transition_id,
          jira_issue_prefix: evaluator.jira_issue_prefix,
          jira_issue_regex: evaluator.jira_issue_regex,
          username: evaluator.username, password: evaluator.password, issues_enabled: evaluator.issues_enabled,
          project_key: evaluator.project_key, project_keys: evaluator.project_keys,
          vulnerabilities_enabled: evaluator.vulnerabilities_enabled,
          vulnerabilities_issuetype: evaluator.vulnerabilities_issuetype,
          deployment_type: evaluator.deployment_type
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
    project_url { 'http://issuetracker.example.com' }
    issues_url { 'http://issues.example.com/issues/:id' }
  end

  factory :ewm_integration, class: 'Integrations::Ewm' do
    project
    active { true }
    issue_tracker
  end

  factory :clickup_integration, class: 'Integrations::Clickup' do
    project
    active { true }
    project_url { 'http://issuetracker.example.com' }
    issues_url { 'http://issues.example.com/issues/:id' }
  end

  trait :issue_tracker do
    project_url { 'http://issuetracker.example.com' }
    issues_url { 'http://issues.example.com/issues/:id' }
    new_issue_url { 'http://new-issue.example.com' }

    transient do
      create_data { true }
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

  trait :chat_notification do
    sequence(:webhook) { |n| "https://example.com/webhook/#{n}" }
    push_events { false }
    issues_events { false }
    confidential_issues_events { false }
    merge_requests_events { false }
    note_events { false }
    confidential_note_events { false }
    tag_push_events { false }
    pipeline_events { false }
    wiki_page_events { false }
  end

  trait :inactive do
    active { false }
  end

  factory :discord_integration, class: 'Integrations::Discord' do
    chat_notification
    project
    active { true }
    type { 'Integrations::Discord' }
  end

  factory :mattermost_integration, class: 'Integrations::Mattermost' do
    chat_notification
    project
    type { 'Integrations::Mattermost' }
    labels_to_be_notified_behavior { 'match_any' }
    active { true }
  end

  factory :microsoft_teams_integration, class: 'Integrations::MicrosoftTeams' do
    chat_notification
    project
    type { 'Integrations::MicrosoftTeams' }
    active { true }
  end

  factory :asana_integration, class: 'Integrations::Asana' do
    project
    api_key { 'secrettoken' }
    active { true }
  end

  factory :beyond_identity_integration, class: 'Integrations::BeyondIdentity' do
    type { 'Integrations::BeyondIdentity' }
    active { true }
    instance { true }
    token { 'api-token' }
  end

  factory :assembla_integration, class: 'Integrations::Assembla' do
    project
    token { 'secrettoken' }
    active { true }
  end

  factory :buildkite_integration, class: 'Integrations::Buildkite' do
    project
    token { 'secrettoken' }
    project_url { 'http://example.com' }
    active { true }
  end

  factory :campfire_integration, class: 'Integrations::Campfire' do
    project
    active { true }
    room { '1234' }
    token { 'test' }
  end

  factory :hangouts_chat_integration, class: 'Integrations::HangoutsChat' do
    chat_notification
    project
    type { 'Integrations::HangoutsChat' }
    active { true }
  end

  factory :irker_integration, class: 'Integrations::Irker' do
    project
    recipients { 'irc://irc.network.net:666/#channel' }
    server_port { 1234 }
    type { 'Integrations::Irker' }
    active { true }
  end

  factory :mattermost_slash_commands_integration, class: 'Integrations::MattermostSlashCommands' do
    project
    token { 'secrettoken' }
    active { true }
  end

  factory :mock_ci_integration, class: 'Integrations::MockCi' do
    project
    mock_service_url { 'http://example.com' }
    type { 'Integrations::MockCi' }
    active { true }
  end

  factory :mock_monitoring_integration, class: 'Integrations::MockMonitoring' do
    project
    type { 'Integrations::MockMonitoring' }
    active { true }
  end

  factory :pumble_integration, class: 'Integrations::Pumble' do
    project
    chat_notification
    type { 'Integrations::Pumble' }
    active { true }
  end

  factory :pushover_integration, class: 'Integrations::Pushover' do
    project
    type { 'Integrations::Pushover' }
    api_key { 'secrettoken' }
    user_key { 'secretkey' }
    priority { "0" }
    active { true }
    device { nil }
    sound { nil }
  end

  factory :teamcity_integration, class: 'Integrations::Teamcity' do
    project
    teamcity_url { 'http://example.com' }
    username { 'username' }
    password { 'secrettoken' }
    build_type { '123' }
    type { 'Integrations::Teamcity' }
    active { true }
  end

  factory :unify_circuit_integration, class: 'Integrations::UnifyCircuit' do
    project
    chat_notification
    type { 'Integrations::UnifyCircuit' }
    active { true }
  end

  factory :webex_teams_integration, class: 'Integrations::WebexTeams' do
    project
    chat_notification
    type { 'Integrations::WebexTeams' }
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
    token { 'secrettoken' }
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
    app_store_protected_refs { true }
  end

  factory :google_play_integration, class: 'Integrations::GooglePlay' do
    project
    active { true }
    type { 'Integrations::GooglePlay' }

    package_name { 'com.gitlab.foo.bar' }
    service_account_key_file_name { 'service_account.json' }
    service_account_key { File.read('spec/fixtures/service_account.json') }
    google_play_protected_refs { true }
  end

  factory :matrix_integration, class: 'Integrations::Matrix' do
    project
    type { 'Integrations::Matrix' }
    active { true }

    token { 'syt-zyx57W2v1u123ew11' }
    room { '!qPKKM111FFKKsfoCVy:matrix.org' }
  end

  factory :squash_tm_integration, class: 'Integrations::SquashTm' do
    project
    active { true }
    type { 'Integrations::SquashTm' }

    url { 'https://url-to-squash.com' }
    token { 'squash_tm_token' }
  end

  factory :telegram_integration, class: 'Integrations::Telegram' do
    project
    type { 'Integrations::Telegram' }
    active { true }

    token { '123456:ABC-DEF1234' }
    room { '@channel' }
    thread { nil }
  end

  factory :jira_cloud_app_integration, class: 'Integrations::JiraCloudApp' do
    project
    active { true }
    type { 'Integrations::JiraCloudApp' }
    jira_cloud_app_service_ids { 'b:YXJpOmNsb3VkOmdyYXBoOjpzZXJ2aWNlLzI=' }
  end

  # this is for testing storing values inside properties, which is deprecated and will be removed in
  # https://gitlab.com/gitlab-org/gitlab/issues/29404
  trait :without_properties_callback do
    jira_tracker_data { nil }
    issue_tracker_data { nil }
    create_data { false }

    after(:build) do |integration|
      integration.class.skip_callback(:validation, :before, :handle_properties)
    end

    to_create { |instance| instance.save!(validate: false) }

    after(:create) do |integration|
      integration.class.set_callback(:validation, :before, :handle_properties)
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
