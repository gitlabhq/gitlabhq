class MigrateUrlToPath < ActiveRecord::Migration
  def up
    select_all("SELECT id, gitlab_url FROM projects").each do |project|
      path = project['gitlab_url'].sub(/.*\/(.*\/.*)$/, '\1')
      execute("UPDATE projects SET gitlab_url = '#{path}' WHERE id = '#{project['id']}'")
    end
  end

  def down
  end
end
