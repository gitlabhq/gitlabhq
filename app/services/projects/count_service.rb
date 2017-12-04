module Projects
  # Base class for the various service classes that count project data (e.g.
  # issues or forks).
  class CountService < BaseCountService
    # The version of the cache format. This should be bumped whenever the
    # underlying logic changes. This removes the need for explicitly flushing
    # all caches.
    VERSION = 1

    def initialize(project)
      @project = project
    end

    def relation_for_count
      self.class.query(@project.id)
    end

    def cache_key_name
      raise(
        NotImplementedError,
        '"cache_key_name" must be implemented and return a String'
      )
    end

    def cache_key
      ['projects', 'count_service', VERSION, @project.id, cache_key_name]
    end

    def self.query(project_ids)
      raise(
        NotImplementedError,
        '"query" must be implemented and return an ActiveRecord::Relation'
      )
    end
  end
end
