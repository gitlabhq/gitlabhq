require 'spec_helper'

describe 'User accepts a merge request', :js do
  let(:merge_request) { create(:merge_request, :with_diffs, :simple, source_project: project) }
  let(:project) { create(:project, :public, :repository) }
  let(:user) { create(:user) }

  before do
    project.add_developer(user)
    sign_in(user)
  end

  context 'with removing the source branch' do
    before do
      visit(merge_request_path(merge_request))
    end

    it 'accepts a merge request' do
      check('Remove source branch')
      click_button('Merge')

      expect(page).to have_content('The changes were merged into')
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

    it 'accepts a merge request' do
      click_button('Merge')

      expect(page).to have_content('The changes were merged into')
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

    it 'accepts a merge request' do
      check('Remove source branch')
      click_button('Merge')

      expect(page).to have_content('The changes were merged into')
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
      click_button('Modify commit message')
      fill_in('Commit message', with: 'wow such merge')

      click_button('Merge')

      page.within('.status-box') do
        expect(page).to have_content('Merged')
      end
    end
  end
end
