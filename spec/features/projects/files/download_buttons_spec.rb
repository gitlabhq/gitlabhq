require 'spec_helper'

feature 'Download buttons in files tree' do
  given(:user) { create(:user) }
  given(:role) { :developer }
  given(:status) { 'success' }
  given(:project) { create(:project, :repository) }

  given(:pipeline) do
    create(:ci_pipeline,
           project: project,
           sha: project.commit.sha,
           ref: project.default_branch,
           status: status)
  end

  given!(:build) do
    create(:ci_build, :success, :artifacts,
           pipeline: pipeline,
           status: pipeline.status,
           name: 'build')
  end

  background do
    sign_in(user)
    project.add_role(user, role)
  end

  describe 'when files tree' do
    context 'with artifacts' do
      before do
        visit project_tree_path(project, project.default_branch)
      end

      scenario 'shows download artifacts button' do
        href = latest_succeeded_project_artifacts_path(project, "#{project.default_branch}/download", job: 'build')

        expect(page).to have_link "Download '#{build.name}'", href: href
      end
    end
  end
end
