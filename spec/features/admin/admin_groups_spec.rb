require 'spec_helper'

feature 'Admin Groups', feature: true do
  let(:internal) { Gitlab::VisibilityLevel::INTERNAL }

  before do
    login_as(:admin)

    stub_application_setting(default_group_visibility: internal)
  end

  describe 'create a group' do
    scenario 'shows the visibility level radio populated with the default value' do
      visit new_admin_group_path

      expect_selected_visibility(internal)
    end
  end

  describe 'group edit' do
    scenario 'shows the visibility level radio populated with the group visibility_level value' do
      group = create(:group, :private)

      visit edit_admin_group_path(group)

      expect_selected_visibility(group.visibility_level)
    end
  end

  def expect_selected_visibility(level)
    selector = "#group_visibility_level_#{level}[checked=checked]"

    expect(page).to have_selector(selector, count: 1)
  end
end
