require 'spec_helper'

describe 'User reverts a commit', :js do
  include RepoHelpers

  let(:project) { create(:project, :repository, namespace: user.namespace) }
  let(:user) { create(:user) }

  before do
    sign_in(user)

    visit(project_commit_path(project, sample_commit.id))

    find('.header-action-buttons .dropdown').click
    find('a[href="#modal-revert-commit"]').click
  end

  context 'without creating a new merge request' do
    before do
      page.within('#modal-revert-commit') do
        uncheck('create_merge_request')
        click_button('Revert')
      end
    end

    it 'reverts a commit' do
      expect(page).to have_content('The commit has been successfully reverted.')
    end

    it 'does not revert a previously reverted commit' do
      # Visit the comment again once it was reverted.
      visit project_commit_path(project, sample_commit.id)

      find('.header-action-buttons .dropdown').click
      find('a[href="#modal-revert-commit"]').click

      page.within('#modal-revert-commit') do
        uncheck('create_merge_request')
        click_button('Revert')
      end

      expect(page).to have_content('Sorry, we cannot revert this commit automatically.')
    end
  end

  context 'with creating a new merge request' do
    it 'reverts a commit' do
      page.within('#modal-revert-commit') do
        click_button('Revert')
      end

      expect(page).to have_content('The commit has been successfully reverted. You can now submit a merge request to get this change into the original branch.')
      expect(page).to have_content("From revert-#{Commit.truncate_sha(sample_commit.id)} into master")
    end
  end
end
