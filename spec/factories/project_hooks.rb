FactoryGirl.define do
  factory :project_hook do
    url { FFaker::Internet.uri('http') }

    trait :token do
      token { SecureRandom.hex(10) }
    end
  end
end
