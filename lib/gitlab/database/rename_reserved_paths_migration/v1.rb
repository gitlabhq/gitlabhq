# This module can be included in migrations to make it easier to rename paths
# of `Namespace` & `Project` models certain paths would become `reserved`.
#
# If the way things are stored on the filesystem related to namespaces and
# projects ever changes. Don't update this module, or anything nested in `V1`,
# since it needs to keep functioning for all migrations using it using the state
# that the data is in at the time. Instead, create a `V2` module that implements
# the new way of reserving paths.
module Gitlab
  module Database
    module RenameReservedPathsMigration
      module V1
        def self.included(kls)
          kls.include(MigrationHelpers)
        end

        def rename_wildcard_paths(one_or_more_paths)
          rename_child_paths(one_or_more_paths)
          paths = Array(one_or_more_paths)
          RenameProjects.new(paths, self).rename_projects
        end

        def rename_child_paths(one_or_more_paths)
          paths = Array(one_or_more_paths)
          RenameNamespaces.new(paths, self).rename_namespaces(type: :child)
        end

        def rename_root_paths(paths)
          paths = Array(paths)
          RenameNamespaces.new(paths, self).rename_namespaces(type: :top_level)
        end

        def revert_renames
          RenameProjects.new([], self).revert_renames
          RenameNamespaces.new([], self).revert_renames
        end
      end
    end
  end
end
