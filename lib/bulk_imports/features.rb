# frozen_string_literal: true

module BulkImports
  module Features
    def self.project_migration_enabled?(destination_namespace = nil)
      if destination_namespace.present?
        root_ancestor = Namespace.find_by_full_path(destination_namespace)&.root_ancestor

        ::Feature.enabled?(:bulk_import_projects, root_ancestor)
      else
        ::Feature.enabled?(:bulk_import_projects)
      end
    end
  end
end
