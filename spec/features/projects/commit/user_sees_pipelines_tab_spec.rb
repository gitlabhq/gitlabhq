# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Commit > Pipelines tab', :js, feature_category: :source_code_management do
  let_it_be_with_reload(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  context 'when commit has pipelines' do
    let_it_be(:pipeline) do
      create(:ci_pipeline,
        :success,
        project: project,
        ref: project.default_branch,
        sha: project.commit.sha)
    end

    let_it_be(:job) { create(:ci_build, :success, pipeline: pipeline) }
    let_it_be(:manual_job) { create(:ci_build, :manual, pipeline: pipeline) }

    before do
      visit project_commit_path(project, project.commit.id)
      wait_for_requests
    end

    it 'displays pipelines table' do
      page.within('.commit-ci-menu') do
        click_link('Pipelines')
      end

      wait_for_requests

      within_testid('pipeline-table-row') do
        expect(page).to have_selector('[data-testid="ci-icon"]', text: 'Passed')
        expect(page).to have_content(pipeline.id)
        expect(page).to have_css('[data-testid="pipeline-mini-graph"]')
        expect(page).to have_css('[data-testid="pipelines-manual-actions-dropdown"]')
        expect(page).to have_css('[data-testid="pipeline-multi-actions-dropdown"]')
      end
    end
  end

  context 'when commit does not have pipelines' do
    before do
      visit project_commit_path(project, project.commit.id)
    end

    it 'does not display pipelines tab link' do
      expect(page).not_to have_link('Pipelines')
    end
  end
end
