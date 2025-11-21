# frozen_string_literal: true

FactoryBot.define do
  factory :dashboard, class: "Analytics::CustomDashboards::Dashboard" do
    name { "Test Dashboard" }
    description { "Example dashboard" }

    config do
      {
        version: "2",
        title: "Sample Dashboard",
        description: "Demo dashboard",
        panels: [
          {
            title: "Sales Panel",
            visualization: "number",
            gridAttributes: {
              width: 4,
              height: 2,
              xPos: 0,
              yPos: 0
            }
          }
        ]
      }
    end

    association :created_by, factory: :user
    namespace
    organization { namespace&.organization || assocation(:common_organization) }
  end
end
