# frozen_string_literal: true

class ScheduleIndexToProjectAuthorizationsOnProjectUserAccessLevel < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_project_authorizations_on_project_user_access_level'

  disable_ddl_transaction!

  def up
    prepare_async_index :project_authorizations, %i[project_id user_id access_level], unique: true, name: INDEX_NAME
  end

  def down
    unprepare_async_index :project_authorizations, %i[project_id user_id access_level], name: INDEX_NAME
  end
end
