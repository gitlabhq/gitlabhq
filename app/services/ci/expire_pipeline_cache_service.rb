# frozen_string_literal: true

module Ci
  class ExpirePipelineCacheService
    def execute(pipeline, delete: false)
      store = Gitlab::EtagCaching::Store.new

      update_etag_cache(pipeline, store)

      if delete
        Gitlab::Cache::Ci::ProjectPipelineStatus.new(pipeline.project).delete_from_cache
      else
        Gitlab::Cache::Ci::ProjectPipelineStatus.update_for_pipeline(pipeline)
      end
    end

    private

    def project_pipelines_path(project)
      Gitlab::Routing.url_helpers.project_pipelines_path(project, format: :json)
    end

    def project_pipeline_path(project, pipeline)
      Gitlab::Routing.url_helpers.project_pipeline_path(project, pipeline, format: :json)
    end

    def commit_pipelines_path(project, commit)
      Gitlab::Routing.url_helpers.pipelines_project_commit_path(project, commit.id, format: :json)
    end

    def new_merge_request_pipelines_path(project)
      Gitlab::Routing.url_helpers.project_new_merge_request_path(project, format: :json)
    end

    def each_pipelines_merge_request_path(pipeline)
      pipeline.all_merge_requests.each do |merge_request|
        path = Gitlab::Routing.url_helpers.pipelines_project_merge_request_path(merge_request.target_project, merge_request, format: :json)

        yield(path)
      end
    end

    # Updates ETag caches of a pipeline.
    #
    # This logic resides in a separate method so that EE can more easily extend
    # it.
    #
    # @param [Ci::Pipeline] pipeline
    # @param [Gitlab::EtagCaching::Store] store
    def update_etag_cache(pipeline, store)
      project = pipeline.project

      store.touch(project_pipelines_path(project))
      store.touch(project_pipeline_path(project, pipeline))
      store.touch(commit_pipelines_path(project, pipeline.commit)) unless pipeline.commit.nil?
      store.touch(new_merge_request_pipelines_path(project))
      each_pipelines_merge_request_path(pipeline) do |path|
        store.touch(path)
      end
    end
  end
end
