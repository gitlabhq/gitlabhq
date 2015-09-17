FactoryGirl.define do
  factory :ci_web_hook, class: Ci::WebHook do
    sequence(:url) { FFaker::Internet.uri('http') }
    project factory: :ci_project
  end
end
