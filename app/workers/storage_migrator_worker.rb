class StorageMigratorWorker
  include ApplicationWorker

  BATCH_SIZE = 100

  def perform(start, finish)
    projects = build_relation(start, finish)

    projects.with_route.find_each(batch_size: BATCH_SIZE) do |project|
      Rails.logger.info "Starting storage migration of #{project.full_path} (ID=#{project.id})..."

      begin
        project.migrate_to_hashed_storage!
      rescue => err
        Rails.logger.error("#{err.message} migrating storage of #{project.full_path} (ID=#{project.id}), trace - #{err.backtrace}")
      end
    end
  end

  def build_relation(start, finish)
    relation = Project
    table = Project.arel_table

    relation = relation.where(table[:id].gteq(start)) if start
    relation = relation.where(table[:id].lteq(finish)) if finish

    relation
  end
end
