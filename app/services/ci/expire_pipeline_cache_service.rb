module Ci
  class ExpirePipelineCacheService < BaseService
    def execute(pipeline)
      @pipeline = pipeline

      Gitlab::EtagCaching::Store.new.touch(project_pipelines_path)
    end

    private

    def project_pipelines_path
      Gitlab::Routing.url_helpers.namespace_project_pipelines_path(
        project.namespace,
        project,
        format: :json)
    end
  end
end
