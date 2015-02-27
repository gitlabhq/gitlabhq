class AddIndexToCreatedAt < ActiveRecord::Migration
  def change
    add_index "users", [:created_at, :id]
    add_index "members", [:created_at, :id]
    add_index "projects", [:created_at, :id]
    add_index "issues", [:created_at, :id]
    add_index "merge_requests", [:created_at, :id]
    add_index "milestones", [:created_at, :id]
    add_index "namespaces", [:created_at, :id]
    add_index "notes", [:created_at, :id]
    add_index "identities", [:created_at, :id]
    add_index "keys", [:created_at, :id]
    add_index "web_hooks", [:created_at, :id]
    add_index "snippets", [:created_at, :id]
  end
end
