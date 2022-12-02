# frozen_string_literal: true

# Service class for getting and caching the number of forks of several projects
# Warning: do not user this service with a really large set of projects
# because the service use maps to retrieve the project ids
module Projects
  class BatchForksCountService < Projects::BatchCountService
    # rubocop: disable CodeReuse/ActiveRecord
    def global_count
      @global_count ||= count_service.query(project_ids)
                     .group(:forked_from_project_id)
                     .count
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def count_service
      ::Projects::ForksCountService
    end
  end
end
