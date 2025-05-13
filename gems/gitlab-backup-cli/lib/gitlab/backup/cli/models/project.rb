# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Models
        class Project < Base
          self.table_name = 'project_routes_view'
          self.primary_key = :id

          scope :default, -> { readonly }

          def storage
            @storage ||= RepositoryStorage.new(self, prefix: RepositoryStorage::REPOSITORY_PATH_PREFIX)
          end

          def disk_path
            "#{storage.disk_path}.git"
          end
        end
      end
    end
  end
end
