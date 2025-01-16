# frozen_string_literal: true

module Ci
  module Runners
    class UpdateProjectRunnersOwnerWorker
      include Gitlab::EventStore::Subscriber

      data_consistency :sticky

      idempotent!

      feature_category :runner

      def handle_event(event)
        ::Ci::Runners::UpdateProjectRunnersOwnerService.new(event.data[:project_id]).execute
      end
    end
  end
end
