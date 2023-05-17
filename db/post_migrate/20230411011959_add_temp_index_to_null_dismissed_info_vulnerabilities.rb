# frozen_string_literal: true

class AddTempIndexToNullDismissedInfoVulnerabilities < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'tmp_index_vulnerability_dismissal_info'

  disable_ddl_transaction!

  def up
    # Temporary index to be removed in https://gitlab.com/gitlab-org/gitlab/-/issues/406653
    add_concurrent_index :vulnerabilities, :id,
      where: "state = 2 AND (dismissed_at IS NULL OR dismissed_by_id IS NULL)",
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :vulnerabilities, INDEX_NAME
  end
end
