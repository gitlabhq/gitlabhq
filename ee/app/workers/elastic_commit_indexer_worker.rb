class ElasticCommitIndexerWorker
  include ApplicationWorker

  sidekiq_options retry: 2

  def perform(project_id, oldrev = nil, newrev = nil)
    return true unless Gitlab::CurrentSettings.elasticsearch_indexing?

    project = Project.find(project_id)

    Gitlab::Elastic::Indexer.new(project).run(oldrev, newrev)
  end
end
