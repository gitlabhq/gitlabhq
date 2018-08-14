FactoryBot.define do
  factory :project_auto_devops do
    project
    enabled true
    domain "example.com"
    deploy_strategy :continuous

    trait :manual do
      deploy_strategy :manual
    end

    trait :disabled do
      enabled false
    end
  end
end
