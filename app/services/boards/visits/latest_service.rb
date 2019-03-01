# frozen_string_literal: true

module Boards
  module Visits
    class LatestService < Boards::BaseService
      def execute
        return nil unless current_user

        recent_visit_model.latest(current_user, parent, count: params[:count])
      end

      private

      def recent_visit_model
        parent.is_a?(Group) ? BoardGroupRecentVisit : BoardProjectRecentVisit
      end
    end
  end
end
