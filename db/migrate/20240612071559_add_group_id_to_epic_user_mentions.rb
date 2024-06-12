# frozen_string_literal: true

class AddGroupIdToEpicUserMentions < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :epic_user_mentions, :group_id, :bigint
  end
end
