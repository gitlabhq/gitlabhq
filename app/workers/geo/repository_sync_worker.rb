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
      resources = find_project_ids_not_synced(batch_size: db_retrieve_batch_size)
      remaining_capacity = db_retrieve_batch_size - resources.size

      if remaining_capacity.zero?
        resources
      else
        resources + find_project_ids_updated_recently(batch_size: remaining_capacity)
      end
    end

    def find_project_ids_not_synced(batch_size:)
      healthy_shards_restriction(current_node.unsynced_projects)
        .reorder(last_repository_updated_at: :desc)
        .limit(batch_size)
        .pluck(:id)
    end

    def find_project_ids_updated_recently(batch_size:)
      current_node.project_registries
                  .dirty
                  .retry_due
                  .order(Gitlab::Database.nulls_first_order(:last_repository_synced_at, :desc))
                  .limit(batch_size)
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
