# rubocop:disable all
class FixNamespaces < ActiveRecord::Migration
  DOWNTIME = false

  def up
    namespaces = exec_query('SELECT id, path FROM namespaces WHERE name <> path and type is null')

    namespaces.each do |row|
      id = row['id']
      path = row['path']
      exec_query("UPDATE namespaces SET name = '#{path}' WHERE id = #{id}")
    end
  end

  def down
  end
end
