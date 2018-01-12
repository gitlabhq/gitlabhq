FactoryBot.define do
  factory :redirect_route do
    sequence(:path) { |n| "redirect#{n}" }
    source factory: :group
    permanent false

    trait :permanent do
      permanent true
    end

    trait :temporary do
      permanent false
    end
  end
end
