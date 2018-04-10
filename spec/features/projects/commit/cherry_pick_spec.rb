require 'spec_helper'

describe 'Cherry-pick Commits' do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, :repository, namespace: group) }
  let(:master_pickable_commit)  { project.commit('7d3b0f7cff5f37573aea97cebfd5692ea1689924') }
  let(:master_pickable_merge)  { project.commit('e56497bb5f03a90a51293fc6d516788730953899') }

  before do
    sign_in(user)
    project.add_master(user)
    visit project_commit_path(project, master_pickable_commit.id)
  end

  context "I cherry-pick a commit" do
    it do
      find("a[href='#modal-cherry-pick-commit']").click
      expect(page).not_to have_content('v1.0.0') # Only branches, not tags
      page.within('#modal-cherry-pick-commit') do
        uncheck 'create_merge_request'
        click_button 'Cherry-pick'
      end
      expect(page).to have_content('The commit has been successfully cherry-picked.')
    end
  end

  context "I cherry-pick a merge commit" do
    it do
      find("a[href='#modal-cherry-pick-commit']").click
      page.within('#modal-cherry-pick-commit') do
        uncheck 'create_merge_request'
        click_button 'Cherry-pick'
      end
      expect(page).to have_content('The commit has been successfully cherry-picked.')
    end
  end

  context "I cherry-pick a commit that was previously cherry-picked" do
    it do
      find("a[href='#modal-cherry-pick-commit']").click
      page.within('#modal-cherry-pick-commit') do
        uncheck 'create_merge_request'
        click_button 'Cherry-pick'
      end
      visit project_commit_path(project, master_pickable_commit.id)
      find("a[href='#modal-cherry-pick-commit']").click
      page.within('#modal-cherry-pick-commit') do
        uncheck 'create_merge_request'
        click_button 'Cherry-pick'
      end
      expect(page).to have_content('Sorry, we cannot cherry-pick this commit automatically.')
    end
  end

  context "I cherry-pick a commit in a new merge request" do
    it do
      find("a[href='#modal-cherry-pick-commit']").click
      page.within('#modal-cherry-pick-commit') do
        click_button 'Cherry-pick'
      end
      expect(page).to have_content('The commit has been successfully cherry-picked. You can now submit a merge request to get this change into the original branch.')
      expect(page).to have_content("From cherry-pick-#{master_pickable_commit.short_id} into master")
    end
  end

  context "I cherry-pick a commit from a different branch", :js do
    it do
      find('.header-action-buttons a.dropdown-toggle').click
      find(:css, "a[href='#modal-cherry-pick-commit']").click

      page.within('#modal-cherry-pick-commit') do
        click_button 'master'
      end

      wait_for_requests

      page.within('#modal-cherry-pick-commit .dropdown-menu') do
        find('.dropdown-input input').set('feature')
        wait_for_requests
        click_link "feature"
      end

      page.within('#modal-cherry-pick-commit') do
        uncheck 'create_merge_request'
        click_button 'Cherry-pick'
      end

      expect(page).to have_content('The commit has been successfully cherry-picked.')
    end
  end

  context 'when the project is archived' do
    let(:project) { create(:project, :repository, namespace: group, archived: true) }

    it 'does not show the cherry-pick link' do
      find('.header-action-buttons a.dropdown-toggle').click

      expect(page).not_to have_css("a[href='#modal-cherry-pick-commit']")
    end
  end
end
