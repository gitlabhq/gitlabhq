# frozen_string_literal: true

FactoryBot.define do
  factory :topic, class: 'Projects::Topic' do
    name { generate(:name) }
    title { generate(:title) }
    organization { association(:organization) }

    trait :with_avatar do
      avatar { fixture_file_upload('spec/fixtures/dk.png') }
    end
  end
end
