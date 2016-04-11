class AddVisibilityLevelToSnippet < ActiveRecord::Migration
  def up
    add_column :snippets, :visibility_level, :integer, :default => 0, :null => false

    execute("UPDATE snippets SET visibility_level = #{Gitlab::VisibilityLevel::PRIVATE} WHERE private = true")
    execute("UPDATE snippets SET visibility_level = #{Gitlab::VisibilityLevel::INTERNAL} WHERE private = false")

    add_index :snippets, :visibility_level

    remove_column :snippets, :private
  end

  def down
    add_column :snippets, :private, :boolean, :default => false, :null => false

    execute("UPDATE snippets SET private = false WHERE visibility_level = #{Gitlab::VisibilityLevel::INTERNAL}")
    execute("UPDATE snippets SET private = true WHERE visibility_level = #{Gitlab::VisibilityLevel::PRIVATE}")

    remove_column :snippets, :visibility_level
  end
end
