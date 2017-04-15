module Ci
  class ExpirePipelineCacheService < BaseService
    attr_reader :pipeline

    def execute(pipeline)
      @pipeline = pipeline
      store = Gitlab::EtagCaching::Store.new

      store.touch(project_pipelines_path)
      store.touch(commit_pipelines_path) if pipeline.commit
      store.touch(new_merge_request_pipelines_path)
      merge_requests_pipelines_paths.each { |path| store.touch(path) }

      Gitlab::Cache::Ci::ProjectPipelineStatus.update_for_pipeline(@pipeline)
    end

    private

    def project_pipelines_path
      Gitlab::Routing.url_helpers.namespace_project_pipelines_path(
        project.namespace,
        project,
        format: :json)
    end

    def commit_pipelines_path
      Gitlab::Routing.url_helpers.pipelines_namespace_project_commit_path(
        project.namespace,
        project,
        pipeline.commit.id,
        format: :json)
    end

    def new_merge_request_pipelines_path
      Gitlab::Routing.url_helpers.new_namespace_project_merge_request_path(
        project.namespace,
        project,
        format: :json)
    end

    def merge_requests_pipelines_paths
      pipeline.merge_requests.collect do |merge_request|
        Gitlab::Routing.url_helpers.pipelines_namespace_project_merge_request_path(
          project.namespace,
          project,
          merge_request,
          format: :json)
      end
    end
  end
end
