# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CascadeDeleteFreezePeriods < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  OLD_PROJECT_FK = 'fk_rails_2e02bbd1a6'
  NEW_PROJECT_FK = 'fk_2e02bbd1a6'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :ci_freeze_periods, :projects, column: :project_id, on_delete: :cascade, name: NEW_PROJECT_FK
    remove_foreign_key_if_exists :ci_freeze_periods, :projects, column: :project_id, name: OLD_PROJECT_FK
  end

  def down
    add_concurrent_foreign_key :ci_freeze_periods, :projects, column: :project_id, on_delete: nil, name: OLD_PROJECT_FK
    remove_foreign_key_if_exists :ci_freeze_periods, :projects, column: :project_id, name: NEW_PROJECT_FK
  end
end
