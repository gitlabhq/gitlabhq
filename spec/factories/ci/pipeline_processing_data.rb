# frozen_string_literal: true

FactoryBot.define do
  factory :ci_pipeline_processing_data, class: 'Ci::PipelineProcessingData' do
    pipeline factory: :ci_empty_pipeline
    project_id { pipeline.project_id }
  end
end
