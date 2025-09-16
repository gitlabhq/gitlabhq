# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Email OTP enrollment callout', :js, feature_category: :system_access do
  let_it_be(:user) { create(:user, :with_namespace) }
  let(:expected_title) { s_('EmailOTP|Enhanced authentication coming soon') }

  context 'when user is eligible for the callout' do
    let(:email_otp_required_after) { 31.days.from_now }

    before do
      user.update!(email_otp_required_after: email_otp_required_after)
    end

    context 'and has signed in' do
      before do
        sign_in(user)
      end

      it 'shows a dismissable callout' do
        visit root_path

        within('[data-feature-id="email_otp_enrollment_callout"]') do
          expect(page).to have_content(expected_title)
          expect(page).to have_content(email_otp_required_after.strftime('%B %d, %Y'))
          expect(page).to have_content(s_('EmailOTP|GitLab will begin requiring email one-time passcodes'))
          expect(page).to have_link(s_('EmailOTP|Review email addresses'), href: profile_emails_path)
        end

        # The 'x' button top right
        find('[data-feature-id="email_otp_enrollment_callout"] button[aria-label="Dismiss"]').click

        expect(page).not_to have_content(expected_title)

        # Verify it stays dismissed after page reload
        visit root_path
        expect(page).not_to have_content(expected_title)
      end

      it 'allows dismissing the callout with the action button' do
        visit root_path
        click_link(s_('EmailOTP|Review email addresses'))

        expect(URI.parse(current_url).path).to eq(profile_emails_path)
        expect(page).not_to have_content(expected_title)

        # Verify it stays dismissed after page reload
        visit root_path
        expect(page).not_to have_content(expected_title)
      end
    end
  end

  context 'when user is not eligible for the callout' do
    # See also: callouts_helper_spec.rb for other conditions which hide
    # the banner
    context 'when email_otp_required_after is more than 60 days away' do
      let(:email_otp_required_after) { 61.days.from_now }

      it 'does not show the callout' do
        visit root_path

        expect(page).not_to have_content(expected_title)
      end
    end
  end
end
