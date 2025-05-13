# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Models
        class GroupWiki < Base
          self.table_name = 'group_wikis_routes_view'
          self.primary_key = :group_id

          scope :default, -> { readonly }

          def storage
            @storage ||= RepositoryStorage.new(self, prefix: RepositoryStorage::GROUP_REPOSITORY_PATH_PREFIX)
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
