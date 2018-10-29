# frozen_string_literal: true

module Boards
  module Visits
    class LatestService < Boards::BaseService
      def execute
        return nil unless current_user

        if parent.is_a?(Group)
          BoardGroupRecentVisit.latest(current_user, parent)
        else
          BoardProjectRecentVisit.latest(current_user, parent)
        end
      end
    end
  end
end
