# frozen_string_literal: true
FactoryBot.define do
  factory :ml_candidates, class: '::Ml::Candidate' do
    association :project, factory: :project
    association :user

    experiment { association :ml_experiments, project_id: project.id }

    trait :with_metrics_and_params do
      metrics { Array.new(2) { association(:ml_candidate_metrics, candidate: instance) } }
      params { Array.new(2) { association(:ml_candidate_params, candidate: instance) } }
    end

    trait :with_metadata do
      metadata { Array.new(2) { association(:ml_candidate_metadata, candidate: instance) } }
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
