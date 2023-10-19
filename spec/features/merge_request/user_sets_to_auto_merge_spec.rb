# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User sets to auto-merge', :js, feature_category: :code_review_workflow do
  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }
  let(:merge_request) do
    create(
      :merge_request_with_diffs,
      source_project: project,
      author: user,
      title: 'Bug NS-04',
      merge_params: { force_remove_source_branch: '1' }
    )
  end

  let(:pipeline) do
    create(
      :ci_pipeline,
      project: project,
      sha: merge_request.diff_head_sha,
      ref: merge_request.source_branch,
      head_pipeline_of: merge_request
    )
  end

  before do
    project.add_maintainer(user)
  end

  context 'when there is active pipeline for merge request' do
    before do
      create(:ci_build, pipeline: pipeline)

      sign_in(user)
      visit project_merge_request_path(project, merge_request)
    end

    describe 'setting to auto-merge when pipeline succeeds' do
      shared_examples 'Set to auto-merge activator' do
        it 'activates auto-merge feature', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/410055' do
          expect(page).to have_content 'Set to auto-merge'
          click_button "Set to auto-merge"
          wait_for_requests

          expect(page).to have_content "Set by #{user.name} to be merged automatically when the pipeline succeeds"
          expect(page).to have_content "Source branch will not be deleted"
          expect(page).to have_selector ".js-cancel-auto-merge"
          expect(page).to have_content(/enabled an automatic merge when the pipeline for \h{8} succeeds/i)
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

      context 'when it is enabled and then canceled' do
        let(:merge_request) do
          create(
            :merge_request_with_diffs,
            :merge_when_pipeline_succeeds,
            source_project: project,
            title: 'Bug NS-04',
            author: user,
            merge_user: user
          )
        end

        before do
          merge_request.merge_params['force_remove_source_branch'] = '0'
          merge_request.save!
          click_button "Cancel auto-merge"
        end

        it_behaves_like 'Set to auto-merge activator'
      end
    end
  end

  context 'when there is an active pipeline' do
    let(:merge_request) do
      create(
        :merge_request_with_diffs,
        :simple,
        :merge_when_pipeline_succeeds,
        source_project: project,
        author: user,
        merge_user: user,
        title: 'MepMep'
      )
    end

    let!(:build) do
      create(:ci_build, pipeline: pipeline)
    end

    before do
      sign_in user
      visit project_merge_request_path(project, merge_request)
    end

    it 'allows to cancel the auto-merge', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/410055' do
      click_button "Cancel auto-merge"

      expect(page).to have_button "Set to auto-merge"

      refresh

      expect(page).to have_content "canceled the automatic merge"
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
