# frozen_string_literal: true

class AddTriggersToIntegrationsTypeNew < ActiveRecord::Migration[6.1]
  include Gitlab::Database::SchemaHelpers

  FUNCTION_NAME = 'integrations_set_type_new'
  TRIGGER_ON_INSERT_NAME = 'trigger_type_new_on_insert'

  def up
    create_trigger_function(FUNCTION_NAME, replace: true) do
      # This list matches `Gitlab::Integrations::StiType::NAMESPACED_INTEGRATIONS`.
      #
      # If we add new integrations after this migration we can directly use the
      # correct class name in `type`, and don't need to add it to `NAMESPACED_INTEGRATIONS`.
      <<~SQL
        WITH mapping(old_type, new_type) AS (VALUES
          ('AsanaService',                   'Integrations::Asana'),
          ('AssemblaService',                'Integrations::Assembla'),
          ('BambooService',                  'Integrations::Bamboo'),
          ('BugzillaService',                'Integrations::Bugzilla'),
          ('BuildkiteService',               'Integrations::Buildkite'),
          ('CampfireService',                'Integrations::Campfire'),
          ('ConfluenceService',              'Integrations::Confluence'),
          ('CustomIssueTrackerService',      'Integrations::CustomIssueTracker'),
          ('DatadogService',                 'Integrations::Datadog'),
          ('DiscordService',                 'Integrations::Discord'),
          ('DroneCiService',                 'Integrations::DroneCi'),
          ('EmailsOnPushService',            'Integrations::EmailsOnPush'),
          ('EwmService',                     'Integrations::Ewm'),
          ('ExternalWikiService',            'Integrations::ExternalWiki'),
          ('FlowdockService',                'Integrations::Flowdock'),
          ('HangoutsChatService',            'Integrations::HangoutsChat'),
          ('IrkerService',                   'Integrations::Irker'),
          ('JenkinsService',                 'Integrations::Jenkins'),
          ('JiraService',                    'Integrations::Jira'),
          ('MattermostService',              'Integrations::Mattermost'),
          ('MattermostSlashCommandsService', 'Integrations::MattermostSlashCommands'),
          ('MicrosoftTeamsService',          'Integrations::MicrosoftTeams'),
          ('MockCiService',                  'Integrations::MockCi'),
          ('MockMonitoringService',          'Integrations::MockMonitoring'),
          ('PackagistService',               'Integrations::Packagist'),
          ('PipelinesEmailService',          'Integrations::PipelinesEmail'),
          ('PivotaltrackerService',          'Integrations::Pivotaltracker'),
          ('PrometheusService',              'Integrations::Prometheus'),
          ('PushoverService',                'Integrations::Pushover'),
          ('RedmineService',                 'Integrations::Redmine'),
          ('SlackService',                   'Integrations::Slack'),
          ('SlackSlashCommandsService',      'Integrations::SlackSlashCommands'),
          ('TeamcityService',                'Integrations::Teamcity'),
          ('UnifyCircuitService',            'Integrations::UnifyCircuit'),
          ('YoutrackService',                'Integrations::Youtrack'),
          ('WebexTeamsService',              'Integrations::WebexTeams'),

          -- EE-only integrations
          ('GithubService',                  'Integrations::Github'),
          ('GitlabSlackApplicationService',  'Integrations::GitlabSlackApplication')
        )

        UPDATE integrations SET type_new = mapping.new_type
        FROM mapping
        WHERE integrations.id = NEW.id
          AND mapping.old_type = NEW.type;
        RETURN NULL;
      SQL
    end

    execute(<<~SQL)
      CREATE TRIGGER #{TRIGGER_ON_INSERT_NAME}
      AFTER INSERT ON integrations
      FOR EACH ROW
      EXECUTE FUNCTION #{FUNCTION_NAME}();
    SQL
  end

  def down
    drop_trigger(:integrations, TRIGGER_ON_INSERT_NAME)
    drop_function(FUNCTION_NAME)
  end
end
