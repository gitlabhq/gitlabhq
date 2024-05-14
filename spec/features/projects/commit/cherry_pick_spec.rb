# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Cherry-pick Commits', :js, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:sha) { '7d3b0f7cff5f37573aea97cebfd5692ea1689924' }

  let!(:project) { create_default(:project, :repository, namespace: user.namespace) }
  let(:master_pickable_commit) { project.commit(sha) }

  before do
    sign_in(user)
  end

  context 'when clicking cherry-pick from the dropdown for a commit on pipelines tab' do
    it 'launches the modal form' do
      create(:ci_empty_pipeline, sha: sha)
      visit project_commit_path(project, master_pickable_commit.id)
      click_link 'Pipelines'

      open_modal

      page.within(modal_selector) do
        expect(page).to have_content('Cherry-pick this commit')
      end
    end
  end

  context 'when starting from the commit tab' do
    before do
      visit project_commit_path(project, master_pickable_commit.id)
    end

    context 'when cherry-picking a commit' do
      specify do
        cherry_pick_commit

        expect(page).to have_content('The commit has been successfully cherry-picked into master.')
      end
    end

    context 'when cherry-picking a merge commit' do
      specify do
        cherry_pick_commit

        expect(page).to have_content('The commit has been successfully cherry-picked into master.')
      end
    end

    context 'when cherry-picking a commit that was previously cherry-picked' do
      specify do
        cherry_pick_commit

        visit project_commit_path(project, master_pickable_commit.id)

        cherry_pick_commit

        expect(page).to have_content('Commit cherry-pick failed:')
      end
    end

    context 'when cherry-picking a commit in a new merge request' do
      specify do
        cherry_pick_commit(create_merge_request: true)

        expect(page).to have_content("The commit has been successfully cherry-picked into cherry-pick-#{master_pickable_commit.short_id}. You can now submit a merge request to get this change into the original branch.")
        expect(page).to have_content("From cherry-pick-#{master_pickable_commit.short_id} into master")
      end
    end

    context 'when I cherry-picking a commit from a different branch' do
      specify do
        open_modal

        page.within(modal_selector) do
          click_button 'master'
        end

        page.within(modal_selector) do
          within_testid('base-dropdown-menu') do
            fill_in 'Search branches', with: 'feature'

            wait_for_requests

            find_by_testid('listbox-item-feature').click
          end
        end

        submit_cherry_pick

        expect(page).to have_content('The commit has been successfully cherry-picked into feature.')
      end
    end

    context 'when the project is archived' do
      let(:project) { create(:project, :repository, :archived, namespace: user.namespace) }

      it 'does not show the cherry-pick button' do
        open_dropdown

        expect(page).not_to have_text("Cherry-pick")
      end
    end
  end

  def cherry_pick_commit(create_merge_request: false)
    open_modal

    submit_cherry_pick(create_merge_request: create_merge_request)
  end

  def open_dropdown
    find(dropdown_selector).click
  end

  def open_modal
    open_dropdown

    page.within(dropdown_selector) do
      click_button 'Cherry-pick'
    end
  end

  def submit_cherry_pick(create_merge_request: false)
    page.within(modal_selector) do
      uncheck('create_merge_request') unless create_merge_request
      click_button('Cherry-pick')
    end
  end

  def dropdown_selector
    '[data-testid="commit-options-dropdown"]'
  end

  def modal_selector
    '[data-testid="modal-commit"]'
  end
end
