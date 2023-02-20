# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'AdditionalEmailToExistingAccount', feature_category: :user_profile do
  describe 'add secondary email associated with account' do
    let_it_be(:user) { create(:user) }
    let_it_be(:email) { create(:email, user: user) }

    before do
      sign_in(user)
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
