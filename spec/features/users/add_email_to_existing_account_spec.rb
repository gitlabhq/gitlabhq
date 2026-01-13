# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'AdditionalEmailToExistingAccount', feature_category: :user_profile do
  include EmailHelpers

  describe 'add secondary email associated with account' do
    let_it_be(:user) { create(:user, :with_namespace) }
    let_it_be(:email) { create(:email, user: user) }

    let(:new_email) { 'hamster-dog@example.com' }

    subject(:fill_in_new_email_form) do
      visit profile_emails_path

      perform_enqueued_jobs do
        click_button 'Add new email'
        fill_in 'Email address', with: new_email
        click_button 'Add email address'
        expect(page).to have_content(new_email)
      end
    end

    before do
      sign_in(user)
      reset_delivered_emails!
    end

    it 'sends confirmation email to user with clickable link' do
      fill_in_new_email_form

      mail = find_email_for(new_email)
      expect(mail.subject).to eq('Confirmation instructions')

      body = Nokogiri::HTML::DocumentFragment.parse(mail.body.parts.last.to_s)
      confirmation_link = body.css('#cta a').attribute('href').value

      expect { visit confirmation_link }.to change { Email.find_by(email: new_email).confirmed_at }
      expect(page).to have_content('Your email address has been successfully confirmed.')
    end

    it 'verifies confirmation of additional email' do
      visit email_confirmation_path(confirmation_token: email.confirmation_token)

      expect(page).to have_content 'Your email address has been successfully confirmed.'
    end

    it 'accepts any pending invites for an email confirmation' do
      member = create(:group_member, :invited, invite_email: email.email)

      visit email_confirmation_path(confirmation_token: email.confirmation_token)

      expect(member.reload.user).to eq(user)
      expect(page).to have_content 'Your email address has been successfully confirmed.'
    end
  end
end
