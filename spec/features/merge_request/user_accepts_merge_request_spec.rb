# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User accepts a merge request', :js, :sidekiq_might_not_need_inline, feature_category: :code_review_workflow do
  let(:merge_request) { create(:merge_request, :simple, source_project: project) }
  let(:project) { create(:project, :public, :repository) }
  let(:user) { create(:user) }

  before do
    project.add_developer(user)
    sign_in(user)
  end

  context 'presents merged merge request content' do
    it 'when merge method is set to merge commit' do
      visit(merge_request_path(merge_request))

      click_merge_button

      puts merge_request.short_merged_commit_sha

      expect(page).to have_content("Changes merged into #{merge_request.target_branch} with #{merge_request.short_merged_commit_sha}")
    end

    context 'when merge method is set to fast-forward merge' do
      let(:project) { create(:project, :public, :repository, merge_requests_ff_only_enabled: true) }

      it 'accepts a merge request with rebase and merge' do
        merge_request = create(:merge_request, :rebased, source_project: project)

        visit(merge_request_path(merge_request))

        click_merge_button

        expect(page).to have_content("Changes merged into #{merge_request.target_branch} with #{merge_request.short_merged_commit_sha}")
      end

      it 'accepts a merge request with squash and merge' do
        merge_request = create(:merge_request, :rebased, source_project: project, squash: true)

        visit(merge_request_path(merge_request))

        click_merge_button

        expect(page).to have_content("Changes merged into #{merge_request.target_branch} with #{merge_request.short_merged_commit_sha}")
      end
    end
  end

  context 'with removing the source branch' do
    before do
      visit(merge_request_path(merge_request))
    end

    it 'accepts a merge request' do
      check('Delete source branch')
      click_merge_button

      expect(page).to have_content('Changes merged into')
      expect(page).not_to have_selector('.js-remove-branch-button')

      # Wait for View Resource requests to complete so they don't blow up if they are
      # only handled after `DatabaseCleaner` has already run.
      wait_for_requests
    end
  end

  context 'without removing the source branch' do
    before do
      visit(merge_request_path(merge_request))
    end

    it 'accepts a merge request', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/471380' do
      click_merge_button

      expect(page).to have_content('Changes merged into')
      expect(page).to have_selector('.js-remove-branch-button')

      # Wait for View Resource requests to complete so they don't blow up if they are
      # only handled after `DatabaseCleaner` has already run
      wait_for_requests
    end
  end

  context 'when a URL has an anchor' do
    before do
      visit(merge_request_path(merge_request, anchor: 'note_123'))
    end

    it 'accepts a merge request', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/462685' do
      check('Delete source branch')
      click_merge_button

      expect(page).to have_content('Changes merged into')
      expect(page).not_to have_selector('.js-remove-branch-button')

      # Wait for View Resource requests to complete so they don't blow up if they are
      # only handled after `DatabaseCleaner` has already run
      wait_for_requests
    end
  end

  context 'when modifying the merge commit message' do
    before do
      merge_request.mark_as_mergeable

      visit(merge_request_path(merge_request))
    end

    it 'accepts a merge request' do
      find_by_testid('widget_edit_commit_message').click
      fill_in('merge-message-edit', with: 'wow such merge')

      click_merge_button

      expect(page).to have_selector('.gl-badge', text: 'Merged')
    end
  end

  def click_merge_button
    page.within('.mr-state-widget') do
      click_button 'Merge'
    end
  end
end
