# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Models
        class PersonalSnippet < Base
          self.table_name = 'personal_snippets_view'
          self.primary_key = :id

          scope :default, -> { readonly }

          def storage
            @storage ||= RepositoryStorage.new(self, prefix: RepositoryStorage::SNIPPET_REPOSITORY_PATH_PREFIX)
          end

          def disk_path
            "#{storage.disk_path}.git"
          end

          def path_with_namespace
            "snippets/#{id}"
          end
        end
      end
    end
  end
end
