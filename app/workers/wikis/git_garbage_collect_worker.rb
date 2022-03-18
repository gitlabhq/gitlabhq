# frozen_string_literal: true

module Wikis
  class GitGarbageCollectWorker # rubocop:disable Scalability/IdempotentWorker
    extend ::Gitlab::Utils::Override
    include GitGarbageCollectMethods

    private

    # Used for getting a project/group out of the resource in order to scope a feature flag
    # Can be removed within https://gitlab.com/gitlab-org/gitlab/-/issues/353607
    def container(resource)
      resource.container
    end

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
