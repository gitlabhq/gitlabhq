# frozen_string_literal: true

module Metrics
  class UsersStarredDashboard < ApplicationRecord
    self.table_name = 'metrics_users_starred_dashboards'

    belongs_to :user, inverse_of: :metrics_users_starred_dashboards
    belongs_to :project, inverse_of: :metrics_users_starred_dashboards

    validates :user_id, presence: true
    validates :project_id, presence: true
    validates :dashboard_path, presence: true, length: { maximum: 255 }
    validates :dashboard_path, uniqueness: { scope: %i[user_id project_id] }
  end
end
