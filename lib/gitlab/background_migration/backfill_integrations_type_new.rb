# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfills the new `integrations.type_new` column, which contains
    # the real class name, rather than the legacy class name in `type`
    # which is mapped via `Gitlab::Integrations::StiType`.
    class BackfillIntegrationsTypeNew
      def perform(start_id, stop_id, *args)
        ActiveRecord::Base.connection.execute(<<~SQL)
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
            ('WebexTeamsService',              'Integrations::WebexTeams'),
            ('YoutrackService',                'Integrations::Youtrack'),

            -- EE-only integrations
            ('GithubService',                  'Integrations::Github'),
            ('GitlabSlackApplicationService',  'Integrations::GitlabSlackApplication')
          )

          UPDATE integrations SET type_new = mapping.new_type
          FROM mapping
          WHERE integrations.id BETWEEN #{start_id} AND #{stop_id}
            AND integrations.type = mapping.old_type
        SQL
      end
    end
  end
end
