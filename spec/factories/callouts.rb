FactoryBot.define do
  factory :callout do
    feature_name 'test_callout'
    dismissed_state false

    user
  end
end
