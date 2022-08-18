# frozen_string_literal: true

class CreateMlExperiments < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    create_table :ml_experiments do |t|
      t.timestamps_with_timezone null: false
      t.bigint :iid, null: false
      t.bigint :project_id, null: false
      t.references :user, foreign_key: true, index: true, on_delete: :nullify
      t.text :name, limit: 255, null: false

      t.index [:project_id, :iid], unique: true
      t.index [:project_id, :name], unique: true
    end
  end
end
