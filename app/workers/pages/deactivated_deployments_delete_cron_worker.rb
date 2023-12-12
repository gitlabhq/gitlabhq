# frozen_string_literal: true

module Pages
  class DeactivatedDeploymentsDeleteCronWorker
    include ApplicationWorker
    include CronjobQueue # rubocop: disable Scalability/CronWorkerContext

    idempotent!
    data_consistency :always # rubocop: disable SidekiqLoadBalancing/WorkerDataConsistency

    feature_category :pages

    def perform
      PagesDeployment.deactivated.each_batch do |deployments|
        deployments.each { |deployment| deployment.file.remove! }
        deployments.delete_all
      end
    end
  end
end
