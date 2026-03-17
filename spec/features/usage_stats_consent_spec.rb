# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Usage stats consent', feature_category: :service_ping do
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
      enable_admin_mode!(user)
    end

    shared_examples 'dismissible banner' do |button_text|
      it 'hides the banner permanently when sets usage stats', :js do
        visit root_dashboard_path

        expect(page).to have_content(message)

        click_link button_text

        expect(page).not_to have_content(message)
        expect(page).to have_content('Application settings saved successfully')

        gitlab_sign_out
        gitlab_sign_in(user)
        visit root_dashboard_path

        expect(page).not_to have_content(message)
      end
    end

    it_behaves_like 'dismissible banner', _('Send service data')
    it_behaves_like 'dismissible banner', _("Don't send service data")

    it 'shows banner on next session if user did not set usage stats', :js do
      visit root_dashboard_path

      expect(page).to have_content(message)

      gitlab_sign_out
      gitlab_sign_in(user)
      visit root_dashboard_path

      expect(page).to have_content(message)
    end
  end
end
