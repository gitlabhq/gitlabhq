class AddMoreDbIndex < ActiveRecord::Migration
  def change
    add_index :deploy_keys_projects, :project_id
    add_index :web_hooks, :project_id
    add_index :protected_branches, :project_id

    add_index :users_groups, :user_id
    add_index :snippets, :author_id
    add_index :notes, :author_id
    add_index :notes, [:noteable_id, :noteable_type]
  end
end
