# frozen_string_literal: true

FactoryBot.define do
  factory :achievement, class: 'Achievements::Achievement' do
    namespace

    name { generate(:name) }

    trait :with_avatar do
      avatar { fixture_file_upload('spec/fixtures/dk.png') }
    end
  end
end
