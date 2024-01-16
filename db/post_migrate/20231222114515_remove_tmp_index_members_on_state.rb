# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveTmpIndexMembersOnState < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.8'

  INDEX_NAME = 'tmp_index_members_on_state'

  def up
    remove_concurrent_index_by_name :members, INDEX_NAME
  end

  def down
    add_concurrent_index :members, :state, name: INDEX_NAME, where: 'state = 2'
  end
end
