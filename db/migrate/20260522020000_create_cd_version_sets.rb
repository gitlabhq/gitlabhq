# frozen_string_literal: true

class CreateCdVersionSets < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  def change
    create_table :cd_version_sets do |t|
      t.bigint :group_id, null: false
      t.bigint :application_id, null: false
      t.bigint :environment_id, null: false
      t.timestamps_with_timezone null: false
      t.text :name, null: false, limit: 255

      t.index :group_id
      t.index [:application_id, :name], unique: true
    end
  end
end
