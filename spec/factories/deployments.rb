FactoryGirl.define do
  factory :deployment, class: Deployment do
    sha 'b83d6e391c22777fca1ed3012fce84f633d7fed0'
    ref 'master'
    tag false
    project

    environment factory: :environment

    after(:build) do |deployment, evaluator|
      deployment.project ||= deployment.environment.project
    end
  end
end
