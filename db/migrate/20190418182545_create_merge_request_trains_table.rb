# frozen_string_literal: true

class CreateMergeRequestTrainsTable < ActiveRecord::Migration[5.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :merge_trains, id: :bigserial do |t|
      t.references :merge_request, foreign_key: { on_delete: :cascade }, type: :integer, index: false, null: false
      t.references :user, foreign_key: { on_delete: :cascade }, type: :integer, null: false
      t.references :pipeline, foreign_key: { to_table: :ci_pipelines, on_delete: :nullify }, type: :integer
      t.timestamps_with_timezone null: false

      t.index [:merge_request_id], unique: true
    end
  end
end
