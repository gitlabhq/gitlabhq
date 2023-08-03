# frozen_string_literal: true

class ScheduleUniqueIndexProjectAuthorizationsOnUniqueProjectUser < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_unique_project_authorizations_on_unique_project_user'

  def up
    prepare_async_index :project_authorizations,
      %i[project_id user_id],
      unique: true,
      where: "is_unique",
      name: INDEX_NAME
  end

  def down
    unprepare_async_index :project_authorizations,
      %i[project_id user_id],
      name: INDEX_NAME
  end
end
