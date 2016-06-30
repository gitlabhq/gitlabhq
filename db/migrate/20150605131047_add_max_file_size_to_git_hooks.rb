# rubocop:disable all
class AddMaxFileSizeToGitHooks < ActiveRecord::Migration
  def change
    add_column :git_hooks, :max_file_size, :integer, default: 0
  end
end
