# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User merges when pipeline succeeds', :js, feature_category: :code_review_workflow do
  let(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }
  let(:merge_request) do
    create(:merge_request_with_diffs, source_project: project,
                                      author: user,
                                      title: 'Bug NS-04',
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
    end

    describe 'enabling set auto-merge' do
      shared_examples 'auto-merge activator' do
        it 'activates the set auto-merge feature' do
          click_button "Set auto-merge"

          expect(page).to have_content "Set by #{user.name} to be merged automatically when the pipeline succeeds"
          expect(page).to have_content "Source branch will not be deleted"
          expect(page).to have_selector ".js-cancel-auto-merge"
          visit project_merge_request_path(project, merge_request) # Needed to refresh the page
          expect(page).to have_content /enabled an automatic merge when the pipeline for \h{8} succeeds/i
        end
      end

      context "when enabled immediately" do
        it_behaves_like 'auto-merge activator'
      end

      context 'when enabled after pipeline status changed', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/258667' do
        before do
          pipeline.run!

          # We depend on merge request widget being reloaded
          # so we have to wait for asynchronous call to reload it
          # and have_content expectation handles that.
          #
          expect(page).to have_content "Pipeline ##{pipeline.id} running"
        end

        it_behaves_like 'auto-merge activator'
      end

      context 'when enabled after it was previously canceled' do
        before do
          click_button "Set auto-merge"

          wait_for_requests

          click_button "Cancel auto-merge"

          wait_for_requests

          expect(page).to have_content 'Set auto-merge'
        end

        it_behaves_like 'auto-merge activator'
      end

      context 'when it was enabled and then canceled' do
        let(:merge_request) do
          create(:merge_request_with_diffs,
                 :merge_when_pipeline_succeeds,
                   source_project: project,
                   title: 'Bug NS-04',
                   author: user,
                   merge_user: user)
        end

        before do
          merge_request.merge_params['force_remove_source_branch'] = '0'
          merge_request.save!
          click_button "Cancel auto-merge"
        end

        it_behaves_like 'auto-merge activator'
      end
    end
  end

  context 'when set auto-merge is enabled' do
    let(:merge_request) do
      create(:merge_request_with_diffs, :simple, :merge_when_pipeline_succeeds,
        source_project: project,
        author: user,
        merge_user: user,
        title: 'MepMep')
    end

    let!(:build) do
      create(:ci_build, pipeline: pipeline)
    end

    before do
      sign_in user
      visit project_merge_request_path(project, merge_request)
    end

    it 'allows to cancel the automatic merge' do
      click_button "Cancel auto-merge"

      expect(page).to have_button "Set auto-merge"

      refresh

      expect(page).to have_content "canceled the automatic merge"
    end

    context 'when pipeline succeeds' do
      before do
        build.success
        refresh
      end

      it 'merges merge request', :sidekiq_might_not_need_inline do
        expect(page).to have_content 'Changes merged'
        expect(merge_request.reload).to be_merged
      end
    end

    context 'view merge request with set auto-merge enabled but automatically merge fails' do
      before do
        merge_request.update!(
          merge_user: merge_request.author,
          merge_error: 'Something went wrong'
        )
        refresh
      end

      it 'shows information about the merge error' do
        # Wait for the `ci_status` and `merge_check` requests
        wait_for_requests

        page.within('.mr-state-widget') do
          expect(page).to have_content('Something went wrong. Try again.')
        end
      end
    end

    context 'view merge request with set auto-merge enabled but automatically merge fails' do
      before do
        merge_request.update!(
          merge_user: merge_request.author,
          merge_error: 'Something went wrong.'
        )
        refresh
      end

      it 'shows information about the merge error' do
        # Wait for the `ci_status` and `merge_check` requests
        wait_for_requests

        page.within('.mr-state-widget') do
          expect(page).to have_content('Something went wrong. Try again.')
        end
      end
    end
  end

  context 'when pipeline is not active' do
    it 'does not allow to enable merge when pipeline succeeds' do
      visit project_merge_request_path(project, merge_request)

      expect(page).not_to have_link 'Set auto-merge'
    end
  end
end
