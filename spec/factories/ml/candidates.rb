# frozen_string_literal: true
FactoryBot.define do
  factory :ml_candidates, class: '::Ml::Candidate' do
    project { association :project }
    user { project.owner }
    experiment { association :ml_experiments, project_id: project.id, user: project.owner }

    trait :with_metrics_and_params do
      metrics { Array.new(2) { association(:ml_candidate_metrics, candidate: instance) } }
      params { Array.new(2) { association(:ml_candidate_params, candidate: instance) } }
    end

    trait :with_metadata do
      metadata { Array.new(2) { association(:ml_candidate_metadata, candidate: instance) } }
    end

    trait :with_artifact do
      artifact do
        association(:generic_package, name: instance.package_name, version: instance.package_version || '1',
          project: project)
      end
    end
  end
end
