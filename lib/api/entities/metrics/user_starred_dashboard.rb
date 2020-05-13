# frozen_string_literal: true

module API
  module Entities
    module Metrics
      class UserStarredDashboard < Grape::Entity
        expose :id, :dashboard_path, :user_id, :project_id
      end
    end
  end
end
