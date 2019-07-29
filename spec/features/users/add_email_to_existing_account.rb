# frozen_string_literal: true

require 'spec_helper'

describe 'AdditionalEmailToExistingAccount' do
  describe 'add secondary email associated with account' do
    let(:user) { create(:user) }

    it 'verifies confirmation of additional email' do
      sign_in(user)

      email = create(:email, user: user)
      visit email_confirmation_path(confirmation_token: email.confirmation_token)
      expect(page).to have_content 'Your email address has been successfully confirmed.'
    end
  end
end
