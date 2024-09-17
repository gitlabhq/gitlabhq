# frozen_string_literal: true

class CreateWorkspacesAgentConfigVersions < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def up
    create_table :workspaces_agent_config_versions do |t| # rubocop:disable Migration/EnsureFactoryForTable -- version table should not be touched manually, it is managed by paper_trail
      t.datetime_with_timezone :created_at
      t.references :project, index: true, foreign_key: { on_delete: :cascade }, null: false
      t.bigint :item_id, null: false
      t.text   :event, null: false, limit: 20
      t.text   :whodunnit, limit: 255
      t.text   :item_type, null: false, limit: 255
      t.jsonb  :object
      t.jsonb  :object_changes

      t.index :item_id
    end
  end

  def down
    drop_table :workspaces_agent_config_versions
  end
end
