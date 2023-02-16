# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'top nav responsive', :js, feature_category: :navigation do
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  context 'when inside a project' do
    let_it_be(:project) { create(:project).tap { |record| record.add_owner(user) } }

    before do
      visit project_path(project)
    end

    it 'the add menu contains invite members dropdown option and goes to the members page' do
      invite_members_from_menu

      expect(page).to have_current_path(project_project_members_path(project))
    end
  end

  context 'when inside a group' do
    let_it_be(:group) { create(:group).tap { |record| record.add_owner(user) } }

    before do
      visit group_path(group)
    end

    it 'the add menu contains invite members dropdown option and goes to the members page' do
      invite_members_from_menu

      expect(page).to have_current_path(group_group_members_path(group))
    end
  end

  def invite_members_from_menu
    find('[data-testid="new-dropdown"]').click

    click_link('Invite members')
  end
end
