# frozen_string_literal: true

class ValidateAwardEmojiShardingKeyNotNullConstraint < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  def up
    validate_multi_column_not_null_constraint :award_emoji,
      :namespace_id,
      :organization_id,
      constraint_name: :check_8ef14b7067
  end

  def down
    # no-op
  end
end
