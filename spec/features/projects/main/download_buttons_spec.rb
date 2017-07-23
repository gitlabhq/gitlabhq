require 'spec_helper'

feature 'Download buttons in project main page', feature: true do
  given(:user) { create(:user) }
  given(:role) { :developer }
  given(:status) { 'success' }
  given(:project) { create(:project) }

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
    project.team << [user, role]
  end

  describe 'when checking project main page' do
    context 'with artifacts' do
      before do
        visit project_path(project)
      end

      scenario 'shows download artifacts button' do
        href = latest_succeeded_project_artifacts_path(project, "#{project.default_branch}/download", job: 'build')

        expect(page).to have_link "Download '#{build.name}'", href: href
      end

      scenario 'download links have download attribute' do
        expect(page).to have_selector('a', text: 'Download')
        page.all('a', text: 'Download').each do |link|
          expect(link[:download]).to eq ''
        end
      end
    end
  end
end
