# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Protected Branches', :js do
  include ProtectedBranchHelpers

  let(:user) { create(:user) }
  let(:admin) { create(:admin) }
  let(:project) { create(:project, :repository) }

  context 'logged in as developer' do
    before do
      project.add_developer(user)
      sign_in(user)
    end

    describe 'Delete protected branch' do
      before do
        create(:protected_branch, project: project, name: 'fix')
        expect(ProtectedBranch.count).to eq(1)
      end

      it 'does not allow developer to remove protected branch' do
        visit project_branches_path(project)

        find('input[data-testid="branch-search"]').set('fix')
        find('input[data-testid="branch-search"]').native.send_keys(:enter)

        expect(page).to have_button('Only a project maintainer or owner can delete a protected branch', disabled: true)
      end

      context 'when feature flag :delete_branch_confirmation_modals is disabled' do
        before do
          stub_feature_flags(delete_branch_confirmation_modals: false)
        end

        it 'does not allow developer to remove protected branch' do
          visit project_branches_path(project)

          find('input[data-testid="branch-search"]').set('fix')
          find('input[data-testid="branch-search"]').native.send_keys(:enter)

          expect(page).to have_selector('button[data-testid="remove-protected-branch"][disabled]')
        end
      end
    end
  end

  context 'logged in as maintainer' do
    before do
      project.add_maintainer(user)
      sign_in(user)
    end

    describe 'Delete protected branch' do
      before do
        create(:protected_branch, project: project, name: 'fix')
        expect(ProtectedBranch.count).to eq(1)
      end

      it 'removes branch after modal confirmation' do
        visit project_branches_path(project)

        find('input[data-testid="branch-search"]').set('fix')
        find('input[data-testid="branch-search"]').native.send_keys(:enter)

        expect(page).to have_content('fix')
        expect(find('.all-branches')).to have_selector('li', count: 1)

        expect(page).to have_button('Delete protected branch', disabled: false)

        page.find('.js-delete-branch-button').click
        fill_in 'delete_branch_input', with: 'fix'
        click_button 'Yes, delete protected branch'

        find('input[data-testid="branch-search"]').set('fix')
        find('input[data-testid="branch-search"]').native.send_keys(:enter)

        expect(page).to have_content('No branches to show')
      end

      context 'when the feature flag :delete_branch_confirmation_modals is disabled' do
        before do
          stub_feature_flags(delete_branch_confirmation_modals: false)
        end

        it 'removes branch after modal confirmation' do
          visit project_branches_path(project)

          find('input[data-testid="branch-search"]').set('fix')
          find('input[data-testid="branch-search"]').native.send_keys(:enter)

          expect(page).to have_content('fix')
          expect(find('.all-branches')).to have_selector('li', count: 1)
          page.find('[data-target="#modal-delete-branch"]').click

          expect(page).to have_css('.js-delete-branch[disabled]')
          fill_in 'delete_branch_input', with: 'fix'
          click_link 'Delete protected branch'

          find('input[data-testid="branch-search"]').set('fix')
          find('input[data-testid="branch-search"]').native.send_keys(:enter)

          expect(page).to have_content('No branches to show')
        end
      end
    end
  end

  context 'logged in as admin' do
    before do
      sign_in(admin)
      gitlab_enable_admin_mode_sign_in(admin)
    end

    describe "explicit protected branches" do
      it "allows creating explicit protected branches" do
        visit project_protected_branches_path(project)
        set_defaults
        set_protected_branch_name('some-branch')
        click_on "Protect"

        within(".protected-branches-list") { expect(page).to have_content('some-branch') }
        expect(ProtectedBranch.count).to eq(1)
        expect(ProtectedBranch.last.name).to eq('some-branch')
      end

      it "displays the last commit on the matching branch if it exists" do
        commit = create(:commit, project: project)
        project.repository.add_branch(admin, 'some-branch', commit.id)

        visit project_protected_branches_path(project)
        set_defaults
        set_protected_branch_name('some-branch')
        click_on "Protect"

        within(".protected-branches-list") do
          expect(page).not_to have_content("matching")
          expect(page).not_to have_content("was deleted")
        end
      end

      it "displays an error message if the named branch does not exist" do
        visit project_protected_branches_path(project)
        set_defaults
        set_protected_branch_name('some-branch')
        click_on "Protect"

        within(".protected-branches-list") { expect(page).to have_content('Branch was deleted') }
      end
    end

    describe "wildcard protected branches" do
      it "allows creating protected branches with a wildcard" do
        visit project_protected_branches_path(project)
        set_defaults
        set_protected_branch_name('*-stable')
        click_on "Protect"

        within(".protected-branches-list") { expect(page).to have_content('*-stable') }
        expect(ProtectedBranch.count).to eq(1)
        expect(ProtectedBranch.last.name).to eq('*-stable')
      end

      it "displays the number of matching branches" do
        project.repository.add_branch(admin, 'production-stable', 'master')
        project.repository.add_branch(admin, 'staging-stable', 'master')

        visit project_protected_branches_path(project)
        set_defaults
        set_protected_branch_name('*-stable')
        click_on "Protect"

        within(".protected-branches-list") do
          expect(page).to have_content("2 matching branches")
        end
      end

      it "displays all the branches matching the wildcard" do
        project.repository.add_branch(admin, 'production-stable', 'master')
        project.repository.add_branch(admin, 'staging-stable', 'master')
        project.repository.add_branch(admin, 'development', 'master')

        visit project_protected_branches_path(project)
        set_protected_branch_name('*-stable')
        set_defaults
        click_on "Protect"

        visit project_protected_branches_path(project)
        click_on "2 matching branches"

        within(".protected-branches-list") do
          expect(page).to have_content("production-stable")
          expect(page).to have_content("staging-stable")
          expect(page).not_to have_content("development")
        end
      end
    end

    describe "access control" do
      before do
        stub_licensed_features(protected_refs_for_users: false)
      end

      include_examples "protected branches > access control > CE"
    end
  end

  context 'when the users for protected branches feature is off' do
    before do
      stub_licensed_features(protected_refs_for_users: false)
    end

    include_examples 'Deploy keys with protected branches' do
      let(:all_dropdown_sections) { %w(Roles Deploy\ Keys) }
    end
  end
end
