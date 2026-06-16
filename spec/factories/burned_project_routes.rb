# frozen_string_literal: true

FactoryBot.define do
  factory :burned_project_route, class: 'Authn::BurnedProjectRoute' do
    organization
    sequence(:path) { |n| "group-#{n}/project-#{n}" }
    sequence(:project_id) { |n| n }
    burned_at { Time.current }

    trait :owned_by_project do
      transient do
        project { association(:project) }
      end

      organization { project.organization }
      path { project.full_path }
      project_id { project.id }
    end
  end
end
