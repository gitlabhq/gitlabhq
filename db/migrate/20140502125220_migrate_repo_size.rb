class MigrateRepoSize < ActiveRecord::Migration
  def up
    project_data = execute('SELECT projects.id, namespaces.path AS namespace_path, projects.path AS project_path FROM projects LEFT JOIN namespaces ON projects.namespace_id = namespaces.id')

    project_data.each do |project|
      id = project['id']
      namespace_path = project['namespace_path'] || ''
      path = File.join(Gitlab.config.gitlab_shell.repos_path, namespace_path, project['project_path'] + '.git')

      begin
        repo = Gitlab::Git::Repository.new(path)
        if repo.empty?
          print '-'
        else
          size = repo.size
          print '.'
          execute("UPDATE projects SET repository_size = #{size} WHERE id = #{id}")
        end
      rescue => e
        puts "\nFailed to update project #{id}: #{e}"
      end
    end
    puts "\nDone"
  end

  def down
  end
end
