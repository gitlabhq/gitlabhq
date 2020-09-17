# frozen_string_literal: true

FactoryBot.define do
  factory :ci_pipeline_artifact, class: 'Ci::PipelineArtifact' do
    pipeline factory: :ci_pipeline
    project { pipeline.project }
    file_type { :code_coverage }
    file_format { :raw }
    file_store { ObjectStorage::SUPPORTED_STORES.first }
    size { 1.megabytes }

    after(:build) do |artifact, _evaluator|
      artifact.file = fixture_file_upload(
        Rails.root.join('spec/fixtures/pipeline_artifacts/code_coverage.json'), 'application/json')
    end

    trait :with_multibyte_characters do
      size { { "utf8" => "✓" }.to_json.bytesize }
      after(:build) do |artifact, _evaluator|
        artifact.file = CarrierWaveStringFile.new_file(
          file_content: { "utf8" => "✓" }.to_json,
          filename: 'filename',
          content_type: 'application/json'
        )
      end
    end

    trait :with_code_coverage_with_multiple_files do
      after(:build) do |artifact, _evaluator|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/pipeline_artifacts/code_coverage_with_multiple_files.json'), 'application/json'
        )
      end

      size { file.size }
    end
  end
end
