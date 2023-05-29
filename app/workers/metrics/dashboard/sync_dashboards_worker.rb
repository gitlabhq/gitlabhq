# frozen_string_literal: true

module Metrics
  module Dashboard
    class SyncDashboardsWorker
      include ApplicationWorker

      data_consistency :always

      sidekiq_options retry: 3

      feature_category :metrics

      idempotent!

      def perform(project_id); end
    end
  end
end
