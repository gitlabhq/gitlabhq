module SystemCheck
  module Orphans
    class RepositoryCheck < SystemCheck::BaseCheck
      set_name 'Orphaned repositories:'

      def multi_check
        Gitlab.config.repositories.storages.each do |name, repository_storage|
          $stdout.puts
          $stdout.puts "* Storage: #{name} (#{repository_storage['path']})".color(:yellow)

          repositories = toplevel_namespace_dirs(repository_storage['path']).map do |path|
            namespace = File.basename(path)
            Dir.glob(File.join(path, '*')).map {|repo| "#{namespace}/#{File.basename(repo)}"}
          end.try(:flatten!)

          orphans = (repositories - list_repositories(name))
          if orphans.empty?
            $stdout.puts "* No orphaned repositories for #{name} storage".color(:green)
            next
          end

          orphans.each do |orphan|
            $stdout.puts " - #{orphan}".color(:red)
          end
        end
      end

      private

      def list_repositories(storage_name)
        sql = "
          SELECT
            CONCAT(n.path, '/', p.path, '.git') repo,
            CONCAT(n.path, '/', p.path, '.wiki.git') wiki
          FROM projects p
            JOIN namespaces n
              ON (p.namespace_id = n.id)
          WHERE (p.repository_storage LIKE ?)
        "

        query = ActiveRecord::Base.send(:sanitize_sql_array, [sql, storage_name])
        ActiveRecord::Base.connection.select_all(query).rows.try(:flatten!)
      end

      def toplevel_namespace_dirs(storage_path)
        Dir.glob(File.join(storage_path, '*'))
      end
    end
  end
end
