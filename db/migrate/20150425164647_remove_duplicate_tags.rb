class RemoveDuplicateTags < ActiveRecord::Migration
  def up
    select_all("SELECT name, COUNT(id) as cnt FROM tags GROUP BY name HAVING COUNT(id) > 1").each do |tag|
      tag_name = quote_string(tag["name"])
      duplicate_ids = select_all("SELECT id FROM tags WHERE name = '#{tag_name}'").map{|tag| tag["id"]}
      origin_tag_id = duplicate_ids.first
      duplicate_ids.delete origin_tag_id

      execute("UPDATE taggings SET tag_id = #{origin_tag_id} WHERE tag_id IN(#{duplicate_ids.join(",")})")
      execute("DELETE FROM tags WHERE id IN(#{duplicate_ids.join(",")})")
    end
  end

  def down
    
  end
end
