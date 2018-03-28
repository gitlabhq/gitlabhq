require 'spec_helper'

feature 'CI shared runner settings' do
  include StubENV

  let(:admin) { create(:admin) }
  let(:group) { create(:group, :with_build_minutes) }
  let!(:project) { create(:project, namespace: group, shared_runners_enabled: true) }

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    sign_in(admin)
  end

  context 'without global shared runners quota' do
    scenario 'should display ratio with global quota' do
      visit_admin_group_path
      expect(page).to have_content("Pipeline minutes quota: 400 / Unlimited")
      expect(page).to have_selector('.shared_runners_limit_disabled')
    end
  end

  context 'with global shared runners quota' do
    before do
      set_admin_shared_runners_minutes 500
    end

    scenario 'should display ratio with global quota' do
      visit_admin_group_path
      expect(page).to have_content("Pipeline minutes quota: 400 / 500")
      expect(page).to have_selector('.shared_runners_limit_under_quota')
    end

    scenario 'should display new ratio with overridden group quota' do
      set_group_shared_runners_minutes 300
      visit_admin_group_path
      expect(page).to have_content("Pipeline minutes quota: 400 / 300")
      expect(page).to have_selector('.shared_runners_limit_over_quota')
    end

    scenario 'should display unlimited ratio with overridden group quota' do
      set_group_shared_runners_minutes 0
      visit_admin_group_path
      expect(page).to have_content("Pipeline minutes quota: 400 / Unlimited")
      expect(page).to have_selector('.shared_runners_limit_disabled')
    end
  end

  def set_admin_shared_runners_minutes(limit)
    visit admin_application_settings_path

    page.within('.as-ci-cd') do
      fill_in 'application_setting_shared_runners_minutes', with: limit
      click_on 'Save changes'
    end
  end

  def set_group_shared_runners_minutes(limit)
    visit admin_group_edit_path(group)
    fill_in 'group_shared_runners_minutes_limit', with: limit
    click_on 'Save changes'
  end

  def visit_admin_group_path
    visit admin_group_path(group)
  end
end
