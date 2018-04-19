require 'spec_helper'

feature 'Download buttons in branches page' do
  given(:user) { create(:user) }
  given(:role) { :developer }
  given(:status) { 'success' }
  given(:project) { create(:project, :repository) }

  given(:pipeline) do
    create(:ci_pipeline,
           project: project,
           sha: project.commit('binary-encoding').sha,
           ref: 'binary-encoding', # make sure the branch is in the 1st page!
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

  describe 'when checking branches' do
    context 'with artifacts' do
      before do
        visit project_branches_filtered_path(project, state: 'all', search: 'binary-encoding')
      end

      scenario 'shows download artifacts button' do
        href = latest_succeeded_project_artifacts_path(project, 'binary-encoding/download', job: 'build')

        expect(page).to have_link "Download '#{build.name}'", href: href
      end
    end
  end
end
