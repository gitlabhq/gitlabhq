class AddFileNameRegexToGitHooks < ActiveRecord::Migration
  def change
    add_column :git_hooks, :file_name_regex, :string
  end
end
