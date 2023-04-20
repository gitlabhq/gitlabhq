# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User merges only if pipeline succeeds', :js, feature_category: :code_review_workflow do
  let(:merge_request) { create(:merge_request_with_diffs) }
  let(:project)       { merge_request.target_project }

  before do
    project.add_maintainer(merge_request.author)
    sign_in(merge_request.author)
  end

  context 'project does not have CI enabled' do
    it 'allows MR to be merged' do
      stub_feature_flags(auto_merge_labels_mr_widget: false)

      visit project_merge_request_path(project, merge_request)

      wait_for_requests

      page.within('.mr-state-widget') do
        expect(page).to have_button 'Merge'
      end
    end
  end

  context 'project does not have CI enabled and auto_merge_labels_mr_widget on' do
    it 'allows MR to be merged' do
      stub_feature_flags(auto_merge_labels_mr_widget: true)

      visit project_merge_request_path(project, merge_request)

      wait_for_requests

      page.within('.mr-state-widget') do
        expect(page).to have_button 'Merge'
      end
    end
  end

  context 'when project has CI enabled' do
    let!(:pipeline) do
      create(:ci_empty_pipeline,
      project: project,
      sha: merge_request.diff_head_sha,
      ref: merge_request.source_branch,
      status: status, head_pipeline_of: merge_request)
    end

    context 'when merge requests can only be merged if the pipeline succeeds' do
      before do
        project.update_attribute(:only_allow_merge_if_pipeline_succeeds, true)

        stub_feature_flags(auto_merge_labels_mr_widget: false)
      end

      context 'when CI is running' do
        let(:status) { :running }

        it 'does not allow to merge immediately' do
          visit project_merge_request_path(project, merge_request)

          wait_for_requests

          expect(page).to have_button 'Merge when pipeline succeeds'
          expect(page).not_to have_button '.js-merge-moment'
        end
      end

      context 'when CI failed' do
        let(:status) { :failed }

        it 'does not allow MR to be merged' do
          visit project_merge_request_path(project, merge_request)

          wait_for_requests

          expect(page).not_to have_button('Merge', exact: true)
          expect(page).to have_content('Merge blocked: pipeline must succeed. Push a commit that fixes the failure or learn about other solutions.')
        end
      end

      context 'when CI canceled' do
        let(:status) { :canceled }

        it 'does not allow MR to be merged' do
          visit project_merge_request_path(project, merge_request)

          wait_for_requests

          expect(page).not_to have_button('Merge', exact: true)
          expect(page).to have_content('Merge blocked: pipeline must succeed. Push a commit that fixes the failure or learn about other solutions.')
        end
      end

      context 'when CI succeeded' do
        let(:status) { :success }

        it 'allows MR to be merged' do
          visit project_merge_request_path(project, merge_request)

          wait_for_requests

          expect(page).to have_button('Merge', exact: true)
        end
      end

      context 'when CI skipped' do
        let(:status) { :skipped }

        it 'does not allow MR to be merged' do
          visit project_merge_request_path(project, merge_request)

          wait_for_requests

          expect(page).not_to have_button('Merge', exact: true)
        end
      end
    end

    context 'when merge requests can only be merged if the pipeline succeeds with auto_merge_labels_mr_widget on' do
      before do
        project.update_attribute(:only_allow_merge_if_pipeline_succeeds, true)

        stub_feature_flags(auto_merge_labels_mr_widget: true)
      end

      context 'when CI is running' do
        let(:status) { :running }

        it 'does not allow to merge immediately' do
          visit project_merge_request_path(project, merge_request)

          wait_for_requests

          expect(page).to have_button 'Set to auto-merge'
          expect(page).not_to have_button '.js-merge-moment'
        end
      end

      context 'when CI failed' do
        let(:status) { :failed }

        it 'does not allow MR to be merged' do
          visit project_merge_request_path(project, merge_request)

          wait_for_requests

          expect(page).not_to have_button('Merge', exact: true)
          expect(page).to have_content('Merge blocked: pipeline must succeed. Push a commit that fixes the failure or learn about other solutions.')
        end
      end

      context 'when CI canceled' do
        let(:status) { :canceled }

        it 'does not allow MR to be merged' do
          visit project_merge_request_path(project, merge_request)

          wait_for_requests

          expect(page).not_to have_button('Merge', exact: true)
          expect(page).to have_content('Merge blocked: pipeline must succeed. Push a commit that fixes the failure or learn about other solutions.')
        end
      end

      context 'when CI succeeded' do
        let(:status) { :success }

        it 'allows MR to be merged' do
          visit project_merge_request_path(project, merge_request)

          wait_for_requests

          expect(page).to have_button('Merge', exact: true)
        end
      end

      context 'when CI skipped' do
        let(:status) { :skipped }

        it 'does not allow MR to be merged' do
          visit project_merge_request_path(project, merge_request)

          wait_for_requests

          expect(page).not_to have_button('Merge', exact: true)
        end
      end
    end

    context 'when merge requests can be merged when the build failed' do
      before do
        project.update_attribute(:only_allow_merge_if_pipeline_succeeds, false)

        stub_feature_flags(auto_merge_labels_mr_widget: false)
      end

      context 'when CI is running' do
        let(:status) { :running }

        it 'allows MR to be merged immediately' do
          visit project_merge_request_path(project, merge_request)

          wait_for_requests

          expect(page).to have_button 'Merge when pipeline succeeds'

          page.find('.js-merge-moment').click
          expect(page).to have_content 'Merge immediately'
        end
      end

      context 'when CI failed' do
        let(:status) { :failed }

        it 'allows MR to be merged' do
          visit project_merge_request_path(project, merge_request)

          wait_for_requests
          page.within('.mr-state-widget') do
            expect(page).to have_button 'Merge'
          end
        end
      end

      context 'when CI succeeded' do
        let(:status) { :success }

        it 'allows MR to be merged' do
          visit project_merge_request_path(project, merge_request)

          wait_for_requests

          page.within('.mr-state-widget') do
            expect(page).to have_button 'Merge'
          end
        end
      end
    end

    context 'when merge requests can be merged when the build failed with auto_merge_labels_mr_widget on' do
      before do
        project.update_attribute(:only_allow_merge_if_pipeline_succeeds, false)

        stub_feature_flags(auto_merge_labels_mr_widget: true)
      end

      context 'when CI is running' do
        let(:status) { :running }

        it 'allows MR to be merged immediately' do
          visit project_merge_request_path(project, merge_request)

          wait_for_requests

          expect(page).to have_button 'Set to auto-merge'

          page.find('.js-merge-moment').click
          expect(page).to have_content 'Merge immediately'
        end
      end

      context 'when CI failed' do
        let(:status) { :failed }

        it 'allows MR to be merged' do
          visit project_merge_request_path(project, merge_request)

          wait_for_requests
          page.within('.mr-state-widget') do
            expect(page).to have_button 'Merge'
          end
        end
      end

      context 'when CI succeeded' do
        let(:status) { :success }

        it 'allows MR to be merged' do
          visit project_merge_request_path(project, merge_request)

          wait_for_requests

          page.within('.mr-state-widget') do
            expect(page).to have_button 'Merge'
          end
        end
      end
    end
  end
end
