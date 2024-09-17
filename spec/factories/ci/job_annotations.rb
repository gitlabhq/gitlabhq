# frozen_string_literal: true

FactoryBot.define do
  factory :ci_job_annotation, class: 'Ci::JobAnnotation' do
    sequence(:name) { |n| "annotation_#{n}" }
    job factory: :ci_build

    trait :external_link do
      data { [{ external_link: { label: 'Example URL', url: 'https://example.com/' } }] }
    end

    project_id { job.project.id }
  end
end
