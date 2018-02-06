FactoryBot.define do
  factory :ci_runner, class: Ci::Runner do
    sequence(:description) { |n| "My runner#{n}" }

    platform  "darwin"
    is_shared false
    active    true
    access_level :not_protected

    trait :online do
      contacted_at Time.now
    end

    trait :shared do
      is_shared true
    end

    trait :specific do
      is_shared false
    end

    trait :inactive do
      active false
    end

    trait :ref_protected do
      access_level :ref_protected
    end
  end
end
