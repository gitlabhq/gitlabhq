# frozen_string_literal: true

class ValidateCommitUserMentionsNamespaceIdFk < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  def up
    validate_foreign_key :commit_user_mentions, :namespace_id, name: :fk_2840265c3f
  end

  def down
    # no-op
  end
end
