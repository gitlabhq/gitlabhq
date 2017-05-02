module Ci
  class ExpirePipelineCacheService < BaseService
    include Gitlab::Routing.url_helpers

    attr_reader :pipeline

    def execute(pipeline)
      @pipeline = pipeline

      Gitlab::EtagCaching::Store.new.tap do |store|
        store.touch(project_pipeline_path)
        store.touch(project_pipelines_path)
        store.touch(commit_pipelines_path) if pipeline.commit
        store.touch(new_merge_request_pipelines_path)

        merge_requests_pipelines_paths.each { |path| store.touch(path) }
      end

      Gitlab::Cache::Ci::ProjectPipelineStatus.update_for_pipeline(pipeline)
    end

    private

    def project_pipelines_path
      namespace_project_pipelines_path(
        project.namespace,
        project,
        format: :json)
    end

    def commit_pipelines_path
      pipelines_namespace_project_commit_path(
        project.namespace,
        project,
        pipeline.commit.id,
        format: :json)
    end

    def new_merge_request_pipelines_path
      new_namespace_project_merge_request_path(
        project.namespace,
        project,
        format: :json)
    end

    def merge_requests_pipelines_paths
      pipeline.merge_requests.collect do |merge_request|
        pipelines_namespace_project_merge_request_path(
          project.namespace,
          project,
          merge_request,
          format: :json)
      end
    end

    def project_pipeline_path
      namespace_project_pipeline_path(
        project.namespace,
        project,
        pipeline,
        format: :json)
    end
  end
end
