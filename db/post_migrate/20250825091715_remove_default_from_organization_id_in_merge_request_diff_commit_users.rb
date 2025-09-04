# frozen_string_literal: true

class RemoveDefaultFromOrganizationIdInMergeRequestDiffCommitUsers < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  def up
    change_column_default :merge_request_diff_commit_users, :organization_id, from: 1, to: nil
  end

  def down
    change_column_default :merge_request_diff_commit_users, :organization_id, from: nil, to: 1
  end
end
