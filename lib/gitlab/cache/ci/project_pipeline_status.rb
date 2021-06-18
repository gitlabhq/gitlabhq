# frozen_string_literal: true

# This class is not backed by a table in the main database.
# It loads the latest Pipeline for the HEAD of a repository, and caches that
# in Redis.
module Gitlab
  module Cache
    module Ci
      class ProjectPipelineStatus
        include Gitlab::Utils::StrongMemoize

        attr_accessor :sha, :status, :ref, :project, :loaded

        def self.load_for_project(project)
          new(project).tap do |status|
            status.load_status
          end
        end

        def self.load_in_batch_for_projects(projects)
          projects.each do |project|
            project.pipeline_status = new(project)
            project.pipeline_status.load_status
          end
        end

        def self.update_for_pipeline(pipeline)
          pipeline_info = {
            sha: pipeline.sha,
            status: pipeline.status,
            ref: pipeline.ref
          }

          new(pipeline.project, pipeline_info: pipeline_info)
            .store_in_cache_if_needed
        end

        def initialize(project, pipeline_info: {}, loaded_from_cache: nil)
          @project = project
          @sha = pipeline_info[:sha]
          @ref = pipeline_info[:ref]
          @status = pipeline_info[:status]
          @loaded = loaded_from_cache
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
        rescue GRPC::Unavailable, GRPC::DeadlineExceeded => e
          # Handle Gitaly connection issues gracefully
          Gitlab::ErrorTracking
            .track_exception(e, project_id: project.id)
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
          Gitlab::Redis::Cache.with do |redis|
            self.sha, self.status, self.ref = redis.hmget(cache_key, :sha, :status, :ref)

            self.status = nil if self.status.empty?
          end
        end

        def store_in_cache
          Gitlab::Redis::Cache.with do |redis|
            redis.mapped_hmset(cache_key, { sha: sha, status: status, ref: ref })
          end
        end

        def delete_from_cache
          Gitlab::Redis::Cache.with do |redis|
            redis.del(cache_key)
          end
        end

        def has_cache?
          return self.loaded unless self.loaded.nil?

          Gitlab::Redis::Cache.with do |redis|
            redis.exists(cache_key)
          end
        end

        def loaded?
          self.loaded
        end

        def cache_key
          "#{Gitlab::Redis::Cache::CACHE_NAMESPACE}:project:#{project.id}:pipeline_status"
        end

        def commit
          strong_memoize(:commit) do
            project.commit
          end
        end
      end
    end
  end
end
