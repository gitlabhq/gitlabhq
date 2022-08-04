# frozen_string_literal: true

class RemoveIntegrationsType < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  MIGRATION = 'BackfillIntegrationsTypeNew'
  BATCH_SIZE = 50
  TABLE_NAME = :integrations
  COLUMN = :type

  # see db/post_migrate/20220213104531_create_indexes_on_integration_type_new.rb
  def indices
    [
      {
        name: "index_integrations_on_project_and_#{COLUMN}_where_inherit_null",
        columns: [:project_id, COLUMN],
        where: 'inherit_from_id IS NULL'
      },
      {
        name: "index_integrations_on_project_id_and_#{COLUMN}_unique",
        columns: [:project_id, COLUMN],
        unique: true
      },
      {
        name: "index_integrations_on_#{COLUMN}",
        columns: [COLUMN]
      },
      {
        name: "index_integrations_on_#{COLUMN}_and_instance_partial",
        columns: [COLUMN, :instance],
        where: 'instance = true',
        unique: true
      },
      {
        name: 'index_integrations_on_type_id_when_active_and_project_id_not_nu',
        columns: [COLUMN, :id],
        where: '((active = true) AND (project_id IS NOT NULL))'
      },
      {
        name: "index_integrations_on_unique_group_id_and_#{COLUMN}",
        columns: [:group_id, COLUMN],
        unique: true
      }
    ]
  end

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: TABLE_NAME,
      column_name: :id,
      job_arguments: [])

    cleanup_unmigrated_rows!

    remove_column :integrations, :type, :text
  end

  # WARNING: this migration is not really safe to be reverted, since doing so
  # will leave the type column empty. If this migration is reverted, we will
  # need to backfill it from type_new
  def down
    add_column :integrations, :type, 'character varying'

    indices.each do |index|
      add_concurrent_index TABLE_NAME, index[:columns], index.except(:columns)
    end
  end

  # Convert any remaining unmigrated rows
  def cleanup_unmigrated_rows!
    tmp_index_name = 'tmp_idx_integrations_unmigrated_type_new'
    add_concurrent_index :integrations, :id, where: 'type_new is null', name: tmp_index_name

    define_batchable_model(:integrations).where(type_new: nil).each_batch do |batch|
      min_id, max_id = batch.pick(Arel.sql('MIN(id), MAX(id)'))

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
            WHERE integrations.type_new IS NULL
            AND integrations.id BETWEEN #{min_id} AND #{max_id}
            AND integrations.type = mapping.old_type
      SQL
    end
  ensure
    remove_concurrent_index_by_name(:integrations, tmp_index_name)
  end
end
