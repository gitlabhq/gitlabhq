# frozen_string_literal: true

class ValidateEpicUserMentionsGroupIdNotNullConstraint < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def up
    validate_not_null_constraint :epic_user_mentions, :group_id
  end

  def down
    # no-op
  end
end
