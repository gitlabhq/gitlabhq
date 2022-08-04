# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfills the new `integrations.type_new` column, which contains
    # the real class name, rather than the legacy class name in `type`
    # which is mapped via `Gitlab::Integrations::StiType`.
    class BackfillIntegrationsTypeNew
      include Gitlab::Database::DynamicModelHelpers

      def perform(start_id, stop_id, batch_table, batch_column, sub_batch_size, pause_ms)
        parent_batch_relation = define_batchable_model(batch_table, connection: connection)
          .where(batch_column => start_id..stop_id)

        parent_batch_relation.each_batch(column: batch_column, of: sub_batch_size) do |sub_batch|
          process_sub_batch(sub_batch)

          sleep(pause_ms * 0.001) if pause_ms > 0
        end
      end

      private

      def connection
        ApplicationRecord.connection
      end

      def process_sub_batch(sub_batch)
        # Extract the start/stop IDs from the current sub-batch
        sub_start_id, sub_stop_id = sub_batch.pick(Arel.sql('MIN(id), MAX(id)'))

        # This matches the mapping from the INSERT trigger added in
        # db/migrate/20210721135638_add_triggers_to_integrations_type_new.rb
        connection.execute(<<~SQL)
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
          WHERE integrations.id BETWEEN #{sub_start_id} AND #{sub_stop_id}
            AND integrations.type = mapping.old_type
        SQL
      end
    end
  end
end
