# frozen_string_literal: true

class CompleteMigrateSecurityScans < ActiveRecord::Migration[6.0]
  disable_ddl_transaction!

  def up
    Gitlab::BackgroundMigration.steal('MigrateSecurityScans')
  end

  def down
    # intentionally blank
  end
end
