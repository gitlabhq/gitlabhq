FactoryBot.define do
  factory :project_auto_devops do
    project
    enabled true
    domain "example.com"

    trait :disabled do
      enabled false
    end
  end
end
