# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User confirmation', feature_category: :system_access do
  describe 'resend confirmation instructions' do
    context 'when recaptcha is enabled' do
      before do
        stub_application_setting(recaptcha_enabled: true)
        allow(Gitlab::Recaptcha).to receive(:load_configurations!)
        visit new_user_confirmation_path
      end

      it 'renders recaptcha' do
        expect(page).to have_css('.g-recaptcha')
      end
    end

    context 'when recaptcha is not enabled' do
      before do
        stub_application_setting(recaptcha_enabled: false)
        visit new_user_confirmation_path
      end

      it 'does not render recaptcha' do
        expect(page).not_to have_css('.g-recaptcha')
      end
    end
  end
end
