# frozen_string_literal: true

class CreateExternalPullRequests < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX = 'index_external_pull_requests_on_project_and_branches'

  # rubocop:disable Migration/PreventStrings
  def change
    create_table :external_pull_requests do |t|
      t.timestamps_with_timezone null: false
      t.references :project, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.integer :pull_request_iid, null: false
      t.integer :status, null: false, limit: 2
      t.string :source_branch, null: false, limit: 255
      t.string :target_branch, null: false, limit: 255
      t.string :source_repository, null: false, limit: 255
      t.string :target_repository, null: false, limit: 255
      t.binary :source_sha, null: false
      t.binary :target_sha, null: false

      t.index [:project_id, :source_branch, :target_branch], unique: true, name: INDEX
    end
  end
  # rubocop:enable Migration/PreventStrings
end
