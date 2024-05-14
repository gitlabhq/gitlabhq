# frozen_string_literal: true

class QueueDisableAllowRunnerRegistrationOnNamespaceSettingsForGitlabCom < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = 'DisableAllowRunnerRegistrationOnNamespaceSettingsForGitlabCom'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 25_000
  SUB_BATCH_SIZE = 250

  def up
    return unless should_run?

    queue_batched_background_migration(
      MIGRATION,
      :namespaces,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    return unless should_run?

    delete_batched_background_migration(MIGRATION, :namespaces, :id, [])
  end

  private

  def should_run?
    ::Gitlab.com? && !::Gitlab::CurrentSettings.gitlab_dedicated_instance?
  end
end
