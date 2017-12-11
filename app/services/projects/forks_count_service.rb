module Projects
  # Service class for getting and caching the number of forks of a project.
  class ForksCountService < Projects::CountService
    def cache_key_name
      'forks_count'
    end

    def self.query(project_ids)
      # We can't directly change ForkedProjectLink to ForkNetworkMember here
      # Nowadays, when a call using v3 to projects/:id/fork is made,
      # the relationship to ForkNetworkMember is not updated
      ForkedProjectLink.where(forked_from_project: project_ids)
    end
  end
end
