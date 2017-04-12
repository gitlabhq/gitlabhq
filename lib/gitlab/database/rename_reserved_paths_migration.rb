module Gitlab
  module Database
    module RenameReservedPathsMigration
      include MigrationHelpers
      include Namespaces
      include Projects

      def rename_wildcard_paths(one_or_more_paths)
        paths = Array(one_or_more_paths)
        rename_namespaces(paths, type: :wildcard)
      end

      def rename_root_paths(paths)
        paths = Array(paths)
        rename_namespaces(paths, type: :top_level)
      end

      def rename_path(namespace_path, path_was)
        counter = 0
        path = "#{path_was}#{counter}"

        while route_exists?(File.join(namespace_path, path))
          counter += 1
          path = "#{path_was}#{counter}"
        end

        path
      end

      def route_exists?(full_path)
        MigrationClasses::Route.where(Route.arel_table[:path].matches(full_path)).any?
      end
    end
  end
end
