# frozen_string_literal: true

FactoryBot.define do
  factory :ci_runner_project, class: 'Ci::RunnerProject' do
    runner factory: [:ci_runner, :project]
    project
  end
end
