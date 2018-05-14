module SystemCheck
  module Orphans
    class NamespaceCheck < SystemCheck::BaseCheck
      set_name 'Orphaned namespaces:'

      def multi_check
        Gitlab.config.repositories.storages.each do |storage_name, repository_storage|
          $stdout.puts
          $stdout.puts "* Storage: #{storage_name} (#{repository_storage.legacy_disk_path})".color(:yellow)
          toplevel_namespace_dirs = disk_namespaces(repository_storage.legacy_disk_path)

          orphans = (toplevel_namespace_dirs - existing_namespaces)
          print_orphans(orphans, storage_name)
        end

        clear_namespaces! # releases memory when check finishes
      end

      private

      def print_orphans(orphans, storage_name)
        if orphans.empty?
          $stdout.puts "* No orphaned namespaces for #{storage_name} storage".color(:green)
          return
        end

        orphans.each do |orphan|
          $stdout.puts " - #{orphan}".color(:red)
        end
      end

      def disk_namespaces(storage_path)
        fetch_disk_namespaces(storage_path).each_with_object([]) do |namespace_path, result|
          namespace = File.basename(namespace_path)
          next if namespace.eql?('@hashed')

          result << namespace
        end
      end

      def fetch_disk_namespaces(storage_path)
        Dir.glob(File.join(storage_path, '*'))
      end

      def existing_namespaces
        @namespaces ||= Namespace.where(parent: nil).all.pluck(:path)
      end

      def clear_namespaces!
        @namespaces = nil
      end
    end
  end
end
