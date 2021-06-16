# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddRunnersCreatedAtIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_runners, [:created_at, :id], order: { id: :desc }, name: 'index_ci_runners_on_created_at_and_id_desc'
    add_concurrent_index :ci_runners, [:created_at, :id], order: { created_at: :desc, id: :desc }, name: 'index_ci_runners_on_created_at_desc_and_id_desc'
  end

  def down
    remove_concurrent_index :ci_runners, [:created_at, :id], order: { id: :desc }, name: 'index_ci_runners_on_created_at_and_id_desc'
    remove_concurrent_index :ci_runners, [:created_at, :id], order: { created_at: :desc, id: :desc }, name: 'index_ci_runners_on_created_at_desc_and_id_desc'
  end
end
