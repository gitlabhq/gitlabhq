FactoryGirl.define do
  factory :geo_node do
    host { Gitlab.config.gitlab.host }
    sequence(:port) {|n| n}

    trait :primary do
      primary true
      port { Gitlab.config.gitlab.port }
    end
  end
end
