# frozen_string_literal: true

module Wikis
  class GitGarbageCollectWorker # rubocop:disable Scalability/IdempotentWorker
    extend ::Gitlab::Utils::Override
    include GitGarbageCollectMethods

    tags :exclude_from_kubernetes

    private

    override :find_resource
    def find_resource(id)
      Project.find(id).wiki
    end

    override :update_db_repository_statistics
    def update_db_repository_statistics(resource)
      Projects::UpdateStatisticsService.new(resource.container, nil, statistics: [:wiki_size]).execute
    end
  end
end
