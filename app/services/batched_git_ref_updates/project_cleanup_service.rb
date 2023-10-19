# frozen_string_literal: true

module BatchedGitRefUpdates
  class ProjectCleanupService
    include ::Gitlab::ExclusiveLeaseHelpers

    LOCK_TIMEOUT = 10.minutes
    GITALY_BATCH_SIZE = 100
    QUERY_BATCH_SIZE = 1000
    MAX_DELETES = 10_000

    def initialize(project_id)
      @project_id = project_id
    end

    def execute
      total_deletes = 0

      in_lock("#{self.class}/#{@project_id}", retries: 0, ttl: LOCK_TIMEOUT) do
        project = Project.find_by_id(@project_id)
        break unless project

        Deletion
          .status_pending
          .for_project(@project_id)
          .select_ref_and_identity
          .each_batch(of: QUERY_BATCH_SIZE) do |batch|
          refs = batch.map(&:ref)

          refs.each_slice(GITALY_BATCH_SIZE) do |refs_to_delete|
            project.repository.delete_refs(*refs_to_delete.uniq)
          end

          total_deletes += refs.count
          Deletion.mark_records_processed(batch)

          break if total_deletes >= MAX_DELETES
        end
      end

      { total_deletes: total_deletes }
    end
  end
end
