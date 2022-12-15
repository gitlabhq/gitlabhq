# frozen_string_literal: true

class AddAuthorizedScopesToSlackIntegration < Gitlab::Database::Migration[2.1]
  def up
    create_table :slack_api_scopes do |t|
      t.text :name, null: false, limit: 100

      t.index :name, name: 'index_slack_api_scopes_on_name', unique: true
    end

    create_table :slack_integrations_scopes do |t|
      references :slack_api_scope,
        null: false,
        index: false, # See composite index
        foreign_key: {
          to_table: :slack_api_scopes,
          on_delete: :cascade
        }

      references :slack_integration,
        null: false,
        index: false, # see composite index
        foreign_key: {
          to_table: :slack_integrations,
          on_delete: :cascade
        }

      t.index [:slack_integration_id, :slack_api_scope_id],
        unique: true,
        name: 'index_slack_api_scopes_on_name_and_integration'
    end
  end

  def down
    drop_table :slack_integrations_scopes, if_exists: true
    drop_table :slack_api_scopes, if_exists: true
  end
end
