FactoryGirl.define do
  factory :geo_node do
    host { Gitlab.config.gitlab.host }
    sequence(:port) {|n| n}

    trait :ssh do
      clone_protocol 'ssh'
      association :geo_node_key
    end

    trait :primary do
      primary true
      port { Gitlab.config.gitlab.port }
    end
  end
end
