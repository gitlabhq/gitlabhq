# frozen_string_literal: true

FactoryBot.define do
  factory :ci_runner_project, class: 'Ci::RunnerProject' do
    project
    runner { association(:ci_runner, :project, projects: [project], runner_projects: [instance]) }
  end
end
