FactoryGirl.define do
  factory :project_group_link do
    project factory: :empty_project
    group
  end
end
