# frozen_string_literal: true

FactoryBot.define do
  factory :ci_runner_controller, class: 'Ci::RunnerController' do
    description { "Controller for managing runner" }
  end
end
