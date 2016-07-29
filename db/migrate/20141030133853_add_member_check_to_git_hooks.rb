# rubocop:disable all
class AddMemberCheckToGitHooks < ActiveRecord::Migration
  def change
    add_column :git_hooks, :member_check, :boolean, default: false, null: false
  end
end
