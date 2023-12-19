# frozen_string_literal: true

# Snippets::RepositoryStorageMove are details of repository storage moves for a
# snippet. For example, moving a snippet to another gitaly node to help
# balance storage capacity.
module Snippets
  class RepositoryStorageMove < ApplicationRecord
    extend ::Gitlab::Utils::Override
    include RepositoryStorageMovable

    self.table_name = 'snippet_repository_storage_moves'

    belongs_to :container, class_name: 'Snippet', inverse_of: :repository_storage_moves, foreign_key: :snippet_id
    alias_attribute :snippet, :container
    alias_attribute :container_id, :snippet_id

    override :schedule_repository_storage_update_worker
    def schedule_repository_storage_update_worker
      Snippets::UpdateRepositoryStorageWorker.perform_async(id)
    end

    private

    override :error_key
    def error_key
      :snippet
    end
  end
end
