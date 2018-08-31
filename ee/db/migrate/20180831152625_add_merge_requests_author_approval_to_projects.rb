# frozen_string_literal: true

class AddMergeRequestsAuthorApprovalToProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :projects, :merge_requests_author_approval, :boolean
  end
end
