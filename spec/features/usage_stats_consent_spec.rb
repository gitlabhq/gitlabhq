# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Usage stats consent' do
  context 'when signed in' do
    let(:user) { create(:admin, created_at: 8.days.ago) }
    let(:message) { 'To help improve GitLab, we would like to periodically collect usage information.' }

    before do
      if Gitlab.ee?
        allow_any_instance_of(EE::User)
          .to receive(:has_current_license?)
          .and_return(false)
      else
        allow(user)
          .to receive(:has_current_license?)
          .and_return(false)
      end

      gitlab_sign_in(user)
      gitlab_enable_admin_mode_sign_in(user)
    end

    it 'hides the banner permanently when sets usage stats' do
      visit root_dashboard_path

      expect(page).to have_content(message)

      click_link 'Send service data'

      expect(page).not_to have_content(message)
      expect(page).to have_content('Application settings saved successfully')

      gitlab_sign_out
      gitlab_sign_in(user)
      visit root_dashboard_path

      expect(page).not_to have_content(message)
    end

    it 'shows banner on next session if user did not set usage stats' do
      visit root_dashboard_path

      expect(page).to have_content(message)

      gitlab_sign_out
      gitlab_sign_in(user)
      visit root_dashboard_path

      expect(page).to have_content(message)
    end
  end
end
