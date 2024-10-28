# frozen_string_literal: true

module Pages
  class DeactivateExpiredDeploymentsCronWorker
    include ApplicationWorker
    include CronjobQueue # rubocop: disable Scalability/CronWorkerContext -- No relevant metadata

    idempotent!
    data_consistency :always

    feature_category :pages

    def perform
      scope = PagesDeployment.expired

      iterator = Gitlab::Pagination::Keyset::Iterator.new(scope: scope)

      iterator.each_batch do |deployments|
        deployments.each(&:deactivate)
      end
    end
  end
end
