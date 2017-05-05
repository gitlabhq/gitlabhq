class ExpirePipelineCacheWorker
  include Sidekiq::Worker
  include PipelineQueue

  def perform(pipeline_id)
    pipeline = Ci::Pipeline.find_by(id: pipeline_id)
    return unless pipeline

    project = pipeline.project
    store = Gitlab::EtagCaching::Store.new

    store.touch(project_pipelines_path(project))
    store.touch(commit_pipelines_path(project, pipeline.commit)) if pipeline.commit
    store.touch(new_merge_request_pipelines_path(project))
    each_pipelines_merge_request_path(project, pipeline) do |path|
      store.touch(path)
    end

    Gitlab::Cache::Ci::ProjectPipelineStatus.update_for_pipeline(pipeline)
  end

  private

  def project_pipelines_path(project)
    Gitlab::Routing.url_helpers.namespace_project_pipelines_path(
      project.namespace,
      project,
      format: :json)
  end

  def commit_pipelines_path(project, commit)
    Gitlab::Routing.url_helpers.pipelines_namespace_project_commit_path(
      project.namespace,
      project,
      commit.id,
      format: :json)
  end

  def new_merge_request_pipelines_path(project)
    Gitlab::Routing.url_helpers.new_namespace_project_merge_request_path(
      project.namespace,
      project,
      format: :json)
  end

  def each_pipelines_merge_request_path(project, pipeline)
    pipeline.all_merge_requests.each do |merge_request|
      path = Gitlab::Routing.url_helpers.pipelines_namespace_project_merge_request_path(
        project.namespace,
        project,
        merge_request,
        format: :json)

      yield(path)
    end
  end
end
