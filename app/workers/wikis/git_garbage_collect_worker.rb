# frozen_string_literal: true

module Wikis
  class GitGarbageCollectWorker # rubocop:disable Scalability/IdempotentWorker
    extend ::Gitlab::Utils::Override
    include GitGarbageCollectMethods

    private

    override :find_resource
    def find_resource(id)
      Project.find(id).wiki
    end

    override :update_db_repository_statistics
    def update_db_repository_statistics(resource, stats)
      Projects::UpdateStatisticsService.new(resource.container, nil, statistics: stats).execute
    end

    def stats
      [:wiki_size]
    end
  end
end
