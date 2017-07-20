FactoryGirl.define do
  factory :ci_runner_project, class: Ci::RunnerProject do
    runner factory: :ci_runner
    project factory: :empty_project
  end
end
