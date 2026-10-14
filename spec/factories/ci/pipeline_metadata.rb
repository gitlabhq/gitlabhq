# frozen_string_literal: true

FactoryBot.define do
  factory :ci_pipeline_metadata, class: 'Ci::PipelineMetadata' do
    name { 'Pipeline name' }

    pipeline factory: :ci_pipeline
    project
  end
end
