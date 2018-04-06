class ElasticBatchProjectIndexerWorker
  include ApplicationWorker

  # Batch indexing is a generally a onetime option, so give finer control over
  # queuing and concurrency

  # This worker is long-running, but idempotent, so retry many times if
  # necessary
  sidekiq_options retry: 10

  def perform(start, finish, update_index = false)
    projects = build_relation(start, finish, update_index)

    projects.find_each { |project| run_indexer(project) }
  end

  private

  def run_indexer(project)
    logger.info "Indexing #{project.full_name} (ID=#{project.id})..."

    last_commit = project.index_status.try(:last_commit)
    Gitlab::Elastic::Indexer.new(project).run(last_commit)

    logger.info "Indexing #{project.full_name} (ID=#{project.id}) is done!"
  rescue => err
    logger.warn("#{err.message} indexing #{project.full_name} (ID=#{project.id}), trace - #{err.backtrace}")
  end

  def build_relation(start, finish, update_index)
    relation = Project.includes(:index_status)

    unless update_index
      relation = relation.where('index_statuses.id IS NULL').references(:index_statuses)
    end

    table = Project.arel_table
    relation = relation.where(table[:id].gteq(start)) if start
    relation = relation.where(table[:id].lteq(finish)) if finish

    relation
  end
end
