# frozen_string_literal: true

module Snippets
  # Tries to schedule a move for every snippet with repositories on the source shard
  class ScheduleBulkRepositoryShardMovesService
    include ScheduleBulkRepositoryShardMovesMethods
    extend ::Gitlab::Utils::Override

    private

    override :repository_klass
    def repository_klass
      SnippetRepository
    end

    override :container_klass
    def container_klass
      Snippet
    end

    override :container_column
    def container_column
      :snippet_id
    end

    override :schedule_bulk_worker_klass
    def self.schedule_bulk_worker_klass
      ::Snippets::ScheduleBulkRepositoryShardMovesWorker
    end
  end
end
