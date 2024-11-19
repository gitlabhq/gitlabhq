# frozen_string_literal: true

module Pages
  class DeactivatedDeploymentsDeleteCronWorker
    include ApplicationWorker
    include CronjobQueue # rubocop: disable Scalability/CronWorkerContext

    idempotent!
    data_consistency :always

    feature_category :pages

    def perform
      PagesDeployment.deactivated.each_batch do |deployments|
        deployments.each(&:destroy!)
      end
    end
  end
end
