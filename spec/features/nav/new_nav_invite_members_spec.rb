# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'new navigation toggle', :js, feature_category: :navigation do
  include Features::InviteMembersModalHelpers

  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  context 'when inside a group' do
    let_it_be(:group) { create(:group, owners: user) }

    before do
      visit group_path(group)
    end

    it 'the add menu contains invite members dropdown option and opens invite modal' do
      invite_members_from_menu

      page.within invite_modal_selector do
        expect(page).to have_content("You're inviting members to the #{group.name} group")
      end
    end
  end

  context 'when inside a project' do
    let_it_be(:project) { create(:project, :repository, owners: user) }

    before do
      visit project_path(project)
    end

    it 'the add menu contains invite members dropdown option and opens invite modal' do
      invite_members_from_menu

      page.within invite_modal_selector do
        expect(page).to have_content("You're inviting members to the #{project.name} project")
      end
    end
  end

  def invite_members_from_menu
    page.find('[data-testid="new-menu-toggle"] button').click
    click_button('Invite team members')
  end
end
