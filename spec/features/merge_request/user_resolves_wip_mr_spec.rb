# frozen_string_literal: true

require 'spec_helper'

describe 'Merge request > User resolves Work in Progress', :js do
  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }
  let(:merge_request) do
    create(:merge_request_with_diffs, source_project: project,
                                      author: user,
                                      title: 'WIP: Bug NS-04',
                                      merge_params: { force_remove_source_branch: '1' })
  end
  let(:pipeline) do
    create(:ci_pipeline, project: project,
                         sha: merge_request.diff_head_sha,
                         ref: merge_request.source_branch,
                         head_pipeline_of: merge_request)
  end

  before do
    project.add_maintainer(user)
  end

  context 'when there is active pipeline for merge request' do
    before do
      create(:ci_build, pipeline: pipeline)
      sign_in(user)
      visit project_merge_request_path(project, merge_request)
      wait_for_requests
    end

    it 'retains merge request data after clicking Resolve WIP status' do
      expect(page.find('.ci-widget-content')).to have_content("Pipeline ##{pipeline.id}")
      expect(page).to have_content "This is a Work in Progress"

      click_button('Resolve WIP status')

      wait_for_requests

      # If we don't disable the wait here, the test will wait until the
      # merge request widget refreshes, which masks missing elements
      # that should already be present.
      expect(page.find('.ci-widget-content', wait: 0)).to have_content("Pipeline ##{pipeline.id}")
      expect(page).not_to have_content('This is a Work in Progress')
    end
  end
end
