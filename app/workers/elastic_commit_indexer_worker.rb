class ElasticCommitIndexerWorker
  include Sidekiq::Worker
  include Gitlab::CurrentSettings

  sidekiq_options queue: :elasticsearch, retry: 2

  def perform(project_id, oldrev = nil, newrev = nil)
    return true unless current_application_settings.elasticsearch_indexing?

    project = Project.find(project_id)

    Gitlab::Elastic::Indexer.new(project).run(oldrev, newrev)
  end
end
