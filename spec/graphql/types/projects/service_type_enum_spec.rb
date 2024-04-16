# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ServiceType'] do
  it 'exposes all the existing project services' do
    expect(described_class.values.keys).to include(*core_service_enums)
  end

  def core_service_enums
    %w[
      ASANA_SERVICE
      ASSEMBLA_SERVICE
      BAMBOO_SERVICE
      BUGZILLA_SERVICE
      BUILDKITE_SERVICE
      CAMPFIRE_SERVICE
      CLICKUP_SERVICE
      CONFLUENCE_SERVICE
      CUSTOM_ISSUE_TRACKER_SERVICE
      DATADOG_SERVICE
      DISCORD_SERVICE
      DRONE_CI_SERVICE
      EMAILS_ON_PUSH_SERVICE
      EWM_SERVICE
      EXTERNAL_WIKI_SERVICE
      HANGOUTS_CHAT_SERVICE
      IRKER_SERVICE
      JENKINS_SERVICE
      JIRA_SERVICE
      MATTERMOST_SERVICE
      MATTERMOST_SLASH_COMMANDS_SERVICE
      MICROSOFT_TEAMS_SERVICE
      PACKAGIST_SERVICE
      PHORGE_SERVICE
      PIPELINES_EMAIL_SERVICE
      PIVOTALTRACKER_SERVICE
      PROMETHEUS_SERVICE
      PUMBLE_SERVICE
      PUSHOVER_SERVICE
      REDMINE_SERVICE
      SLACK_SERVICE
      SLACK_SLASH_COMMANDS_SERVICE
      TEAMCITY_SERVICE
      UNIFY_CIRCUIT_SERVICE
      WEBEX_TEAMS_SERVICE
      YOUTRACK_SERVICE
      ZENTAO_SERVICE
    ]
  end

  it 'coerces values correctly' do
    integration = build(:jenkins_integration)
    expect(described_class.coerce_isolated_result(integration.type)).to eq 'JENKINS_SERVICE'
  end
end
