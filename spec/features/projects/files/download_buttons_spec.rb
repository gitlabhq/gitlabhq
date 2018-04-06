require 'spec_helper'

describe 'Projects > Files > Download buttons in files tree' do
  let(:user) { create(:user) }
  let(:role) { :developer }
  let(:status) { 'success' }
  let(:project) { create(:project, :repository) }

  let(:pipeline) do
    create(:ci_pipeline,
           project: project,
           sha: project.commit.sha,
           ref: project.default_branch,
           status: status)
  end

  let!(:build) do
    create(:ci_build, :success, :artifacts,
           pipeline: pipeline,
           status: pipeline.status,
           name: 'build')
  end

  before do
    sign_in(user)
    project.add_role(user, role)
  end

  describe 'when files tree' do
    context 'with artifacts' do
      before do
        visit project_tree_path(project, project.default_branch)
      end

      it 'shows download artifacts button' do
        href = latest_succeeded_project_artifacts_path(project, "#{project.default_branch}/download", job: 'build')

        expect(page).to have_link "Download '#{build.name}'", href: href
      end
    end
  end
end
