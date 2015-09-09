FactoryGirl.define do
  factory :ci_web_hook, class: Ci::WebHook do
    sequence(:url) { Faker::Internet.uri('http') }
    project
  end
end
