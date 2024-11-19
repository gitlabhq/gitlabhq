# frozen_string_literal: true

FactoryBot.define do
  factory :ci_pipeline_message, class: 'Ci::PipelineMessage' do
    pipeline factory: :ci_pipeline
    content { 'warning' }
    severity { 1 }
    project_id { pipeline.project_id }
  end
end
