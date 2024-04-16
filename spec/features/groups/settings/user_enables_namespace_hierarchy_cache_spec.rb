# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Permission and group features > Enable caching of hierarchical objects', :js, feature_category: :value_stream_management do
  include ListboxHelpers

  let_it_be_with_reload(:group) { create(:group) }
  let_it_be(:user) { create(:user, owner_of: group) }

  before do
    sign_in(user)
  end

  context 'with the group_hierarchy_optimization feature flag enabled' do
    before do
      stub_feature_flags(group_hierarchy_optimization: true)
    end

    it 'enables the setting' do
      visit edit_group_path(group)

      page.within('#js-permissions-settings') do
        check 'group[enable_namespace_descendants_cache]'

        click_on 'Save changes'
      end

      expect(group.namespace_descendants).to be_present
    end

    it 'disables the setting' do
      create(:namespace_descendants, namespace: group)

      visit edit_group_path(group)

      page.within('#js-permissions-settings') do
        uncheck 'group[enable_namespace_descendants_cache]'

        click_on 'Save changes'
      end

      expect(group.reload.namespace_descendants).not_to be_present
    end
  end

  context 'with the group_hierarchy_optimization feature flag disabled' do
    before do
      stub_feature_flags(group_hierarchy_optimization: false)
    end

    it 'does not render the setting' do
      visit edit_group_path(group)

      expect(page).not_to have_selector('group[enable_namespace_descendants_cache]')
    end
  end
end
