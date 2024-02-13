# frozen_string_literal: true

module QA
  FactoryBot.define do
    # https://docs.gitlab.com/ee/api/projects.html
    factory :project, class: 'QA::Resource::Project' do
      trait :private do
        visibility { 'private' }
      end

      trait :with_readme do
        initialize_with_readme { true }
      end

      trait :auto_devops do
        auto_devops_enabled { true }
      end
    end

    factory :fork, class: 'QA::Resource::Fork'
  end
end
