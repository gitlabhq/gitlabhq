FactoryGirl.define do
  factory :forked_project_link do
    association :forked_to_project, factory: :project
    association :forked_from_project, factory: :project

    after(:create) do |link|
      link.forked_from_project.reload
      link.forked_to_project.reload
    end

    trait :forked_to_empty_project do
      association :forked_to_project, factory: :empty_project
    end
  end
end
