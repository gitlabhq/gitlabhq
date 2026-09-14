# frozen_string_literal: true

class AddTmpIndexOnAwardEmojiForIssues < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'tmp_idx_award_emoji_on_id_where_awardable_type_issue'

  disable_ddl_transaction!
  milestone '19.4'

  # Supports the FixAwardEmojiNamespaceIdForIssues BBM. Dropped in 19.6, once the BBM is
  # finalized: https://gitlab.com/gitlab-org/gitlab/-/issues/628743
  def up
    add_concurrent_index :award_emoji, :id, name: INDEX_NAME, where: "awardable_type = 'Issue'"
  end

  def down
    remove_concurrent_index_by_name :award_emoji, INDEX_NAME
  end
end
