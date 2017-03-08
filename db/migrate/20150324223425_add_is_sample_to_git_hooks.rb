# rubocop:disable all
class AddIsSampleToGitHooks < ActiveRecord::Migration
  def change
    add_column :git_hooks, :is_sample, :boolean, default: false
  end
end
