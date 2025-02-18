# frozen_string_literal: true

class AddEpicUserMentionsGroupIdNotNullConstraint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  def up
    add_not_null_constraint :epic_user_mentions, :group_id, validate: false
  end

  def down
    remove_not_null_constraint :epic_user_mentions, :group_id
  end
end
