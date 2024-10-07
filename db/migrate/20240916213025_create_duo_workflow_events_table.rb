# frozen_string_literal: true

class CreateDuoWorkflowEventsTable < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    create_table :duo_workflows_events do |t| # rubocop:disable Migration/EnsureFactoryForTable -- https://gitlab.com/gitlab-org/gitlab/-/issues/468630
      t.references :workflow, foreign_key: { to_table: :duo_workflows_workflows, on_delete: :cascade }, null: false,
        index: true
      t.references :project, foreign_key: { to_table: :projects, on_delete: :cascade }, null: false,
        index: true
      t.timestamps_with_timezone null: false
      t.integer :event_type, limit: 2, null: false
      t.integer :event_status, limit: 2, null: false
      t.text :message, null: true, limit: 255
    end
  end
end
