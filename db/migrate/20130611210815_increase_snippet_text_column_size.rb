# rubocop:disable all
class IncreaseSnippetTextColumnSize < ActiveRecord::Migration[4.2]
  def up
    # MYSQL LARGETEXT for snippet
    change_column :snippets, :content, :text, :limit => 4294967295
  end

  def down
  end
end
