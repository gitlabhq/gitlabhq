# frozen_string_literal: true

class FixBrokenUserAchievementsAwarded < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '16.7'

  class User < MigrationRecord
    self.table_name = 'users'
  end

  def up
    User.reset_column_information

    ghost_id = User.where(user_type: 5).first&.id

    return unless ghost_id

    update_column_in_batches(:user_achievements, :awarded_by_user_id, ghost_id) do |table, query|
      query.where(table[:awarded_by_user_id].eq(nil))
    end
  end

  def down
    # noop -- this is a data migration and can't be reversed
  end
end
