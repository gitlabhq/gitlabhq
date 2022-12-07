# frozen_string_literal: true

FactoryBot.define do
  factory :ci_sources_pipeline, class: 'Ci::Sources::Pipeline' do
    after(:build) do |source|
      source.project ||= source.pipeline.project
      source.source_pipeline ||= source.source_job&.pipeline
      source.source_project ||= source.source_pipeline&.project
    end

    source_job factory: :ci_build

    pipeline factory: :ci_empty_pipeline
  end
end
