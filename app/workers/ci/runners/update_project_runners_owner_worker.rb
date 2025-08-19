# frozen_string_literal: true

module Ci
  module Runners
    class UpdateProjectRunnersOwnerWorker
      include ApplicationWorker

      loggable_arguments 0, 1
      data_consistency :sticky

      idempotent!

      feature_category :runner

      def handle_event(_event)
        # TODO: This worker has been made no-op as part of deprecation.
        # Remove this worker class in a future release following the
        # Sidekiq compatibility guidelines.
      end
    end
  end
end
