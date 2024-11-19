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

  shared_examples 'Set to auto-merge activator' do
    it 'activates auto-merge feature' do
      visit project_merge_request_path(project, merge_request)

      expect(page).to have_content 'Set to auto-merge'
      click_button "Set to auto-merge"
      wait_for_requests

      expect(page).to have_content "Set by #{user.name} to be merged automatically when all merge checks pass"
      expect(page).to have_content "Source branch will not be deleted"
      expect(page).to have_selector ".js-cancel-auto-merge"
      expect(page).to have_content(/enabled an automatic merge when all merge checks for \h{8} pass/i)
    end
  end

  shared_examples 'immediate merge' do
    it 'can be merged' do
      visit project_merge_request_path(project, merge_request)

      wait_for_requests
      expect(page).not_to have_content 'Set to auto-merge'
      expect(page).to have_button 'Merge'
    end
  end

  context 'when there is an active pipeline' do
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

    it 'changes the source branch text' do
      check('Delete source branch')
      click_button "Set to auto-merge"

      wait_for_requests

      expect(page).to have_content "Source branch will be deleted"
    end

    context 'when it allows enabling after it was previously canceled' do
      before do
        click_button "Set to auto-merge"

        wait_for_requests

        click_button "Cancel auto-merge"

        wait_for_requests
      end

      it_behaves_like 'Set to auto-merge activator'
    end

    context 'when pipeline must succeed setting is true' do
      before do
        project.update!(only_allow_merge_if_pipeline_succeeds: true)
      end

      it_behaves_like 'Set to auto-merge activator'
    end

    context 'when pipeline must succeed setting is false' do
      before do
        project.update!(only_allow_merge_if_pipeline_succeeds: false)
      end

      it_behaves_like 'Set to auto-merge activator'
    end
  end

  context 'when there is a skipped pipeline' do
    let(:pipeline) { create(:ci_pipeline, :merged_result_pipeline, :skipped, merge_request: merge_request) }

    before do
      create(:ci_build, :skipped, pipeline: pipeline)
      merge_request.update_head_pipeline

      sign_in(user)
    end

    context 'when skipped pipeline is considered success' do
      before do
        project.update!(allow_merge_on_skipped_pipeline: true)
      end

      it_behaves_like 'immediate merge'
    end

    context 'when skipped pipeline is not considered success' do
      before do
        project.update!(allow_merge_on_skipped_pipeline: false)
      end

      context 'when pipeline must succeed setting is true' do
        before do
          project.update!(only_allow_merge_if_pipeline_succeeds: true)
        end

        it_behaves_like 'Set to auto-merge activator'
      end

      context 'when pipeline must succeed setting is false' do
        before do
          project.update!(only_allow_merge_if_pipeline_succeeds: false)
        end

        it_behaves_like 'immediate merge'
      end
    end
  end

  context 'when the pipeline is success' do
    let(:pipeline) { create(:ci_pipeline, :merged_result_pipeline, :success, merge_request: merge_request) }

    before do
      create(:ci_build, :success, pipeline: pipeline)
      merge_request.update_head_pipeline

      sign_in(user)
    end

    context 'when other checks pass' do
      it_behaves_like 'immediate merge'
    end

    context 'when other checks do not pass' do
      before do
        merge_request.update!(title: "Draft: 111")
      end

      it_behaves_like 'Set to auto-merge activator'
    end
  end

  context 'when there is no pipeline' do
    before do
      sign_in user
    end

    it 'allows setting to auto merge' do
      expect(page).not_to have_link 'Set to auto-merge'
    end
  end
end
