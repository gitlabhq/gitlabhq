class ExpirePipelineCacheWorker
  include ApplicationWorker
  include PipelineQueue

  queue_namespace :pipeline_cache

  def perform(pipeline_id)
    pipeline = Ci::Pipeline.find_by(id: pipeline_id)
    return unless pipeline

    project = pipeline.project
    store = Gitlab::EtagCaching::Store.new

    store.touch(project_pipelines_path(project))
    store.touch(project_pipeline_path(project, pipeline))
    store.touch(commit_pipelines_path(project, pipeline.commit)) unless pipeline.commit.nil?
    store.touch(new_merge_request_pipelines_path(project))
    each_pipelines_merge_request_path(project, pipeline) do |path|
      store.touch(path)
    end

    Gitlab::Cache::Ci::ProjectPipelineStatus.update_for_pipeline(pipeline)
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

  def each_pipelines_merge_request_path(project, pipeline)
    pipeline.all_merge_requests.each do |merge_request|
      path = Gitlab::Routing.url_helpers.pipelines_project_merge_request_path(project, merge_request, format: :json)

      yield(path)
    end
  end
end
