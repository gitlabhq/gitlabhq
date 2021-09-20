# frozen_string_literal: true

class UpdateIntegrationsTriggerTypeNewOnInsert < ActiveRecord::Migration[6.1]
  include Gitlab::Database::SchemaHelpers

  FUNCTION_NAME = 'integrations_set_type_new'

  def up
    # Update `type_new` dynamically based on `type`.
    #
    # The old class names are in the format `AbcService`, and the new ones `Integrations::Abc`.
    create_trigger_function(FUNCTION_NAME, replace: true) do
      <<~SQL
        UPDATE integrations SET type_new = regexp_replace(NEW.type, '\\A(.+)Service\\Z', 'Integrations::\\1')
        WHERE integrations.id = NEW.id;
        RETURN NULL;
      SQL
    end
  end

  def down
    # We initially went with this static mapping since we assumed that new integrations could
    # just use the correct class name directly in `type`, but this will complicate the data migration
    # since we plan to drop `type` at some point and replace it with `type_new`, so we still need
    # to keep this column filled for all records.
    create_trigger_function(FUNCTION_NAME, replace: true) do
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
  end
end
