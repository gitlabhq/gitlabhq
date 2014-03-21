class CreateGitHooks < ActiveRecord::Migration
  def change
    create_table :git_hooks do |t|
      t.string :force_push_regex
      t.string :delete_branch_regex
      t.string :commit_message_regex
      t.boolean :deny_delete_tag
      t.integer :project_id

      t.timestamps
    end
  end
end
