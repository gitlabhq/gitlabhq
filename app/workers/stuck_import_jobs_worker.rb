class StuckImportJobsWorker
  include Sidekiq::Worker
  include CronjobQueue

  IMPORT_EXPIRATION = 15.hours.to_i

  def perform
    stuck_projects.find_in_batches(batch_size: 500) do |group|
      jids = group.map(&:import_jid)

      # Find the jobs that aren't currently running or that exceeded the threshold.
      completed_jids = Gitlab::SidekiqStatus.completed_jids(jids)

      if completed_jids.any?
        completed_ids = group.select { |project| completed_jids.include?(project.import_jid) }.map(&:id)

        fail_batch!(completed_jids, completed_ids)
      end
    end
  end

  private

  def stuck_projects
    Project.select('id, import_jid').with_import_status(:started).where.not(import_jid: nil)
  end

  def fail_batch!(completed_jids, completed_ids)
    Project.where(id: completed_ids).update_all(import_status: 'failed', import_error: error_message)

    Rails.logger.info("Marked stuck import jobs as failed. JIDs: #{completed_jids.join(', ')}")
  end

  def error_message
    "Import timed out. Import took longer than #{IMPORT_EXPIRATION} seconds"
  end
end
