include ActionDispatch::TestProcess

FactoryGirl.define do
  factory :ci_job_artifact, class: Ci::JobArtifact do
    job factory: :ci_build
    file_type :archive

    after :build do |artifact|
      artifact.project ||= artifact.job.project
    end

    after :create do |artifact|
      if artifact.archive?
        artifact.file = fixture_file_upload(Rails.root.join('spec/fixtures/ci_build_artifacts.zip'),
                                            'application/zip')
        artifact.save
      end
    end
  end

  factory :ci_job_metadata, parent: :ci_job_artifact do
    file_type :metadata

    after :create do |artifact|
      artifact.file = fixture_file_upload(Rails.root.join('spec/fixtures/ci_build_artifacts_metadata.gz'),
                                            'application/x-gzip')
      artifact.save
    end
  end
end
