# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'New group page', :js, feature_category: :subgroups do
  let_it_be(:user)  { create(:user) }
  let_it_be(:parent_group) { create(:group) }

  before do
    parent_group.add_owner(user)
    sign_in(user)
  end

  describe 'new top level group alert' do
    context 'when a user visits the new group page' do
      it 'shows the new top level group alert' do
        visit new_group_path(anchor: 'create-group-pane')

        expect(page).to have_selector('[data-testid="new-top-level-alert"]')
      end
    end

    context 'when a user visits the new sub group page' do
      it 'does not show the new top level group alert' do
        visit new_group_path(parent_id: parent_group.id, anchor: 'create-group-pane')

        expect(page).not_to have_selector('[data-testid="new-top-level-alert"]')
      end
    end
  end

  describe 'sidebar' do
    context 'for a new top-level group' do
      it_behaves_like 'a dashboard page with sidebar', :new_group_path, :groups
    end

    context 'for a new subgroup' do
      it 'shows the group sidebar of the parent group' do
        visit new_group_path(parent_id: parent_group.id, anchor: 'create-group-pane')
        expect(page).to have_selector(
          ".nav-sidebar[aria-label=\"Group navigation\"] .context-header[title=\"#{parent_group.name}\"]"
        )
      end
    end
  end
end
