FactoryGirl.define do
  factory :user_activity do
    last_activity_at { Time.now }
    user
  end
end
