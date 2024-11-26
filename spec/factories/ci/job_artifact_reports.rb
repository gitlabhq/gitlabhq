# frozen_string_literal: true

FactoryBot.define do
  factory :ci_job_artifact_report, class: 'Ci::JobArtifactReport' do
    job_artifact factory: :ci_job_artifact
    project_id { job_artifact.project_id }

    trait :validated do
      status { 1 }
    end

    trait :faulty do
      status { 0 }
    end
  end
end
