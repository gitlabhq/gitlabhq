# frozen_string_literal: true
FactoryBot.define do
  factory :ml_candidates, class: '::Ml::Candidate' do
    association :project, factory: :project
    association :user

    experiment { association :ml_experiments, project_id: project.id }

    trait :with_metrics_and_params do
      after(:create) do |candidate|
        candidate.metrics = FactoryBot.create_list(:ml_candidate_metrics, 2, candidate: candidate )
        candidate.params = FactoryBot.create_list(:ml_candidate_params, 2, candidate: candidate )
      end
    end

    trait :with_metadata do
      after(:create) do |candidate|
        candidate.metadata = FactoryBot.create_list(:ml_candidate_metadata, 2, candidate: candidate )
      end
    end

    trait :with_artifact do
      after(:create) do |candidate|
        candidate.package = FactoryBot.create(
          :generic_package,
          name: candidate.package_name,
          version: candidate.package_version,
          project: candidate.project
        )
      end
    end
  end
end
