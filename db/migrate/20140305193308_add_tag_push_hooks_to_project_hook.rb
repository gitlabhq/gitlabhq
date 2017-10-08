# rubocop:disable all
class AddTagPushHooksToProjectHook < ActiveRecord::Migration[4.2]
  def change
    add_column :web_hooks, :tag_push_events, :boolean, default: false
  end
end
