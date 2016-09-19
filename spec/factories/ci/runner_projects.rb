FactoryGirl.define do
  factory :ci_runner_project, class: Ci::RunnerProject do
    runner_id 1
    gl_project_id 1
  end
end
