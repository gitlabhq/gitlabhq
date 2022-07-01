# frozen_string_literal: true

FactoryBot.define do
  factory :ci_runner_version, class: 'Ci::RunnerVersion' do
    sequence(:version) { |n| "1.0.#{n}" }
  end
end
