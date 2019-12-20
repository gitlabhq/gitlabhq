# frozen_string_literal: true

FactoryBot.define do
  factory :release do
    tag { "v1.1.0" }
    sha { 'b83d6e391c22777fca1ed3012fce84f633d7fed0' }
    name { tag }
    description { "Awesome release" }
    project
    author
    released_at { Time.zone.parse('2018-10-20T18:00:00Z') }

    trait :legacy do
      sha { nil }
      author { nil }
    end

    trait :with_evidence do
      after(:create) do |release, _|
        create(:evidence, release: release)
      end
    end
  end
end
