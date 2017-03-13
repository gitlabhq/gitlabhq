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
      self.sha, self.status = Gitlab::Redis.with { |redis| redis.hmget(project_pipeline_status_key, :sha, :status) }
    end

    def store_in_cache
      Gitlab::Redis.with { |redis| redis.mapped_hmset(project_pipeline_status_key, { sha: sha, status: status }) }
    end

    def delete_from_cache
      Gitlab::Redis.with { |redis| redis.del(project_pipeline_status_key) }
    end

    def has_cache?
      Gitlab::Redis.with { |redis| redis.exists(project_pipeline_status_key) }
    end

    def loaded?
      self.loaded
    end

    def project_pipeline_status_key
      "projects/#{project.id}/build_status"
    end
  end
end
