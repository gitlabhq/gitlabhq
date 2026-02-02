# frozen_string_literal: true

class ValidateCommitUserMentionsNamespaceIdNotNullConstraint < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  CONSTRAINT_NAME = 'check_ddd6f289f4'

  def up
    validate_not_null_constraint :commit_user_mentions, :namespace_id, constraint_name: CONSTRAINT_NAME
  end

  def down
    # no-op
  end
end
