class CreateCiBuildsMetadataTable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :ci_builds_metadata do |t|
      t.integer :build_id, null: false
      t.integer :used_timeout
      t.integer :timeout_source
    end
  end
end
