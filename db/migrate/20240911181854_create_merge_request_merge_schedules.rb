# frozen_string_literal: true

class CreateMergeRequestMergeSchedules < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    create_table :merge_request_merge_schedules do |t| # rubocop:disable Migration/EnsureFactoryForTable -- factory exists in spec/factories/merge_request_merge_schedule.rb
      t.references :merge_request, foreign_key: { on_delete: :cascade }, index: false, null: false
      t.datetime_with_timezone :merge_after

      t.bigint :project_id, null: false

      t.index :merge_request_id, unique: true
      t.index :project_id
    end
  end
end
