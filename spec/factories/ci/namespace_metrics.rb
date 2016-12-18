FactoryGirl.define do
  factory :namespace_metrics do
    trait :with_used_limit do
      shared_runners_minutes 1000
    end
  end
end
