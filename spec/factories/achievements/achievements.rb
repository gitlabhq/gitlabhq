# frozen_string_literal: true

FactoryBot.define do
  factory :achievement, class: 'Achievements::Achievement' do
    namespace

    name { generate(:name) }
  end
end
