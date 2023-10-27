# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'New group page', :js, feature_category: :groups_and_projects do
  let_it_be(:user)  { create(:user) }
  let_it_be(:parent_group) { create(:group) }

  before do
    parent_group.add_owner(user)
    sign_in(user)
  end

  describe 'sidebar' do
    context 'for a new top-level group' do
      it 'shows the "Your work" navigation' do
        visit new_group_path
        expect(page).to have_selector(".super-sidebar", text: "Your work")
      end
    end

    context 'for a new subgroup' do
      it 'shows the group navigation of the parent group' do
        visit new_group_path(parent_id: parent_group.id, anchor: 'create-group-pane')
        expect(page).to have_selector(".super-sidebar", text: parent_group.name)
      end
    end
  end
end
