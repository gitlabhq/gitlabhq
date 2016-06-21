FactoryGirl.define do
  factory :path_lock do
    project
    user { build :user }
    sequence(:path) { |n| "app/model#{n}" }
  end
end
