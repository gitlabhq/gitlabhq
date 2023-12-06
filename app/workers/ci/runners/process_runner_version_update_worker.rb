# frozen_string_literal: true

module Ci
  module Runners
    class ProcessRunnerVersionUpdateWorker
      include ApplicationWorker

      data_consistency :always

      feature_category :fleet_visibility
      urgency :low

      idempotent!
      deduplicate :until_executing

      def perform(version)
        result = ::Ci::Runners::ProcessRunnerVersionUpdateService.new(version).execute

        result.to_h.slice(:status, :message, :upgrade_status).each do |key, value|
          log_extra_metadata_on_done(key, value)
        end
      end
    end
  end
end
