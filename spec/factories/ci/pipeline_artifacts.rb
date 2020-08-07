# frozen_string_literal: true

FactoryBot.define do
  factory :ci_pipeline_artifact, class: 'Ci::PipelineArtifact' do
    pipeline factory: :ci_pipeline
    project { pipeline.project }
    file_type { :code_coverage }
    file_format { :raw }
    file_store { Ci::PipelineArtifact::FILE_STORE_SUPPORTED.first }
    size { 1.megabytes }
  end
end
