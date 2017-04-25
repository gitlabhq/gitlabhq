module Gitlab
  module Database
    module RenameReservedPathsMigration
      module V1
        def self.included(kls)
          kls.include(MigrationHelpers)
        end

        def rename_wildcard_paths(one_or_more_paths)
          paths = Array(one_or_more_paths)
          RenameNamespaces.new(paths, self).rename_namespaces(type: :wildcard)
          RenameProjects.new(paths, self).rename_projects
        end

        def rename_root_paths(paths)
          paths = Array(paths)
          RenameNamespaces.new(paths, self).rename_namespaces(type: :top_level)
        end
      end
    end
  end
end
