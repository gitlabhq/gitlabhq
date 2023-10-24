# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddIndexStoppingEnvironmentsOnUpdatedAt < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_environments_on_updated_at_for_stopping_state'

  disable_ddl_transaction!

  def up
    add_concurrent_index :environments, :updated_at, where: "state = 'stopping'", name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :environments, name: INDEX_NAME
  end
end
