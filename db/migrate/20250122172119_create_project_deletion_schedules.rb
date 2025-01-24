# frozen_string_literal: true

class CreateProjectDeletionSchedules < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    create_table :project_deletion_schedules, id: false do |t| # rubocop:disable Migration/EnsureFactoryForTable, Lint/RedundantCopDisableDirective -- Factory created in EE
      t.bigint :project_id, null: false, default: nil, primary_key: true
      t.bigint :user_id, null: false
      t.datetime_with_timezone :marked_for_deletion_at, null: false

      t.index :user_id
      t.index [:marked_for_deletion_at, :user_id], name: :index_project_deletions_on_marked_for_deletion_at_and_user_id
    end
  end
end
