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
    context 'in the current navigation' do
      before do
        user.update!(use_new_navigation: false)
      end

      context 'for a new top-level group' do
        it_behaves_like 'a "Your work" page with sidebar and breadcrumbs', :new_group_path, :groups
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

    context 'in the new navigation' do
      before do
        user.update!(use_new_navigation: true)
      end

      context 'for a new top-level group' do
        it 'shows the "Your work" navigation' do
          visit new_group_path
          expect(page).to have_selector(".super-sidebar .context-switcher-toggle", text: "Your work")
        end
      end

      context 'for a new subgroup' do
        it 'shows the group navigation of the parent group' do
          visit new_group_path(parent_id: parent_group.id, anchor: 'create-group-pane')
          expect(page).to have_selector(".super-sidebar .context-switcher-toggle", text: parent_group.name)
        end
      end
    end
  end
end
