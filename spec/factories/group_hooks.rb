FactoryGirl.define do
  factory :group_hook do
    url { FFaker::Internet.uri('http') }
  end
end
