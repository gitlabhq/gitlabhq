# frozen_string_literal: true

FactoryBot.define do
  factory :ci_pipeline_config, class: 'Ci::PipelineConfig' do
    pipeline factory: :ci_empty_pipeline
    content { "content" }
  end
end
