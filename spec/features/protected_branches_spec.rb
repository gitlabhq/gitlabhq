# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Protected Branches', :js, feature_category: :source_code_management do
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

        expect(page).not_to have_button('Delete protected branch')
      end
    end
  end

  context 'logged in as maintainer' do
    before do
      project.add_maintainer(user)
      sign_in(user)
    end

    it 'allows to create a protected branch with name containing HTML tags' do
      visit project_protected_branches_path(project)

      show_add_form
      set_defaults
      set_protected_branch_name('foo<b>bar<\b>')
      click_on "Protect"

      within(".protected-branches-list") { expect(page).to have_content('foo<b>bar<\b>') }
      expect(ProtectedBranch.count).to eq(1)
      expect(ProtectedBranch.last.name).to eq('foo<b>bar<\b>')
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

        within_testid('branch-more-actions') do
          find('button').click
        end

        wait_for_requests
        expect(page).to have_button('Delete protected branch', disabled: false)

        find_by_testid('delete-branch-button').click
        fill_in 'delete_branch_input', with: 'fix'
        click_button 'Yes, delete protected branch'

        expect(page).to have_content('No branches to show')
      end
    end
  end

  context 'logged in as admin' do
    before do
      sign_in(admin)
      enable_admin_mode!(admin)
    end

    it_behaves_like 'setting project protected branches'

    it "shows success alert once protected branch is created" do
      visit project_protected_branches_path(project)

      show_add_form
      set_defaults
      set_protected_branch_name('some->branch')
      click_on "Protect"
      wait_for_requests
      expect(page).to have_content(s_('ProtectedBranch|View protected branches as branch rules'))
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
      let(:all_dropdown_sections) { ['Roles', 'Deploy Keys'] }
    end
  end
end
