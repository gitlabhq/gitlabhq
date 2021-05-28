# frozen_string_literal: true

class AddDefaultValueToMergeRequestsAuthorApprovalOnProjects < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  def up
    with_lock_retries do
      change_column_default :projects, :merge_requests_author_approval, false
    end
  end

  def down
    with_lock_retries do
      change_column_default :projects, :merge_requests_author_approval, nil
    end
  end
end
