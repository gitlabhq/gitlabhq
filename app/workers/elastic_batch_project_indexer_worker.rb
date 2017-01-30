class ElasticBatchProjectIndexerWorker
  include Sidekiq::Worker
  include Gitlab::CurrentSettings

  sidekiq_options queue: :elasticsearch, retry: 2

  def perform(start, finish, update_index = false)
    projects = build_relation(start, finish, update_index)
    indexer = Gitlab::Elastic::Indexer.new

    projects.find_each do |project|
      repository = project.repository
      next unless repository.exists? && !repository.empty?

      begin
        logger.info "Indexing #{project.name_with_namespace} (ID=#{project.id})..."

        index_status = project.index_status || project.build_index_status
        head_commit = repository.commit

        if !head_commit || index_status.last_commit == head_commit.sha
          logger.info("Skipped".color(:yellow))
          next
        end

        indexer.run(
          project.id,
          repository.path_to_repo,
          index_status.last_commit
        )

        # During indexing the new commits can be pushed,
        # the last_commit parameter only indicates that at least this commit is in index
        index_status.last_commit = head_commit.sha
        index_status.indexed_at = DateTime.now
        index_status.save

        logger.info("Done!".color(:green))
      rescue => err
        logger.warn("#{err.message}, trace - #{err.backtrace}")
      end
    end
  end

  def build_relation(start, finish, update_index)
    relation = Project.includes(:index_status)

    if update_index
      relation = relation.where('index_statuses.id IS NULL').references(:index_statuses)
    end

    table = Project.arel_table
    relation = relation.where(table[:id].gteq(start)) if start
    relation = relation.where(table[:id].lteq(finish)) if finish

    relation
  end
end
