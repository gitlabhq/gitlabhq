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
    end
  end
end
