# frozen_string_literal: true

class CreateCoverageFuzzingCorpuses < Gitlab::Database::Migration[1.0]
  def change
    create_table :coverage_fuzzing_corpuses do |t|
      t.bigint :project_id, null: false
      t.bigint :user_id
      t.bigint :package_id, null: false

      t.datetime_with_timezone :file_updated_at, null: false, default: -> { 'NOW()' }
      t.timestamps_with_timezone null: false

      t.index :project_id
      t.index :user_id
      t.index :package_id
    end
  end
end
