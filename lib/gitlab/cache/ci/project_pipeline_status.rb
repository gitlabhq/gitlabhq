# This class is not backed by a table in the main database.
# It loads the latest Pipeline for the HEAD of a repository, and caches that
# in Redis.
module Gitlab
  module Cache
    module Ci
      class ProjectPipelineStatus
        attr_accessor :sha, :status, :ref, :project, :loaded

        delegate :commit, to: :project

        def self.load_for_project(project)
          new(project).tap do |status|
            status.load_status
          end
        end

        def self.update_for_pipeline(pipeline)
          new(pipeline.project,
              sha: pipeline.sha,
              status: pipeline.status,
              ref: pipeline.ref).store_in_cache_if_needed
        end

        def initialize(project, sha: nil, status: nil, ref: nil)
          @project = project
          @sha = sha
          @ref = ref
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
            load_from_project
            store_in_cache
          end

          self.loaded = true
        end

        def load_from_project
          return unless commit

          self.sha = commit.sha
          self.status = commit.status
          self.ref = project.default_branch
        end

        # We only cache the status for the HEAD commit of a project
        # This status is rendered in project lists
        def store_in_cache_if_needed
          return delete_from_cache unless commit
          return unless sha
          return unless ref

          if commit.sha == sha && project.default_branch == ref
            store_in_cache
          end
        end

        def load_from_cache
          Gitlab::Redis.with do |redis|
            self.sha, self.status, self.ref = redis.hmget(cache_key, :sha, :status, :ref)
          end
        end

        def store_in_cache
          Gitlab::Redis.with do |redis|
            redis.mapped_hmset(cache_key, { sha: sha, status: status, ref: ref })
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
  end
end
