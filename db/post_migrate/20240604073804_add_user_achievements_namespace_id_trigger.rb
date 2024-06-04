# frozen_string_literal: true

class AddUserAchievementsNamespaceIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def up
    install_sharding_key_assignment_trigger(
      table: :user_achievements,
      sharding_key: :namespace_id,
      parent_table: :achievements,
      parent_sharding_key: :namespace_id,
      foreign_key: :achievement_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :user_achievements,
      sharding_key: :namespace_id,
      parent_table: :achievements,
      parent_sharding_key: :namespace_id,
      foreign_key: :achievement_id
    )
  end
end
