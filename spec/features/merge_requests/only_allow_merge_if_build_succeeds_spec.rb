require 'spec_helper'

feature 'Only allow merge requests to be merged if the build succeeds', feature: true do
  let(:merge_request) { create(:merge_request_with_diffs) }
  let(:project)       { merge_request.target_project }

  before do
    login_as merge_request.author

    project.team << [merge_request.author, :master]
  end

  context 'project does not have CI enabled' do
    it 'allows MR to be merged' do
      visit_merge_request(merge_request)

      expect(page).to have_button 'Accept Merge Request'
    end
  end

  context 'when project has CI enabled' do
    given!(:pipeline) do
      create(:ci_empty_pipeline,
      project: project,
      sha: merge_request.diff_head_sha,
      ref: merge_request.source_branch,
      status: status)
    end

    context 'when merge requests can only be merged if the build succeeds' do
      before do
        project.update_attribute(:only_allow_merge_if_build_succeeds, true)
      end

      context 'when CI is running' do
        given(:status) { :running }

        it 'does not allow to merge immediately' do
          visit_merge_request(merge_request)

          expect(page).to have_button 'Merge When Pipeline Succeeds'
          expect(page).not_to have_button 'Select Merge Moment'
        end
      end

      context 'when CI failed' do
        given(:status) { :failed }

        it 'does not allow MR to be merged' do
          visit_merge_request(merge_request)

          expect(page).not_to have_button 'Accept Merge Request'
          expect(page).to have_content('Please retry the job or push a new commit to fix the failure.')
        end
      end

      context 'when CI canceled' do
        given(:status) { :canceled }

        it 'does not allow MR to be merged' do
          visit_merge_request(merge_request)

          expect(page).not_to have_button 'Accept Merge Request'
          expect(page).to have_content('Please retry the job or push a new commit to fix the failure.')
        end
      end

      context 'when CI succeeded' do
        given(:status) { :success }

        it 'allows MR to be merged' do
          visit_merge_request(merge_request)

          expect(page).to have_button 'Accept Merge Request'
        end
      end

      context 'when CI skipped' do
        given(:status) { :skipped }

        it 'allows MR to be merged' do
          visit_merge_request(merge_request)

          expect(page).to have_button 'Accept Merge Request'
        end
      end
    end

    context 'when merge requests can be merged when the build failed' do
      before do
        project.update_attribute(:only_allow_merge_if_build_succeeds, false)
      end

      context 'when CI is running' do
        given(:status) { :running }

        it 'allows MR to be merged immediately', js: true do
          visit_merge_request(merge_request)

          expect(page).to have_button 'Merge When Pipeline Succeeds'

          click_button 'Select Merge Moment'
          expect(page).to have_content 'Merge Immediately'
        end
      end

      context 'when CI failed' do
        given(:status) { :failed }

        it 'allows MR to be merged' do
          visit_merge_request(merge_request)

          expect(page).to have_button 'Accept Merge Request'
        end
      end

      context 'when CI succeeded' do
        given(:status) { :success }

        it 'allows MR to be merged' do
          visit_merge_request(merge_request)

          expect(page).to have_button 'Accept Merge Request'
        end
      end
    end
  end

  def visit_merge_request(merge_request)
    visit namespace_project_merge_request_path(merge_request.project.namespace, merge_request.project, merge_request)
  end
end
