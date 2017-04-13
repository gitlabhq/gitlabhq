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

      def rename_path_for_routable(routable)
        old_path = routable.path
        old_full_path = routable.full_path
        # Only remove the last occurrence of the path name to get the parent namespace path
        namespace_path = remove_last_occurrence(old_full_path, old_path)
        new_path = rename_path(namespace_path, old_path)
        new_full_path = join_routable_path(namespace_path, new_path)

        # skips callbacks & validations
        routable.class.where(id: routable).
          update_all(path: new_path)

        rename_routes(old_full_path, new_full_path)

        [old_full_path, new_full_path]
      end

      def rename_routes(old_full_path, new_full_path)
        replace_statement = replace_sql(Route.arel_table[:path],
                                        old_full_path,
                                        new_full_path)

        update_column_in_batches(:routes, :path, replace_statement)  do |table, query|
          query.where(MigrationClasses::Route.arel_table[:path].matches("#{old_full_path}%"))
        end
      end

      def rename_path(namespace_path, path_was)
        counter = 0
        path = "#{path_was}#{counter}"

        while route_exists?(join_routable_path(namespace_path, path))
          counter += 1
          path = "#{path_was}#{counter}"
        end

        path
      end

      def remove_last_occurrence(string, pattern)
        string.reverse.sub(pattern.reverse, "").reverse
      end

      def join_routable_path(namespace_path, top_level)
        if namespace_path.present?
          File.join(namespace_path, top_level)
        else
          top_level
        end
      end

      def route_exists?(full_path)
        MigrationClasses::Route.where(Route.arel_table[:path].matches(full_path)).any?
      end
    end
  end
end
