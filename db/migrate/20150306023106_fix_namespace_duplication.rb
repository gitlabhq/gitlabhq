class FixNamespaceDuplication < ActiveRecord::Migration
  def up
    #fixes path duplication
    select_all('SELECT MAX(id) max, COUNT(id) cnt, path FROM namespaces GROUP BY path HAVING COUNT(id) > 1').each do |nms|
      bad_nms_ids = select_all("SELECT id FROM namespaces WHERE path = '#{nms['path']}' AND id <> #{nms['max']}").map{|x| x["id"]}
      execute("UPDATE projects SET namespace_id = #{nms["max"]} WHERE namespace_id IN(#{bad_nms_ids.join(', ')})")
      execute("DELETE FROM namespaces WHERE id IN(#{bad_nms_ids.join(', ')})")
    end

    #fixes name duplication
    select_all('SELECT MAX(id) max, COUNT(id) cnt, name FROM namespaces GROUP BY name HAVING COUNT(id) > 1').each do |nms|
      bad_nms_ids = select_all("SELECT id FROM namespaces WHERE name = '#{nms['name']}' AND id <> #{nms['max']}").map{|x| x["id"]}
      execute("UPDATE projects SET namespace_id = #{nms["max"]} WHERE namespace_id IN(#{bad_nms_ids.join(', ')})")
      execute("DELETE FROM namespaces WHERE id IN(#{bad_nms_ids.join(', ')})")
    end
  end

  def down
    # not implemented
  end
end
