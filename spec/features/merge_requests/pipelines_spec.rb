require 'spec_helper'

feature 'Pipelines for Merge Requests', feature: true, js: true do
  include WaitForAjax

  given(:user) { create(:user) }
  given(:merge_request) { create(:merge_request) }
  given(:project) { merge_request.target_project }

  before do
    project.team << [user, :master]
    login_as user
  end

  context 'with pipelines' do
    let!(:pipeline) do
      create(:ci_empty_pipeline,
             project: merge_request.source_project,
             ref: merge_request.source_branch,
             sha: merge_request.diff_head_sha)
    end

    before do
      visit namespace_project_merge_request_path(project.namespace, project, merge_request)
    end

    scenario 'does click a pipeline tab and sees a list of pipelines' do
      page.within('.merge-request-tabs') do
        click_link('Pipelines')
      end
      wait_for_ajax

      expect(page).to have_selector('.pipeline-actions')
    end
  end

  context 'without pipelines' do
    before do
      visit namespace_project_merge_request_path(project.namespace, project, merge_request)
    end

    scenario 'does not find a pipeline link' do
      page.within('.merge-request-tabs') do
        expect(page).not_to have_link('Pipelines')
      end
    end
  end
end
