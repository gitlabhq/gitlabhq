require 'spec_helper'

feature 'Pipelines for Merge Requests', feature: true, js: true do
  given(:user) { create(:user) }
  given(:merge_request) { create(:merge_request) }
  given(:project) { merge_request.target_project }

  before do
    project.team << [user, :master]
    sign_in user
  end

  context 'with pipelines' do
    let!(:pipeline) do
      create(:ci_empty_pipeline,
             project: merge_request.source_project,
             ref: merge_request.source_branch,
             sha: merge_request.diff_head_sha)
    end

    before do
      visit project_merge_request_path(project, merge_request)
    end

    scenario 'user visits merge request pipelines tab' do
      page.within('.merge-request-tabs') do
        click_link('Pipelines')
      end
      wait_for_requests

      expect(page).to have_selector('.stage-cell')
    end
  end

  context 'without pipelines' do
    before do
      visit project_merge_request_path(project, merge_request)
    end

    scenario 'user visits merge request page' do
      page.within('.merge-request-tabs') do
        expect(page).to have_no_link('Pipelines')
      end
    end
  end
end
