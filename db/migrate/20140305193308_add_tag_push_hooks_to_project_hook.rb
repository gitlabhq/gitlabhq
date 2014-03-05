class AddTagPushHooksToProjectHook < ActiveRecord::Migration
  def change
    add_column :web_hooks, :tag_push_events, :boolean, default: false
  end
end
