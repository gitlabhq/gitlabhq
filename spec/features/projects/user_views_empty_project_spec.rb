# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views an empty project', feature_category: :groups_and_projects do
  include Features::InviteMembersModalHelpers

  let_it_be(:project) { create(:project, :empty_repo) }
  let_it_be(:user) { create(:user) }

  shared_examples 'allowing push to default branch' do
    let(:default_branch) { project.default_branch_or_main }

    it 'shows push-to-default-branch instructions' do
      visit project_path(project)

      expect(page).to have_content("git push --set-upstream origin #{default_branch}")
    end
  end

  context 'when user is a maintainer' do
    before do
      project.add_maintainer(user)
      sign_in(user)
    end

    it_behaves_like 'allowing push to default branch'

    it 'shows a link for inviting members and launches invite modal', :js do
      visit project_path(project)

      click_button 'Invite members'

      page.within invite_modal_selector do
        expect(page).to have_content("You're inviting members to the #{project.name} project")
      end
    end
  end

  context 'when user is an admin' do
    let_it_be(:user) { create(:user, :admin) }

    context 'when admin mode is enabled' do
      before do
        sign_in(user)
        enable_admin_mode!(user)
      end

      it_behaves_like 'allowing push to default branch'
    end

    context 'when admin mode is disabled' do
      it 'does not show push-to-master instructions' do
        visit project_path(project)

        expect(page).not_to have_content('git push --set-upstream origin')
      end
    end
  end

  context 'when user is a developer' do
    before do
      project.add_developer(user)
      sign_in(user)
    end

    it 'does not show push-to-master instructions nor invite members link', :aggregate_failures, :js do
      visit project_path(project)

      expect(page).not_to have_content('git push --set-upstream origin')
      expect(page).not_to have_button(text: 'Invite members')
    end
  end
end
