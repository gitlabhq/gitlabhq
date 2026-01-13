# frozen_string_literal: true

class QueueBuildsMetadataMigrationForSelfManaged < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  # reintroduced in db/post_migrate/20260107142958_re_queue_builds_metadata_migration_for_self_managed.rb
  def up; end
  def down; end
end
