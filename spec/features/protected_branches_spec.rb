require 'spec_helper'

feature 'Projected Branches', feature: true, js: true do
  include WaitForAjax

  let(:user) { create(:user, :admin) }
  let(:project) { create(:project) }

  before { login_as(user) }

  def set_allowed_to(operation, option = 'Masters')
    find(".js-allowed-to-#{operation}").click
    wait_for_ajax
    click_on option
    find(".js-allowed-to-#{operation}").click # needed to submit form in some cases
  end

  def set_protected_branch_name(branch_name)
    find(".js-protected-branch-select").click
    find(".dropdown-input-field").set(branch_name)
    click_on("Create wildcard #{branch_name}")
  end

  describe "explicit protected branches" do
    it "allows creating explicit protected branches" do
      visit namespace_project_protected_branches_path(project.namespace, project)
      set_protected_branch_name('some-branch')
      set_allowed_to('merge')
      set_allowed_to('push')
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
      set_allowed_to('merge')
      set_allowed_to('push')
      click_on "Protect"

      within(".protected-branches-list") { expect(page).to have_content(commit.id[0..7]) }
    end

    it "displays an error message if the named branch does not exist" do
      visit namespace_project_protected_branches_path(project.namespace, project)
      set_protected_branch_name('some-branch')
      set_allowed_to('merge')
      set_allowed_to('push')
      click_on "Protect"

      within(".protected-branches-list") { expect(page).to have_content('branch was removed') }
    end
  end

  describe "wildcard protected branches" do
    it "allows creating protected branches with a wildcard" do
      visit namespace_project_protected_branches_path(project.namespace, project)
      set_protected_branch_name('*-stable')
      set_allowed_to('merge')
      set_allowed_to('push')
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
      set_allowed_to('merge')
      set_allowed_to('push')
      click_on "Protect"

      within(".protected-branches-list") { expect(page).to have_content("2 matching branches") }
    end

    it "displays all the branches matching the wildcard" do
      project.repository.add_branch(user, 'production-stable', 'master')
      project.repository.add_branch(user, 'staging-stable', 'master')
      project.repository.add_branch(user, 'development', 'master')

      visit namespace_project_protected_branches_path(project.namespace, project)
      set_protected_branch_name('*-stable')
      set_allowed_to('merge')
      set_allowed_to('push')
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
        set_allowed_to('merge')
        set_allowed_to('push', access_type_name)
        click_on "Protect"

        expect(ProtectedBranch.count).to eq(1)
        expect(ProtectedBranch.last.push_access_levels.map(&:access_level)).to eq([access_type_id])
      end

      it "allows updating protected branches so that #{access_type_name} can push to them" do
        authorized_user = create(:user)
        project.team << [authorized_user, :developer]

        visit namespace_project_protected_branches_path(project.namespace, project)
        set_protected_branch_name('master')
        set_allowed_to('merge')
        set_allowed_to('push', authorized_user.name)
        click_on "Protect"

        expect(ProtectedBranch.count).to eq(1)

        within(".js-protected-branch-edit-form") do
          set_allowed_to('push', access_type_name)
        end

        wait_for_ajax

        expect(ProtectedBranch.last.push_access_levels.map(&:access_level)).to include(access_type_id)
      end
    end

    ProtectedBranch::MergeAccessLevel.human_access_levels.each do |(access_type_id, access_type_name)|
      it "allows creating protected branches that #{access_type_name} can merge to" do
        visit namespace_project_protected_branches_path(project.namespace, project)
        set_protected_branch_name('master')
        set_allowed_to('push')
        set_allowed_to('merge', access_type_name)
        click_on "Protect"

        expect(ProtectedBranch.count).to eq(1)
        expect(ProtectedBranch.last.merge_access_levels.map(&:access_level)).to eq([access_type_id])
      end

      it "allows updating protected branches so that #{access_type_name} can merge to them", focus: true do
        authorized_user = create(:user)
        project.team << [authorized_user, :developer]

        visit namespace_project_protected_branches_path(project.namespace, project)
        set_protected_branch_name('master')
        set_allowed_to('merge', authorized_user.name)
        set_allowed_to('push')
        click_on "Protect"

        expect(ProtectedBranch.count).to eq(1)

        within(".js-protected-branch-edit-form") do
          set_allowed_to('merge', access_type_name)
        end

        wait_for_ajax
        expect(ProtectedBranch.last.merge_access_levels.map(&:access_level)).to include(access_type_id)
      end
    end

    context "while restricting access to a specific user" do
      let(:authorized_user) { create(:user) }

      before { project.team << [authorized_user, :developer] }

      git_operations = ['push', 'merge']

      git_operations.each_with_index do |git_operation_type, i|
        alt_git_operation = git_operations[(i +1) %2] # Will return the next or previous operation

        it "allows creating protected branches that a specific user can #{git_operation_type} to" do
          visit namespace_project_protected_branches_path(project.namespace, project)
          set_protected_branch_name('master')
          within('.new_protected_branch') do
            find(".js-allowed-to-#{git_operation_type}").click
            click_on authorized_user.name
          end
          set_allowed_to(alt_git_operation)

          perform_enqueued_jobs { click_on "Protect" }

          within '.js-protected-branch-edit-form' do
            find(".js-allowed-to-#{git_operation_type}").click
            wait_for_ajax
            expect(page).to have_selector('a.is-active', text: authorized_user.name)
          end
        end

        it "allows updating a protected branch so that a specific user can #{git_operation_type} to it" do
          visit namespace_project_protected_branches_path(project.namespace, project)
          set_protected_branch_name('master')
          set_allowed_to('merge')
          set_allowed_to('push')
          click_on "Protect"

          within '.js-protected-branch-edit-form' do
            set_allowed_to(git_operation_type, authorized_user.name)
          end

          wait_for_ajax

          access_levels = ProtectedBranch.first.send("#{git_operation_type}_access_levels".to_sym)
          expect(access_levels.last.user).to eq(authorized_user)
        end

        it "allows deleting a user-specific access level" do
          other_authorized_user = create(:user)
          project.team << [other_authorized_user, :developer]

          visit namespace_project_protected_branches_path(project.namespace, project)
          set_protected_branch_name('master')

          within('.new_protected_branch') do
            # First authorized user has access
            set_allowed_to(git_operation_type, authorized_user.name)
            set_allowed_to(alt_git_operation)
          end
          click_on "Protect"
          
          within '.js-protected-branch-edit-form' do
            # Second authorized user has access
            set_allowed_to(git_operation_type, other_authorized_user.name)

            # Remove first user's access
            find(".js-allowed-to-#{git_operation_type}").click
            wait_for_ajax
            click_on other_authorized_user.name
            find(".js-allowed-to-#{git_operation_type}").click # Close to submit the form
          end

          access_levels = ProtectedBranch.first.send("#{git_operation_type}_access_levels".to_sym)

          expect(access_levels.count).to eq(2)
          expect(access_levels.last.user).to eq(other_authorized_user)
        end
      end
    end
  end
end
