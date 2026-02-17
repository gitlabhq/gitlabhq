# frozen_string_literal: true

class ValidateAwardEmojiNamespaceIdFk < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  def up
    validate_foreign_key :award_emoji, :namespace_id, name: :fk_e766b8f650
  end

  def down
    # no-op
  end
end
