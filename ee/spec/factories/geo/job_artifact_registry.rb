FactoryBot.define do
  factory :geo_job_artifact_registry, class: Geo::JobArtifactRegistry do
    sequence(:artifact_id)
    success true

    trait :with_artifact do
      after(:build, :stub) do |registry, _|
        file = create(:ci_job_artifact)
        registry.artifact_id = file.id
      end
    end
  end
end
