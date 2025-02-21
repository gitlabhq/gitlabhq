# frozen_string_literal: true

class RequeueLimitNamespaceVisibilityByOrganizationVisibility < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "LimitNamespaceVisibilityByOrganizationVisibility"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 3_000
  SUB_BATCH_SIZE = 300

  # `db/post_migrate/20250130093913_queue_limit_namespace_visibility_by_organization_visibility.rb` failed because of
  # `Sidekiq::Shutdown` so we need to re-enqueue the migration only for gitlab.com.
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/366720.
  def up
    return unless Gitlab.com_except_jh?

    delete_batched_background_migration(MIGRATION, :namespaces, :id, [])

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
    return unless Gitlab.com_except_jh?

    delete_batched_background_migration(MIGRATION, :namespaces, :id, [])
  end
end
