class ElasticCommitIndexerWorker
  include Sidekiq::Worker

  sidekiq_options queue: :elasticsearch

  def perform(project_id, oldrev, newrev)
    project = Project.find(project_id)

    indexer = Gitlab::Elastic::Indexer.new
    indexer.run(
      project_id,
      project.repository.path_to_repo,
      oldrev,
      newrev
    )
  end
end
