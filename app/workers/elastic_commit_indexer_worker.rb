class ElasticCommitIndexerWorker
  include Sidekiq::Worker

  sidekiq_options queue: :elasticsearch

  def perform(project_id, oldrev = nil, newrev = nil)
    project = Project.find(project_id)
    repository = project.repository

    return true unless repository.exists? && !repository.empty?

    indexer = Gitlab::Elastic::Indexer.new
    indexer.run(
      project_id,
      repository.path_to_repo,
      oldrev,
      newrev
    )
  end
end
