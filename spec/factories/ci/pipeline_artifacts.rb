# frozen_string_literal: true

FactoryBot.define do
  factory :ci_pipeline_artifact, class: 'Ci::PipelineArtifact' do
    pipeline factory: :ci_pipeline
    project { pipeline.project }
    file_format { :raw }
    file_store { ObjectStorage::SUPPORTED_STORES.first }
    size { 1.megabyte }
    file_type { :code_coverage }
    after(:build) do |artifact, _evaluator|
      artifact.file = fixture_file_upload(
        Rails.root.join('spec/fixtures/pipeline_artifacts/code_coverage.json'), 'application/json')
    end

    trait :unlocked do
      association :pipeline, :unlocked, factory: :ci_pipeline
    end

    trait :artifact_unlocked do
      association :pipeline, :unlocked, factory: :ci_pipeline
      locked { :unlocked }
    end

    trait :expired do
      expire_at { Date.yesterday }
    end

    trait :remote_store do
      file_store { ::ObjectStorage::Store::REMOTE }
    end

    trait :with_coverage_report do
      file_type { :code_coverage }

      after(:build) do |artifact, _evaluator|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/pipeline_artifacts/code_coverage.json'), 'application/json')
      end

      size { file.size }
    end

    trait :with_coverage_multibyte_characters do
      file_type { :code_coverage }
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
      file_type { :code_coverage }

      after(:build) do |artifact, _evaluator|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/pipeline_artifacts/code_coverage_with_multiple_files.json'), 'application/json'
        )
      end

      size { 1.megabyte }
    end

    trait :with_codequality_mr_diff_report do
      file_type { :code_quality_mr_diff }

      after(:build) do |artifact, _evaluator|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/pipeline_artifacts/code_quality_mr_diff.json'), 'application/json')
      end

      size { file.size }
    end
  end
end
