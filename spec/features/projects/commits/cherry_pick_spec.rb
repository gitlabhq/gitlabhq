require 'spec_helper'

describe 'Cherry-pick Commits' do
  let(:project) { create(:project) }
  let(:master_pickable_commit)  { project.commit('7d3b0f7cff5f37573aea97cebfd5692ea1689924') }
  let(:master_pickable_merge)  { project.commit('e56497bb5f03a90a51293fc6d516788730953899') }

  before do
    login_as :user
    project.team << [@user, :master]
    visit namespace_project_commits_path(project.namespace, project, project.repository.root_ref, { limit: 5 })
  end

  context "I cherry-pick a commit" do
    it do
      visit namespace_project_commit_path(project.namespace, project, master_pickable_commit.id)
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
      visit namespace_project_commit_path(project.namespace, project, master_pickable_merge.id)
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
      visit namespace_project_commit_path(project.namespace, project, master_pickable_commit.id)
      find("a[href='#modal-cherry-pick-commit']").click
      page.within('#modal-cherry-pick-commit') do
        uncheck 'create_merge_request'
        click_button 'Cherry-pick'
      end
      visit namespace_project_commit_path(project.namespace, project, master_pickable_commit.id)
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
      visit namespace_project_commit_path(project.namespace, project, master_pickable_commit.id)
      find("a[href='#modal-cherry-pick-commit']").click
      page.within('#modal-cherry-pick-commit') do
        click_button 'Cherry-pick'
      end
      expect(page).to have_content('The commit has been successfully cherry-picked. You can now submit a merge request to get this change into the original branch.')
    end
  end
end
