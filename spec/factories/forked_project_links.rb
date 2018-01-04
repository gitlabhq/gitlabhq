FactoryBot.define do
  factory :forked_project_link do
    association :forked_to_project, factory: [:project, :repository]
    association :forked_from_project, factory: [:project, :repository]

    after(:create) do |link|
      link.forked_from_project.reload
      link.forked_to_project.reload
    end

    trait :forked_to_empty_project do
      association :forked_to_project, factory: [:project, :repository]
    end
  end
end
