module SystemCheck
  module Orphans
    class RepositoryCheck < SystemCheck::BaseCheck
      set_name 'Orphaned repositories:'
      attr_accessor :orphans

      def multi_check
        Gitlab.config.repositories.storages.each do |storage_name, repository_storage|
          storage_path = repository_storage.legacy_disk_path

          $stdout.puts
          $stdout.puts "* Storage: #{storage_name} (#{storage_path})".color(:yellow)

          repositories = disk_repositories(storage_path)
          orphans = (repositories - fetch_repositories(storage_name))

          print_orphans(orphans, storage_name)
        end
      end

      private

      def print_orphans(orphans, storage_name)
        if orphans.empty?
          $stdout.puts "* No orphaned repositories for #{storage_name} storage".color(:green)
          return
        end

        orphans.each do |orphan|
          $stdout.puts " - #{orphan}".color(:red)
        end
      end

      def disk_repositories(storage_path)
        fetch_disk_namespaces(storage_path).each_with_object([]) do |namespace_path, result|
          namespace = File.basename(namespace_path)
          next if namespace.eql?('@hashed')

          fetch_disk_repositories(namespace_path).each do |repo|
            result << "#{namespace}/#{File.basename(repo)}"
          end
        end
      end

      def fetch_repositories(storage_name)
        sql = "
          SELECT
            CONCAT(n.path, '/', p.path, '.git') repo,
            CONCAT(n.path, '/', p.path, '.wiki.git') wiki
          FROM projects p
            JOIN namespaces n
              ON (p.namespace_id = n.id AND
                  n.parent_id IS NULL)
          WHERE (p.repository_storage LIKE ?)
        "

        query = ActiveRecord::Base.send(:sanitize_sql_array, [sql, storage_name]) # rubocop:disable GitlabSecurity/PublicSend
        ActiveRecord::Base.connection.select_all(query).rows.try(:flatten!) || []
      end

      def fetch_disk_namespaces(storage_path)
        Dir.glob(File.join(storage_path, '*'))
      end

      def fetch_disk_repositories(namespace_path)
        Dir.glob(File.join(namespace_path, '*'))
      end
    end
  end
end
