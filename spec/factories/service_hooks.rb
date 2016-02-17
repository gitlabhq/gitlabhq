FactoryGirl.define do
  factory :service_hook do
    url { FFaker::Internet.uri('http') }
    service
  end
end
