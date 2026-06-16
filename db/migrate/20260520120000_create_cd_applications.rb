# frozen_string_literal: true

class CreateCdApplications < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  def change
    create_table :cd_applications do |t|
      t.bigint :group_id, null: false
      t.timestamps_with_timezone null: false
      t.text :name, null: false, limit: 255
      t.text :description, limit: 2000

      t.index [:group_id, :name], unique: true
    end
  end
end
