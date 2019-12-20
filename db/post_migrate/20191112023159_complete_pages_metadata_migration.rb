# frozen_string_literal: true

class CompletePagesMetadataMigration < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def up
    Gitlab::BackgroundMigration.steal('MigratePagesMetadata')
  end

  def down
    # no-op
  end
end
