include ActionDispatch::TestProcess

FactoryGirl.define do
  factory :artifact, class: Ci::Artifact do
    project
    build factory: :ci_build

    after :create do |artifact|
      artifact.file = fixture_file_upload(Rails.root.join('spec/fixtures/ci_build_artifacts.zip'), 'application/zip')
      artifact.save
    end

    factory :artifact_metadata do
      type :metadata

      after :create do |artifact|
        artifact.file = fixture_file_upload(Rails.root.join('spec/fixtures/ci_build_artifacts_metadata.gz'), 'application/x-gzip')
        artifact.save
      end
    end
  end
end
