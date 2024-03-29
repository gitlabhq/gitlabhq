# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge requests > User merges immediately', :js, feature_category: :code_review_workflow do
  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }
  let!(:merge_request) do
    create(
      :merge_request_with_diffs,
      source_project: project,
      author: user,
      title: 'Bug NS-04',
      head_pipeline: pipeline,
      source_branch: pipeline.ref
    )
  end

  let(:pipeline) do
    create(
      :ci_pipeline,
      project: project,
      ref: 'master',
      sha: project.repository.commit('master').id
    )
  end

  context 'when there is active pipeline for merge request' do
    before do
      create(:ci_build, pipeline: pipeline)
      project.add_maintainer(user)
      sign_in(user)
      visit project_merge_request_path(project, merge_request)
    end

    it 'enables merge immediately' do
      wait_for_requests

      within_testid('ready_to_merge_state') do
        find('.gl-new-dropdown-toggle').click

        Sidekiq::Testing.fake! do
          click_button 'Merge immediately'
        end
      end

      expect(find_by_testid('merging-state')).to have_content('Merging!')

      wait_for_requests
    end
  end
end
