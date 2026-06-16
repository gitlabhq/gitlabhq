# frozen_string_literal: true

class CreateCdArtifactSources < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  def change
    create_table :cd_artifact_sources do |t|
      t.bigint :group_id, null: false
      t.bigint :service_id, null: false
      t.timestamps_with_timezone null: false

      t.index :group_id
      t.index :service_id, unique: true
    end
  end
end
