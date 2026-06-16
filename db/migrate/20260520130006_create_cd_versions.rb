# frozen_string_literal: true

class CreateCdVersions < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  def change
    create_table :cd_versions do |t|
      t.bigint :group_id, null: false
      t.bigint :artifact_source_id, null: false
      t.timestamps_with_timezone null: false
      t.text :name, null: false, limit: 255

      t.index :group_id
      t.index [:artifact_source_id, :name], unique: true
    end
  end
end
