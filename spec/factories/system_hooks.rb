FactoryGirl.define do
  factory :system_hook do
    url { FFaker::Internet.uri('http') }
  end
end
