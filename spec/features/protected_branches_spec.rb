# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Protected Branches', :js, feature_category: :source_code_management do
  include ProtectedBranchHelpers

  let_it_be_with_reload(:user) { create(:user) }
  let_it_be_with_reload(:admin) { create(:admin) }
  let_it_be_with_reload(:project) { create(:project, :repository) }

  context 'logged in as developer' do
    before_all do
      project.add_developer(user)
    end

    before do
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
    let(:success_message) { s_('ProtectedBranch|View protected branches as branch rules') }

    before_all do
      project.add_maintainer(user)
    end

    before do
      stub_feature_flags(edit_branch_rules: false)
      sign_in(user)
    end

    it_behaves_like 'setting project protected branches'
  end

  context 'logged in as admin' do
    before do
      sign_in(admin)
      enable_admin_mode!(admin)
    end

    describe "access control" do
      before do
        stub_licensed_features(protected_refs_for_users: false)
      end

      it_behaves_like "protected branches > access control > CE"
    end
  end

  context 'when the users for protected branches feature is off' do
    before do
      stub_licensed_features(protected_refs_for_users: false)
    end

    it_behaves_like 'deploy keys with protected branches' do
      let(:all_dropdown_sections) { ['Roles', 'Deploy keys'] }
    end
  end
end
