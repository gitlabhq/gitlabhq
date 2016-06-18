FactoryGirl.define do
  factory :environment, class: Environment do
    sequence(:name) { |n| "environment#{n}" }

    project factory: :empty_project
  end
end
