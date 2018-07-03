# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AlterWebHookLogsIndexes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  # "created_at" comes first so the Sidekiq worker pruning old webhook logs can
  # use a composite index index.
  #
  # We leave the old standalone index on "web_hook_id" in place so future code
  # that doesn't care about "created_at" can still use that index.
  COLUMNS_TO_INDEX = %i[created_at web_hook_id]

  def up
    add_concurrent_index(:web_hook_logs, COLUMNS_TO_INDEX)
  end

  def down
    remove_concurrent_index(:web_hook_logs, COLUMNS_TO_INDEX)
  end
end
