# frozen_string_literal: true

FactoryBot.define do
  factory :ci_runtime_environment, class: 'Ci::RuntimeEnvironment' do
    project
    sequence(:environment_key) { |n| "#{n}/s_#{SecureRandom.hex(4)}/executor-data" }
  end
end
