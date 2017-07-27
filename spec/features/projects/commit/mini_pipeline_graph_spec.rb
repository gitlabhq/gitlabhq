require 'rails_helper'

feature 'Mini Pipeline Graph in Commit View', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }

  before do
    sign_in(user)
  end

  context 'when commit has pipelines' do
    let(:pipeline) do
      create(:ci_empty_pipeline,
              project: project,
              ref: project.default_branch,
              sha: project.commit.sha)
    end

    let(:build) do
      create(:ci_build, pipeline: pipeline)
    end

    before do
      build.run
      visit project_commit_path(project, project.commit.id)
    end

    it 'should display a mini pipeline graph' do
      expect(page).to have_selector('.mr-widget-pipeline-graph')
    end

    it 'should show the builds list when stage is clicked' do
      first('.mini-pipeline-graph-dropdown-toggle').click

      wait_for_requests

      page.within '.js-builds-dropdown-list' do
        expect(page).to have_selector('.ci-status-icon-running')
        expect(page).to have_content(build.stage)
      end
    end
  end

  context 'when commit does not have pipelines' do
    before do
      visit project_commit_path(project, project.commit.id)
    end

    it 'should not display a mini pipeline graph' do
      expect(page).not_to have_selector('.mr-widget-pipeline-graph')
    end
  end
end
