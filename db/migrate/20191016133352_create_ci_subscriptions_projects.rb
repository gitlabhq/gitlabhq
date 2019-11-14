# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateCiSubscriptionsProjects < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    create_table :ci_subscriptions_projects do |t|
      t.references :downstream_project, null: false, index: false, foreign_key: { to_table: :projects, on_delete: :cascade }
      t.references :upstream_project, null: false, foreign_key: { to_table: :projects, on_delete: :cascade }
    end

    add_index :ci_subscriptions_projects, [:downstream_project_id, :upstream_project_id],
      unique: true, name: 'index_ci_subscriptions_projects_unique_subscription'
  end
end
