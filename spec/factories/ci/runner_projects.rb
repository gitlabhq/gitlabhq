# frozen_string_literal: true

FactoryBot.define do
  factory :ci_runner_project, class: 'Ci::RunnerProject' do
    project

    after(:build) do |runner_project, evaluator|
      unless runner_project.runner.present?
        runner_project.runner = build(
          :ci_runner, :project, runner_projects: [runner_project]
        )
      end
    end
  end
end
