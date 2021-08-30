# frozen_string_literal: true

class UpdateExternalProjectBots < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  class User < ActiveRecord::Base
    self.table_name = 'users'
  end

  disable_ddl_transaction!

  TMP_INDEX_NAME = 'tmp_idx_update_external_project_bots'

  def up
    add_concurrent_index('users', 'id', name: TMP_INDEX_NAME, where: 'external = true')

    ids = ActiveRecord::Base.connection
                            .execute("SELECT u.id FROM users u JOIN users u2 on u2.id = u.created_by_id WHERE u.user_type = 6 AND u2.external = true")
                            .map { |result| result['id'] }

    ids.each_slice(10) do |group|
      UpdateExternalProjectBots::User.where(id: group).update_all(external: true)
    end

    remove_concurrent_index_by_name('users', TMP_INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name('users', TMP_INDEX_NAME) if index_exists_by_name?('users', TMP_INDEX_NAME)

    # This migration is irreversible
  end
end
