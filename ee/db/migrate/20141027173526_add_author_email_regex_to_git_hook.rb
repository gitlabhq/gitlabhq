class AddAuthorEmailRegexToGitHook < ActiveRecord::Migration
  def change
    add_column :git_hooks, :author_email_regex, :string
  end
end
