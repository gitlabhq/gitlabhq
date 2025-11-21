# frozen_string_literal: true

FactoryBot.define do
  factory :dashboard_version, class: 'Analytics::CustomDashboards::DashboardVersion' do
    association :dashboard, factory: :dashboard
    association :updated_by, factory: :user
    organization { dashboard.organization }
    version_number { 1 }

    config do
      {
        version: "2",
        title: "Version Config",
        panels: [
          {
            title: "Panel",
            visualization: "number",
            gridAttributes: { width: 4, height: 2 }
          }
        ]
      }
    end
  end
end
