# frozen_string_literal: true

class AddNamespaceIdToUserAchievements < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :user_achievements, :namespace_id, :bigint
  end
end
