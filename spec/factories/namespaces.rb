FactoryGirl.define do
  factory :namespace do
    sequence(:name) { |n| "namespace#{n}" }
    path { name.downcase.gsub(/\s/, '_') }
    owner

    trait :with_limit do
      shared_runners_minutes_limit 500
    end

    trait :with_used_limit do
      namespace_metrics factory: :namespace_metrics, :with_used_limit
      shared_runners_minutes_limit 500
    end
  end
end
