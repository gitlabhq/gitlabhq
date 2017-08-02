module Geo
  class RepositorySyncWorker < Geo::BaseSchedulerWorker
    BACKOFF_DELAY = 5.minutes
    MAX_CAPACITY = 25

    private

    def max_capacity
      MAX_CAPACITY
    end

    def schedule_job(project_id)
      job_id = Geo::ProjectSyncWorker.perform_in(BACKOFF_DELAY, project_id, Time.now)

      { id: project_id, job_id: job_id } if job_id
    end

    def load_pending_resources
      project_ids_not_synced = find_project_ids_not_synced
      project_ids_updated_recently = find_project_ids_updated_recently

      interleave(project_ids_not_synced, project_ids_updated_recently)
    end

    def find_project_ids_not_synced
      Project.where.not(id: Geo::ProjectRegistry.synced.pluck(:project_id))
             .order(last_repository_updated_at: :desc)
             .limit(db_retrieve_batch_size)
             .pluck(:id)
    end

    def find_project_ids_updated_recently
      Geo::ProjectRegistry.dirty
                          .order(Gitlab::Database.nulls_first_order(:last_repository_synced_at, :desc))
                          .limit(db_retrieve_batch_size)
                          .pluck(:project_id)
    end
  end
end
