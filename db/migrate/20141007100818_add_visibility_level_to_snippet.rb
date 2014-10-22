class AddVisibilityLevelToSnippet < ActiveRecord::Migration
  def up
    add_column :snippets, :visibility_level, :integer, :default => 0, :null => false

    Snippet.where(private: true).update_all(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
    Snippet.where(private: false).update_all(visibility_level: Gitlab::VisibilityLevel::INTERNAL)

    add_index :snippets, :visibility_level

    remove_column :snippets, :private
  end

  def down
    add_column :snippets, :private, :boolean, :default => false, :null => false
    
    Snippet.where(visibility_level: Gitlab::VisibilityLevel::INTERNAL).update_all(private: false)
    Snippet.where(visibility_level: Gitlab::VisibilityLevel::PRIVATE).update_all(private: true)
    
    remove_column :snippets, :visibility_level
  end
end
