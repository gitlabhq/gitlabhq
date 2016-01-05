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
end
