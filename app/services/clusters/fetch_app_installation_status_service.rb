module Clusters
  class FetchAppInstallationStatusService < BaseHelmService
    def execute
      return unless app.installing?

      phase = helm.installation_status(app)
      log = helm.installation_log(app) if phase == 'Failed'
      yield(phase, log) if block_given?
    rescue KubeException => ke
      app.make_errored!("Kubernetes error: #{ke.message}") unless app.errored?
    end
  end
end
