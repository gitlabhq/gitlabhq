require 'spec_helper'

describe 'Projects > Files > Download buttons in files tree' do
  let(:project) { create(:project, :repository) }
  let(:user) { project.creator }

  let(:pipeline) do
    create(:ci_pipeline,
           project: project,
           sha: project.commit.sha,
           ref: project.default_branch,
           status: 'success')
  end

  let!(:build) do
    create(:ci_build, :success, :artifacts,
           pipeline: pipeline,
           status: pipeline.status,
           name: 'build')
  end

  before do
    sign_in(user)
    project.add_developer(user)

    visit project_tree_path(project, project.default_branch)
  end

  context 'with artifacts' do
    it 'shows download artifacts button' do
      href = latest_succeeded_project_artifacts_path(project, "#{project.default_branch}/download", job: 'build')

      expect(page).to have_link "Download '#{build.name}'", href: href
    end
  end
end
