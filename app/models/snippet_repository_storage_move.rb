# frozen_string_literal: true

# SnippetRepositoryStorageMove are details of repository storage moves for a
# snippet. For example, moving a snippet to another gitaly node to help
# balance storage capacity.
class SnippetRepositoryStorageMove < ApplicationRecord
  extend ::Gitlab::Utils::Override
  include RepositoryStorageMovable

  belongs_to :container, class_name: 'Snippet', inverse_of: :repository_storage_moves, foreign_key: :snippet_id
  alias_attribute :snippet, :container

  override :schedule_repository_storage_update_worker
  def schedule_repository_storage_update_worker
    SnippetUpdateRepositoryStorageWorker.perform_async(
      snippet_id,
      destination_storage_name,
      id
    )
  end

  private

  override :error_key
  def error_key
    :snippet
  end
end
