# This class is not backed by a table in the main database.
# It loads the latest Pipeline for the HEAD of a repository, and caches that
# in Redis.
module Ci
  class PipelineStatus
    attr_accessor :sha, :status, :project, :loaded

    delegate :commit, to: :project

    def self.load_for_project(project)
      new(project).tap do |status|
        status.load_status
      end
    end

    def initialize(project, sha: nil, status: nil)
      @project = project
      @sha = sha
      @status = status
    end

    def has_status?
      loaded? && sha.present? && status.present?
    end

    def load_status
      return if loaded?

      if has_cache?
        load_from_cache
      else
        load_from_commit
        store_in_cache
      end

      self.loaded = true
    end

    def load_from_commit
      return unless commit

      self.sha = commit.sha
      self.status = commit.status
    end

    # We only cache the status for the HEAD commit of a project
    # This status is rendered in project lists
    def store_in_cache_if_needed
      return unless sha
      return delete_from_cache unless commit
      store_in_cache if commit.sha == self.sha
    end

    def load_from_cache
      Gitlab::Redis.with do |redis|
        self.sha, self.status = redis.hmget(cache_key, :sha, :status)
      end
    end

    def store_in_cache
      Gitlab::Redis.with do |redis|
        redis.mapped_hmset(cache_key, { sha: sha, status: status })
      end
    end

    def delete_from_cache
      Gitlab::Redis.with do |redis|
        redis.del(cache_key)
      end
    end

    def has_cache?
      Gitlab::Redis.with do |redis|
        redis.exists(cache_key)
      end
    end

    def loaded?
      self.loaded
    end

    def cache_key
      "projects/#{project.id}/build_status"
    end
  end
end
