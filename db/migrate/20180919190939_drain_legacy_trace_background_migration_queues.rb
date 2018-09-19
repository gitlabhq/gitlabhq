# frozen_string_literal: true

class DrainLegacyTraceBackgroundMigrationQueues < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # See https://gitlab.com/gitlab-org/gitlab-ce/issues/50712
    Gitlab::BackgroundMigration.steal('ArchiveLegacyTraces')
  end

  def down
    # no-op
  end
end
