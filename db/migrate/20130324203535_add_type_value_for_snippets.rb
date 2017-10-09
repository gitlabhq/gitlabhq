# rubocop:disable all
class AddTypeValueForSnippets < ActiveRecord::Migration[4.2]
  def up
    Snippet.where("project_id IS NOT NULL").update_all(type: 'ProjectSnippet')
  end

  def down
  end
end
