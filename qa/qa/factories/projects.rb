# frozen_string_literal: true

module QA
  FactoryBot.define do
    # https://docs.gitlab.com/ee/api/projects.html
    factory :project, class: 'QA::Resource::Project' do
      name { 'Project Name' }
      visibility { 'public' }

      trait :private do
        visibility { 'private' }
      end

      trait :with_readme do
        initialize_with_readme { true }
      end
    end
  end
end
