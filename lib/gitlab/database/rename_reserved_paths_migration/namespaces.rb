module Gitlab
  module Database
    module RenameReservedPathsMigration
      module Namespaces
        include Gitlab::ShellAdapter

        def rename_namespaces(paths, type:)
          namespaces_for_paths(paths, type: type).each do |namespace|
            rename_namespace(namespace)
          end
        end

        def namespaces_for_paths(paths, type:)
          namespaces = if type == :wildcard
                         MigrationClasses::Namespace.where.not(parent_id: nil)
                       elsif type == :top_level
                         MigrationClasses::Namespace.where(parent_id: nil)
                       end
          with_paths = MigrationClasses::Namespace.arel_table[:path].
                        matches_any(paths)
          namespaces.where(with_paths)
        end

        def rename_namespace(namespace)
          old_full_path, new_full_path = rename_path_for_routable(namespace)

          move_repositories(namespace, old_full_path, new_full_path)
          move_uploads(old_full_path, new_full_path)
          move_pages(old_full_path, new_full_path)
        end

        def move_repositories(namespace, old_full_path, new_full_path)
          repo_paths_for_namespace(namespace).each do |repository_storage_path|
            # Ensure old directory exists before moving it
            gitlab_shell.add_namespace(repository_storage_path, old_full_path)

            unless gitlab_shell.mv_namespace(repository_storage_path, old_full_path, new_full_path)
              message = "Exception moving path #{repository_storage_path} \
                           from #{old_full_path} to #{new_full_path}"
              Rails.logger.error message
            end
          end
        end

        def repo_paths_for_namespace(namespace)
          projects_for_namespace(namespace).
            select('distinct(repository_storage)').map(&:repository_storage_path)
        end

        def projects_for_namespace(namespace)
          namespace_ids = child_ids_for_parent(namespace, ids: [namespace.id])
          namespace_or_children = MigrationClasses::Project.
                                    arel_table[:namespace_id].
                                    in(namespace_ids)
          MigrationClasses::Project.unscoped.where(namespace_or_children)
        end

        # This won't scale to huge trees, but it should do for a handful of
        # namespaces called `system`.
        def child_ids_for_parent(namespace, ids: [])
          namespace.children.each do |child|
            ids << child.id
            child_ids_for_parent(child, ids: ids) if child.children.any?
          end
          ids
        end
      end
    end
  end
end
