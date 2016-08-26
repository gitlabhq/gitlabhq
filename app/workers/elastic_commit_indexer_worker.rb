class ElasticCommitIndexerWorker
  include Sidekiq::Worker
  include Gitlab::CurrentSettings

  sidekiq_options queue: :elasticsearch, retry: 2

  def perform(project_id, oldrev = nil, newrev = nil)
    return true unless current_application_settings.elasticsearch_indexing?

    project = Project.find(project_id)
    repository = project.repository

    return true unless repository.head_exists?

    indexer = Gitlab::Elastic::Indexer.new
    indexer.run(
      project_id,
      repository.path_to_repo,
      oldrev,
      newrev
    )
  end
end
