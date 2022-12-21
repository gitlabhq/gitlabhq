# frozen_string_literal: true

class CreateUserAchievements < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    create_table :user_achievements do |t|
      t.references :achievement,
                    null: false,
                    index: false,
                    foreign_key: { on_delete: :cascade }
      t.bigint :user_id,
                null: false
      t.bigint :awarded_by_user_id,
                null: true
      t.bigint :revoked_by_user_id,
                index: true,
                null: true
      t.timestamps_with_timezone null: false
      t.datetime_with_timezone :revoked_at, null: true
      t.index 'achievement_id, (revoked_by_user_id IS NULL)',
              name: 'index_user_achievements_on_achievement_id_revoked_by_is_null'
      t.index 'user_id, (revoked_by_user_id IS NULL)',
              name: 'index_user_achievements_on_user_id_revoked_by_is_null'
      t.index 'awarded_by_user_id, (revoked_by_user_id IS NULL)',
              name: 'index_user_achievements_on_awarded_by_revoked_by_is_null'
    end
  end

  def down
    drop_table :user_achievements
  end
end
