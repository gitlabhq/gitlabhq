class AddTypeValueForSnippets < ActiveRecord::Migration
  def up
    Snippet.where("project_id IS NOT NULL").update_all(type: 'ProjectSnippet')
  end

  def down
  end
end
