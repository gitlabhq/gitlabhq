# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User reverts a commit', :js do
  include RepoHelpers

  let_it_be(:user) { create(:user) }

  let!(:project) { create_default(:project, :repository, namespace: user.namespace) }

  before do
    sign_in(user)
  end

  context 'when clicking revert from the dropdown for a commit on pipelines tab' do
    it 'launches the modal and is able to submit the revert' do
      sha = '7d3b0f7cff5f37573aea97cebfd5692ea1689924'
      create(:ci_empty_pipeline, sha: sha)
      visit project_commit_path(project, project.commit(sha).id)
      click_link 'Pipelines'

      open_modal

      page.within(modal_selector) do
        expect(page).to have_content('Revert this commit')
      end
    end
  end

  context 'when starting from the commit tab' do
    before do
      visit project_commit_path(project, sample_commit.id)
    end

    context 'without creating a new merge request' do
      it 'reverts a commit' do
        revert_commit

        expect(page).to have_content('The commit has been successfully reverted.')
      end

      it 'does not revert a previously reverted commit' do
        revert_commit
        # Visit the comment again once it was reverted.
        visit project_commit_path(project, sample_commit.id)

        revert_commit

        expect(page).to have_content('Sorry, we cannot revert this commit automatically.')
      end
    end

    context 'with creating a new merge request' do
      it 'reverts a commit' do
        revert_commit(create_merge_request: true)

        expect(page).to have_content('The commit has been successfully reverted. You can now submit a merge request to get this change into the original branch.')
        expect(page).to have_content("From revert-#{Commit.truncate_sha(sample_commit.id)} into master")
      end
    end

    context 'when the project is archived' do
      let(:project) { create(:project, :repository, :archived, namespace: user.namespace) }

      it 'does not show the revert button' do
        open_dropdown

        expect(page).not_to have_button('Revert')
      end
    end
  end

  def revert_commit(create_merge_request: false)
    open_modal

    page.within(modal_selector) do
      uncheck('create_merge_request') unless create_merge_request
      click_button 'Revert'
    end
  end

  def open_dropdown
    find(dropdown_selector).click
  end

  def open_modal
    open_dropdown

    page.within(dropdown_selector) do
      click_button 'Revert'
    end
  end

  def dropdown_selector
    '[data-testid="commit-options-dropdown"]'
  end

  def modal_selector
    '[data-testid="modal-commit"]'
  end
end
