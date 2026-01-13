# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User password', :with_current_organization, feature_category: :system_access do
  include EmailHelpers

  # Recaptcha must be stubbed for all request flows, as it uses singleton configuration
  # which will leak between specs
  before do
    allow(Gitlab::Recaptcha).to receive(:load_configurations!)
  end

  describe 'send password reset' do
    context 'when recaptcha is enabled' do
      before do
        stub_application_setting(recaptcha_enabled: true)
        visit new_user_password_path
      end

      it 'renders recaptcha' do
        expect(page).to have_css('.g-recaptcha')
      end
    end

    context 'when recaptcha is not enabled' do
      before do
        stub_application_setting(recaptcha_enabled: false)
        visit new_user_password_path
      end

      it 'does not render recaptcha' do
        expect(page).not_to have_css('.g-recaptcha')
      end
    end

    context 'when user has multiple emails' do
      let_it_be(:user) { create(:user, email: 'primary@example.com') }
      let_it_be(:verified_email) { create(:email, :confirmed, user: user, email: 'second@example.com') }
      let_it_be(:unverified_email) { create(:email, user: user, email: 'unverified@example.com') }

      subject(:submit_form) do
        perform_enqueued_jobs do
          visit new_user_password_path
          fill_in 'user_email', with: email
          click_button 'Reset password'
        end
      end

      context 'when user enters the primary email' do
        let(:email) { user.email }
        let(:new_password) { '5upers3cret!' }

        it 'sends reset instructions email' do
          submit_form

          mail = find_email_for(email)
          expect(mail.subject).to eq('Reset password instructions')
          body = Nokogiri::HTML::DocumentFragment.parse(mail.body.parts.last.to_s)
          reset_password_link = body.css('#cta a').attribute('href').value

          visit reset_password_link
          expect(page).to have_content('Change your password')

          fill_in 'user_password', with: new_password
          fill_in 'user_password_confirmation', with: new_password
          click_button 'Change your password'

          expect(page).to have_content('Your password has been changed successfully.')
        end
      end

      context 'when user enters a secondary verified email' do
        let(:email) { verified_email.email }

        it 'send the email to the correct email address' do
          submit_form
          expect(ActionMailer::Base.deliveries.first.to).to include(email)
        end
      end

      context 'when user enters an unverified email' do
        let(:email) { unverified_email.email }

        it 'does not send an email' do
          submit_form
          expect(ActionMailer::Base.deliveries.count).to eq(0)
        end
      end
    end
  end
end
