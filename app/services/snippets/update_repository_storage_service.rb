# frozen_string_literal: true

module Snippets
  class UpdateRepositoryStorageService
    include UpdateRepositoryStorageMethods

    delegate :snippet, to: :repository_storage_move

    private

    def track_repository(destination_storage_name)
      snippet.track_snippet_repository(destination_storage_name)
    end

    def mirror_repositories
      return unless snippet.repository_exists?

      mirror_repository(type: Gitlab::GlRepository::SNIPPET)
    end
  end
end
