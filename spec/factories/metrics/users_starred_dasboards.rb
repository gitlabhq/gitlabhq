# frozen_string_literal: true

FactoryBot.define do
  factory :metrics_users_starred_dashboard, class: '::Metrics::UsersStarredDashboard' do
    dashboard_path { "custom_dashboard.yml" }
    user
    project
  end
end
