FactoryGirl.define do
  factory :deployment, class: Deployment do
    sha '97de212e80737a608d939f648d959671fb0a0142'
    ref 'master'
    tag false
    project nil

    environment factory: :environment

    after(:build) do |deployment, evaluator|
      deployment.project ||= deployment.environment.project
    end
  end
end
