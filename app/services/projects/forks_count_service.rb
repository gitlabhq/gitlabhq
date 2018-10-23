# frozen_string_literal: true

module Projects
  # Service class for getting and caching the number of forks of a project.
  class ForksCountService < Projects::CountService
    def cache_key_name
      'forks_count'
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def self.query(project_ids)
      ForkNetworkMember.where(forked_from_project: project_ids)
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
