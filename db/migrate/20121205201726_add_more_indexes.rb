class AddMoreIndexes < ActiveRecord::Migration
  def change
    add_index :events, :created_at
    add_index :events, :target_id

    add_index :issues, :closed
    add_index :issues, :created_at
    add_index :issues, :title

    add_index :keys, :identifier
    # FIXME: MySQL can't index text columns
    #add_index :keys, :key
    add_index :keys, :project_id

    add_index :merge_requests, :closed
    add_index :merge_requests, :created_at
    add_index :merge_requests, :source_branch
    add_index :merge_requests, :target_branch
    add_index :merge_requests, :title

    add_index :milestones, :due_date
    add_index :milestones, :project_id

    add_index :namespaces, :name
    add_index :namespaces, :path
    add_index :namespaces, :type

    add_index :notes, :created_at

    add_index :snippets, :created_at
    add_index :snippets, :expires_at

    add_index :users, :admin
    add_index :users, :blocked
    add_index :users, :name
    add_index :users, :username

    add_index :users_projects, :project_access
    add_index :users_projects, :user_id

    add_index :wikis, :project_id
    add_index :wikis, :slug
  end
end
