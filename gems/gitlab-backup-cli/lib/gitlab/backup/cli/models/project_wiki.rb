# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Models
        class ProjectWiki < Base
          self.table_name = 'project_routes_view'
          self.primary_key = :id

          scope :default, -> { readonly }

          def storage
            @storage ||= RepositoryStorage.new(self, prefix: RepositoryStorage::REPOSITORY_PATH_PREFIX)
          end

          def disk_path
            "#{storage.disk_path}.wiki.git"
          end

          def path_with_namespace
            "#{read_attribute(:path_with_namespace)}.wiki"
          end
        end
      end
    end
  end
end
