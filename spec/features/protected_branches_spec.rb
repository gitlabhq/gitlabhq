require 'spec_helper'

feature 'Projected Branches', feature: true, js: true do
  include WaitForAjax

  let(:user) { create(:user, :admin) }
  let(:project) { create(:project) }

  before { login_as(user) }

  def set_protected_branch_name(branch_name)
    find(".js-protected-branch-select").click
    find(".dropdown-input-field").set(branch_name)
    click_on("Create wildcard #{branch_name}")
  end

  describe "explicit protected branches" do
    it "allows creating explicit protected branches" do
      visit namespace_project_protected_branches_path(project.namespace, project)
      set_protected_branch_name('some-branch')
      click_on "Protect"

      within(".protected-branches-list") { expect(page).to have_content('some-branch') }
      expect(ProtectedBranch.count).to eq(1)
      expect(ProtectedBranch.last.name).to eq('some-branch')
    end

    it "displays the last commit on the matching branch if it exists" do
      commit = create(:commit, project: project)
      project.repository.add_branch(user, 'some-branch', commit.id)

      visit namespace_project_protected_branches_path(project.namespace, project)
      set_protected_branch_name('some-branch')
      click_on "Protect"

      within(".protected-branches-list") { expect(page).to have_content(commit.id[0..7]) }
    end

    it "displays an error message if the named branch does not exist" do
      visit namespace_project_protected_branches_path(project.namespace, project)
      set_protected_branch_name('some-branch')
      click_on "Protect"

      within(".protected-branches-list") { expect(page).to have_content('branch was removed') }
    end
  end

  describe "wildcard protected branches" do
    it "allows creating protected branches with a wildcard" do
      visit namespace_project_protected_branches_path(project.namespace, project)
      set_protected_branch_name('*-stable')
      click_on "Protect"

      within(".protected-branches-list") { expect(page).to have_content('*-stable') }
      expect(ProtectedBranch.count).to eq(1)
      expect(ProtectedBranch.last.name).to eq('*-stable')
    end

    it "displays the number of matching branches" do
      project.repository.add_branch(user, 'production-stable', 'master')
      project.repository.add_branch(user, 'staging-stable', 'master')

      visit namespace_project_protected_branches_path(project.namespace, project)
      set_protected_branch_name('*-stable')
      click_on "Protect"

      within(".protected-branches-list") { expect(page).to have_content("2 matching branches") }
    end

    it "displays all the branches matching the wildcard" do
      project.repository.add_branch(user, 'production-stable', 'master')
      project.repository.add_branch(user, 'staging-stable', 'master')
      project.repository.add_branch(user, 'development', 'master')

      visit namespace_project_protected_branches_path(project.namespace, project)
      set_protected_branch_name('*-stable')
      click_on "Protect"

      visit namespace_project_protected_branches_path(project.namespace, project)
      click_on "2 matching branches"

      within(".protected-branches-list") do
        expect(page).to have_content("production-stable")
        expect(page).to have_content("staging-stable")
        expect(page).not_to have_content("development")
      end
    end
  end

  describe "access control" do
    ProtectedBranch::PushAccessLevel.human_access_levels.each do |(access_type_id, access_type_name)|
      it "allows creating protected branches that #{access_type_name} can push to" do
        visit namespace_project_protected_branches_path(project.namespace, project)
        set_protected_branch_name('master')
        within('.new_protected_branch') do
          find(".js-allowed-to-push").click
          within(".dropdown.open .dropdown-menu") { click_on access_type_name }
        end
        click_on "Protect"

        expect(ProtectedBranch.count).to eq(1)
        expect(ProtectedBranch.last.push_access_levels.first.access_level).to eq(access_type_id)
      end

      it "allows updating protected branches so that #{access_type_name} can push to them" do
        visit namespace_project_protected_branches_path(project.namespace, project)
        set_protected_branch_name('master')
        click_on "Protect"

        expect(ProtectedBranch.count).to eq(1)

        within(".protected-branches-list") do
          find(".js-allowed-to-push").click
          within('.js-allowed-to-push-container') { click_on access_type_name }
        end

        wait_for_ajax
        expect(ProtectedBranch.last.push_access_levels.first.access_level).to eq(access_type_id)
      end
    end

    ProtectedBranch::MergeAccessLevel.human_access_levels.each do |(access_type_id, access_type_name)|
      it "allows creating protected branches that #{access_type_name} can merge to" do
        visit namespace_project_protected_branches_path(project.namespace, project)
        set_protected_branch_name('master')
        within('.new_protected_branch') do
          find(".js-allowed-to-merge").click
          within(".dropdown.open .dropdown-menu") { click_on access_type_name }
        end
        click_on "Protect"

        expect(ProtectedBranch.count).to eq(1)
        expect(ProtectedBranch.last.merge_access_levels.first.access_level).to eq(access_type_id)
      end

      it "allows updating protected branches so that #{access_type_name} can merge to them" do
        visit namespace_project_protected_branches_path(project.namespace, project)
        set_protected_branch_name('master')
        click_on "Protect"

        expect(ProtectedBranch.count).to eq(1)

        within(".protected-branches-list") do
          find(".js-allowed-to-merge").click
          within('.js-allowed-to-merge-container') { click_on access_type_name }
        end

        wait_for_ajax
        expect(ProtectedBranch.last.merge_access_levels.first.access_level).to eq(access_type_id)
      end
    end
  end
end
