# frozen_string_literal: true

module Snippets
  class UpdateRepositoryStorageWorker # rubocop:disable Scalability/IdempotentWorker
    extend ::Gitlab::Utils::Override
    include ::UpdateRepositoryStorageWorker

    sidekiq_options retry: 3

    private

    override :find_repository_storage_move
    def find_repository_storage_move(repository_storage_move_id)
      Snippets::RepositoryStorageMove.find(repository_storage_move_id)
    end

    override :update_repository_storage
    def update_repository_storage(repository_storage_move)
      ::Snippets::UpdateRepositoryStorageService.new(repository_storage_move).execute
    end
  end
end
