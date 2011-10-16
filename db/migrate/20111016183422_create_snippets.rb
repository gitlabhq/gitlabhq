class CreateSnippets < ActiveRecord::Migration
  def change
    create_table :snippets do |t|
      t.string :title
      t.text :content
      t.integer :author_id, :null => false
      t.integer :project_id, :null => false

      t.timestamps
    end
  end
end
