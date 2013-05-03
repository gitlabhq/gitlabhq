# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :forked_project_link do
    association :forked_to_project, factory: :project
    association :forked_from_project, factory: :project
  end
end
