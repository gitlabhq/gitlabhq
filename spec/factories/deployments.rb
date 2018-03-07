FactoryBot.define do
  factory :deployment, class: Deployment do
    sha '97de212e80737a608d939f648d959671fb0a0142'
    ref 'master'
    tag false
    user nil
    project nil
    deployable factory: :ci_build
    environment factory: :environment

    after(:build) do |deployment, evaluator|
      deployment.project ||= deployment.environment.project
      deployment.user ||= deployment.project.creator

      unless deployment.project.repository_exists?
        allow(deployment.project.repository).to receive(:create_ref)
      end
    end
  end
end
