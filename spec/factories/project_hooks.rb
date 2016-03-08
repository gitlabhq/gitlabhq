FactoryGirl.define do
  factory :project_hook do
    url { FFaker::Internet.uri('http') }
  end
end
