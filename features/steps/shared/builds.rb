module SharedBuilds
  include Spinach::DSL

  step 'CI is enabled' do
    @project.enable_ci
  end

  step 'I have recent build for my project' do
    ci_commit = create :ci_commit, project: @project, sha: sample_commit.id
    @build = create :ci_build, commit: ci_commit
  end

  step 'I visit recent build summary page' do
    visit namespace_project_build_path(@project.namespace, @project, @build)
  end

  step 'recent build has artifacts available' do
    artifacts = Rails.root + 'spec/fixtures/ci_build_artifacts.zip'
    archive = fixture_file_upload(artifacts, 'application/zip')
    @build.update_attributes(artifacts_file: archive)
  end

  step 'recent build has artifacts metadata available' do
    metadata = Rails.root + 'spec/fixtures/ci_build_artifacts_metadata.gz'
    gzip = fixture_file_upload(metadata, 'application/x-gzip')
    @build.update_attributes(artifacts_metadata: gzip)
  end
end
