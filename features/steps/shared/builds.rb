module SharedBuilds
  include Spinach::DSL

  step 'project has CI enabled' do
    @project.enable_ci
  end

  step 'project has coverage enabled' do
    @project.update_attribute(:build_coverage_regex, /Coverage (\d+)%/)
  end

  step 'project has a recent build' do
    @pipeline = create(:ci_empty_pipeline, project: @project, sha: @project.commit.sha, ref: 'master')
    @build = create(:ci_build_with_coverage, pipeline: @pipeline)
  end

  step 'recent build is successful' do
    @build.success
  end

  step 'recent build failed' do
    @build.drop
  end

  step 'project has another build that is running' do
    create(:ci_build, pipeline: @pipeline, name: 'second build', status_event: 'run')
  end

  step 'I visit recent build details page' do
    visit namespace_project_build_path(@project.namespace, @project, @build)
  end

  step 'I visit project builds page' do
    visit namespace_project_builds_path(@project.namespace, @project)
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

  step 'recent build has a build trace' do
    @build.trace = 'build trace'
  end

  step 'download of build artifacts archive starts' do
    expect(page.response_headers['Content-Type']).to eq 'application/zip'
    expect(page.response_headers['Content-Transfer-Encoding']).to eq 'binary'
  end

  step 'I access artifacts download page' do
    visit download_namespace_project_build_artifacts_path(@project.namespace, @project, @build)
  end

  step 'I see details of a build' do
    expect(page).to have_content "Build ##{@build.id}"
  end

  step 'I see build trace' do
    expect(page).to have_css '#build-trace'
  end

  step 'I see the build' do
    page.within('.build') do
      expect(page).to have_content "##{@build.id}"
      expect(page).to have_content @build.sha[0..7]
      expect(page).to have_content @build.ref
      expect(page).to have_content @build.name
    end
  end
end
