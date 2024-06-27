# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User sets to auto-merge', :js, feature_category: :code_review_workflow do
  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }
  let(:merge_request) do
    create(:merge_request, :with_merge_request_pipeline,
      source_project: project, source_branch: 'feature',
      target_project: project, target_branch: 'master',
      author: user, title: 'Bug NS-04', merge_sha: '12345678')
  end

  let!(:pipeline) { merge_request.all_pipelines.first }

  before do
    merge_request.update_head_pipeline
    project.add_maintainer(user)
  end

  context 'when there is active pipeline for merge request' do
    before do
      create(:ci_build, pipeline: pipeline)

      sign_in(user)

      visit project_merge_request_path(project, merge_request)
    end

    it 'allows to cancel the auto-merge' do
      click_button "Set to auto-merge"

      wait_for_requests

      click_button "Cancel auto-merge"

      wait_for_requests

      expect(page).to have_content "canceled the automatic merge"
    end

    describe 'setting to auto-merge true' do
      shared_examples 'Set to auto-merge activator' do
        it 'activates auto-merge feature' do
          expect(page).to have_content 'Set to auto-merge'
          click_button "Set to auto-merge"
          wait_for_requests

          expect(page).to have_content "Set by #{user.name} to be merged automatically when all merge checks pass"
          expect(page).to have_content "Source branch will not be deleted"
          expect(page).to have_selector ".js-cancel-auto-merge"
          expect(page).to have_content(/enabled an automatic merge when all merge checks for \h{8} pass/i)
        end
      end

      context "when enabled immediately" do
        it_behaves_like 'Set to auto-merge activator'
      end

      context 'when enabled after it was previously canceled' do
        before do
          click_button "Set to auto-merge"

          wait_for_requests

          click_button "Cancel auto-merge"

          wait_for_requests
        end

        it_behaves_like 'Set to auto-merge activator'
      end
    end
  end

  context 'when there is no active pipeline' do
    before do
      sign_in user
      visit project_merge_request_path(project, merge_request.reload)
    end

    it 'does not allow to set to auto-merge' do
      expect(page).not_to have_link 'Set to auto-merge'
    end
  end
end
