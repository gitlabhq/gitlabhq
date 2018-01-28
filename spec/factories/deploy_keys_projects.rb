FactoryBot.define do
  factory :deploy_keys_project do
    deploy_key
    project

    trait :write_access do
      can_push true
    end
  end
end
