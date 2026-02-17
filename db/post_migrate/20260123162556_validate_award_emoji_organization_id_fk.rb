# frozen_string_literal: true

class ValidateAwardEmojiOrganizationIdFk < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  def up
    validate_foreign_key :award_emoji, :organization_id, name: :fk_5e03b44d0b
  end

  def down
    # no-op
  end
end
