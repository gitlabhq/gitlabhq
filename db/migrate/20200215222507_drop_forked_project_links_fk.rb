# frozen_string_literal: true

class DropForkedProjectLinksFk < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists :forked_project_links, column: :forked_to_project_id
    end
  end

  def down
    unless foreign_key_exists?(:forked_project_links, :projects, column: :forked_to_project_id)
      with_lock_retries do
        add_foreign_key :forked_project_links, :projects, column: :forked_to_project_id, on_delete: :cascade, validate: false
      end
    end

    fk_name = concurrent_foreign_key_name(:forked_project_links, :forked_to_project_id, prefix: 'fk_rails_')
    validate_foreign_key(:forked_project_links, :forked_to_project_id, name: fk_name)
  end
end
