# frozen_string_literal: true

class StealEncryptRunnersTokens < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  # This cleans after `EncryptRunnersTokens`

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    Gitlab::BackgroundMigration.steal('EncryptRunnersTokens')
  end

  def down
    # no-op
  end
end
