# frozen_string_literal: true

module QA
  FactoryBot.define do
    # https://docs.gitlab.com/ee/api/issues.html
    factory :issue, class: 'QA::Resource::Issue' do
      title { Faker::Lorem.sentence }
      description { Faker::Lorem.paragraph }

      confidential { false }

      trait :confidential do
        confidential { true }
      end

      trait :incident do
        issue_type { 'incident' }
      end

      factory :incident, traits: [:incident]
    end
  end
end
