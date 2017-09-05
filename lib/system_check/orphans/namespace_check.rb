module SystemCheck
  module Orphans
    class NamespaceCheck < SystemCheck::BaseCheck
      set_name 'Orphaned namespaces:'

      def multi_check
        Gitlab.config.repositories.storages.each do |name, repository_storage|
          $stdout.puts
          $stdout.puts "* Storage: #{name} (#{repository_storage['path']})".color(:yellow)
          toplevel_namespace_dirs = Dir.glob(File.join(repository_storage['path'], '*')).map{|p| File.basename(p)}

          orphans = (toplevel_namespace_dirs - existing_namespaces)
          if orphans.empty?
            $stdout.puts "* No orphaned namespaces for #{name} storage".color(:green)
            next
          end

          orphans.each do |orphan|
            $stdout.puts " - #{orphan}".color(:red)
          end
        end

        clear_namespaces! # releases memory when check finishes
      end

      private

      def existing_namespaces
        @namespaces ||= Namespace.all.pluck(:path)
      end

      def clear_namespaces!
        @namespaces = nil
      end
    end
  end
end
