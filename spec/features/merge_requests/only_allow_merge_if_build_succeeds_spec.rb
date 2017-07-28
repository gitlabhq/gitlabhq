require 'spec_helper'

feature 'Only allow merge requests to be merged if the pipeline succeeds', js: true do
  let(:merge_request) { create(:merge_request_with_diffs) }
  let(:project)       { merge_request.target_project }

  before do
    sign_in merge_request.author

    project.team << [merge_request.author, :master]
  end

  context 'project does not have CI enabled', js: true do
    it 'allows MR to be merged' do
      visit_merge_request(merge_request)

      wait_for_requests

      expect(page).to have_button 'Merge'
    end
  end

  context 'when project has CI enabled', js: true do
    given!(:pipeline) do
      create(:ci_empty_pipeline,
      project: project,
      sha: merge_request.diff_head_sha,
      ref: merge_request.source_branch,
      status: status, head_pipeline_of: merge_request)
    end

    context 'when merge requests can only be merged if the pipeline succeeds' do
      before do
        project.update_attribute(:only_allow_merge_if_pipeline_succeeds, true)
      end

      context 'when CI is running' do
        given(:status) { :running }

        it 'does not allow to merge immediately' do
          visit_merge_request(merge_request)

          wait_for_requests

          expect(page).to have_button 'Merge when pipeline succeeds'
          expect(page).not_to have_button 'Select merge moment'
        end
      end

      context 'when CI failed' do
        given(:status) { :failed }

        it 'does not allow MR to be merged' do
          visit_merge_request(merge_request)

          wait_for_requests

          expect(page).to have_css('button[disabled="disabled"]', text: 'Merge')
          expect(page).to have_content('Please retry the job or push a new commit to fix the failure.')
        end
      end

      context 'when CI canceled' do
        given(:status) { :canceled }

        it 'does not allow MR to be merged' do
          visit_merge_request(merge_request)

          wait_for_requests

          expect(page).not_to have_button 'Merge'
          expect(page).to have_content('Please retry the job or push a new commit to fix the failure.')
        end
      end

      context 'when CI succeeded' do
        given(:status) { :success }

        it 'allows MR to be merged' do
          visit_merge_request(merge_request)

          wait_for_requests

          expect(page).to have_button 'Merge'
        end
      end

      context 'when CI skipped' do
        given(:status) { :skipped }

        it 'allows MR to be merged' do
          visit_merge_request(merge_request)

          wait_for_requests

          expect(page).to have_button 'Merge'
        end
      end
    end

    context 'when merge requests can be merged when the build failed' do
      before do
        project.update_attribute(:only_allow_merge_if_pipeline_succeeds, false)
      end

      context 'when CI is running' do
        given(:status) { :running }

        it 'allows MR to be merged immediately' do
          visit_merge_request(merge_request)

          wait_for_requests

          expect(page).to have_button 'Merge when pipeline succeeds'

          click_button 'Select merge moment'
          expect(page).to have_content 'Merge immediately'
        end
      end

      context 'when CI failed' do
        given(:status) { :failed }

        it 'allows MR to be merged' do
          visit_merge_request(merge_request)

          wait_for_requests

          expect(page).to have_button 'Merge'
        end
      end

      context 'when CI succeeded' do
        given(:status) { :success }

        it 'allows MR to be merged' do
          visit_merge_request(merge_request)

          wait_for_requests

          expect(page).to have_button 'Merge'
        end
      end
    end
  end

  def visit_merge_request(merge_request)
    visit project_merge_request_path(merge_request.project, merge_request)
  end
end
