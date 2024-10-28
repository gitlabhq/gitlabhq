# frozen_string_literal: true

module Pages
  class DeactivateMrDeploymentsWorker
    include ApplicationWorker

    idempotent!
    data_consistency :always
    urgency :low

    feature_category :pages

    def perform(merge_request_id)
      build_ids = Ci::Build.ids_in_merge_request(merge_request_id)
      deactivate_deployments_with_build_ids(build_ids)
    end

    private

    def deactivate_deployments_with_build_ids(build_ids)
      PagesDeployment
        .versioned
        .ci_build_id_in(build_ids)
        .each_batch do |batch|
          batch.deactivate
        end
    end
  end
end
