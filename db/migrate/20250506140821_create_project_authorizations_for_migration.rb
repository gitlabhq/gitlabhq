# frozen_string_literal: true

class CreateProjectAuthorizationsForMigration < Gitlab::Database::Migration[2.3]
  milestone '18.0'

  def change
    # rubocop:disable Migration/EnsureFactoryForTable -- replaces `project_authorizations` eventually
    create_table :project_authorizations_for_migration, primary_key: %i[user_id project_id] do |t|
      # rubocop:enable Migration/EnsureFactoryForTable
      t.bigint :user_id, null: false
      t.bigint :project_id, null: false
      t.integer :access_level, limit: 2, null: false
    end
  end
end
