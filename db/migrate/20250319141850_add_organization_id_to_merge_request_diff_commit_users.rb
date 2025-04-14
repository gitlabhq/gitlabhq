# frozen_string_literal: true

class AddOrganizationIdToMergeRequestDiffCommitUsers < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    add_column :merge_request_diff_commit_users, :organization_id, :bigint
  end
end
