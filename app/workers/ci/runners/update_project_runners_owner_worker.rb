# frozen_string_literal: true

module Ci
  module Runners
    class UpdateProjectRunnersOwnerWorker
      include Gitlab::EventStore::Subscriber

      data_consistency :sticky

      idempotent!

      feature_category :runner

      def handle_event(event)
        return unless feature_enabled?(event.data[:project_id])

        ::Ci::Runners::UpdateProjectRunnersOwnerService.new(event.data[:project_id]).execute
      end

      private

      def feature_enabled?(project_id)
        Feature.enabled?(:update_project_runners_owner, Project.actor_from_id(project_id))
      end
    end
  end
end
