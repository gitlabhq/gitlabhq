# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Cohorts page' do
  before do
    admin = create(:admin)
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)
  end

  context 'with usage ping enabled' do
    it 'shows users count per month' do
      stub_application_setting(usage_ping_enabled: true)

      create_list(:user, 2)

      visit admin_cohorts_path

      expect(page).to have_content("#{Time.now.strftime('%b %Y')} 3 0")
    end
  end

  context 'with usage ping disabled' do
    it 'shows empty state', :js do
      stub_application_setting(usage_ping_enabled: false)

      visit admin_cohorts_path

      expect(page).to have_selector(".js-empty-state")
    end
  end
end
