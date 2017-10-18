module Geo
  class RepositorySyncWorker < Geo::BaseSchedulerWorker
    private

    def max_capacity
      current_node.repos_max_capacity
    end

    def schedule_job(project_id)
      job_id = Geo::ProjectSyncWorker.perform_async(project_id, Time.now)

      { id: project_id, job_id: job_id } if job_id
    end

    def load_pending_resources
      project_ids_not_synced = find_project_ids_not_synced
      project_ids_updated_recently = find_project_ids_updated_recently

      interleave(project_ids_not_synced, project_ids_updated_recently)
    end

    def find_project_ids_not_synced
      healthy_shards_restriction(current_node.unsynced_projects)
        .reorder(last_repository_updated_at: :desc)
        .limit(db_retrieve_batch_size)
        .pluck(:id)
    end

    def find_project_ids_updated_recently
      current_node.project_registries
                  .dirty
                  .order(Gitlab::Database.nulls_first_order(:last_repository_synced_at, :desc))
                  .limit(db_retrieve_batch_size)
                  .pluck(:project_id)
    end

    def healthy_shards_restriction(relation)
      configured = Gitlab.config.repositories.storages.keys
      referenced = Project.distinct(:repository_storage).pluck(:repository_storage)
      healthy = healthy_shards

      known = configured | referenced
      return relation if (known - healthy).empty?

      relation.where(repository_storage: healthy)
    end

    def healthy_shards
      Gitlab::HealthChecks::FsShardsCheck
        .readiness
        .select(&:success)
        .map { |check| check.labels[:shard] }
        .compact
        .uniq
    end
  end
end
