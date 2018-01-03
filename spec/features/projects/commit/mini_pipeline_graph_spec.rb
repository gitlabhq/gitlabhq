require 'rails_helper'

feature 'Mini Pipeline Graph in Commit View', :js do
  let(:project) { create(:project, :public, :repository) }

  context 'when commit has pipelines' do
    let(:pipeline) do
      create(:ci_empty_pipeline,
              project: project,
              ref: project.default_branch,
              sha: project.commit.sha)
    end
    let(:build) { create(:ci_build, pipeline: pipeline) }

    it 'display icon with status' do
      build.run
      visit project_commit_path(project, project.commit.id)

      expect(page).to have_selector('.ci-status-icon-running')
    end

    it 'displays a mini pipeline graph' do
      build.run
      visit project_commit_path(project, project.commit.id)

      expect(page).to have_selector('.mr-widget-pipeline-graph')

      first('.mini-pipeline-graph-dropdown-toggle').click

      wait_for_requests

      page.within '.js-builds-dropdown-list' do
        expect(page).to have_selector('.ci-status-icon-running')
        expect(page).to have_content(build.stage)
      end

      build.drop
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
