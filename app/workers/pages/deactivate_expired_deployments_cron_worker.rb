# frozen_string_literal: true

module Pages
  class DeactivateExpiredDeploymentsCronWorker
    include ApplicationWorker
    include CronjobQueue # rubocop: disable Scalability/CronWorkerContext -- No relevant metadata

    idempotent!
    data_consistency :always

    feature_category :pages

    MAX_NUM_DELETIONS = 10000
    BATCH_SIZE = 1000

    def perform
      scope = PagesDeployment.active.expired

      iterator = Gitlab::Pagination::Keyset::Iterator.new(scope: scope)
      count = 0
      start = Time.current

      iterator.each_batch(of: BATCH_SIZE) do |deployments|
        deployments.each(&:deactivate)
        count += deployments.length

        break if count >= MAX_NUM_DELETIONS
      end

      log_extra_metadata_on_done(:deactivate_expired_pages_deployments, {
        deactivated_deployments: count,
        duration: Time.current - start
      })
    end
  end
end
