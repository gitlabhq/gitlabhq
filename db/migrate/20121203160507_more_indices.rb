class MoreIndices < ActiveRecord::Migration
  def change
    add_index :notes, :project_id
    add_index :namespaces, :owner_id
    add_index :keys, :user_id

    add_index :projects, :namespace_id
    add_index :projects, :owner_id

    add_index :services, :project_id
    add_index :snippets, :project_id

    add_index :users_projects, :project_id

    # Issues
    add_index :issues, :assignee_id
    add_index :issues, :milestone_id
    add_index :issues, :author_id

    # Merge Requests
    add_index :merge_requests, :assignee_id
    add_index :merge_requests, :milestone_id
    add_index :merge_requests, :author_id

  end
end
