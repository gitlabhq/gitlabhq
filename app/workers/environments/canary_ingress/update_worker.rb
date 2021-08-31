# frozen_string_literal: true

module Environments
  module CanaryIngress
    class UpdateWorker
      include ApplicationWorker

      data_consistency :always

      sidekiq_options retry: false
      idempotent!
      worker_has_external_dependencies!
      feature_category :continuous_delivery

      def perform(environment_id, params)
        Environment.find_by_id(environment_id).try do |environment|
          Environments::CanaryIngress::UpdateService
            .new(environment.project, nil, params.with_indifferent_access)
            .execute(environment)
        end
      end
    end
  end
end
