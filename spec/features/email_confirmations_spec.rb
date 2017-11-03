require 'spec_helper'

feature 'EmailConfirmations' do

  describe 'confirming secondary email' do
    let(:user)  { create(:user) }
    let(:user2) { create(:user) }

    context 'with user signed in' do
      before do
        sign_in(user)
      end

      it 'fails with invalid token' do
        visit email_confirmation_path(confirmation_token: 'token_1')

        expect(page).to have_content('Confirmation token is invalid')
      end

      it 'successfully confirms' do
        user.emails.create(email: 'new@email.com', confirmation_token: 'token_1')

        visit email_confirmation_path(confirmation_token: 'token_1')

        expect(page).to have_content "Your email address has been successfully confirmed"
      end

      it 'removes secondary email duplicates' do
        user.emails.create(email: 'new@email.com', confirmation_token: 'token_1')
        user2.emails.create(email: 'New@email.com')

        visit email_confirmation_path(confirmation_token: 'token_1')

        expect(Email.where(email: 'new@email.com').count).to eq 1
        expect(Email.confirmed.count).to eq 1
        expect(page).to have_content "Your email address has been successfully confirmed"
      end
    end

    context 'user not signed in' do
      it 'fails with invalid token' do
        visit email_confirmation_path(confirmation_token: 'token_1')

        expect(page).to have_content('Confirmation token is invalid')
      end

      it 'successfully confirms' do
        user.emails.create(email: 'new@email.com', confirmation_token: 'token_1')

        visit email_confirmation_path(confirmation_token: 'token_1')

        expect(page).to have_content "Your email address has been successfully confirmed"
      end
    end
  end

  describe 'confirming user account email' do
    let!(:user)  { create(:user, :unconfirmed) }

    context 'user not signed in' do
      it 'fails with invalid token' do
        visit user_confirmation_path(confirmation_token: 'invalid_token')

        expect(page).to have_content('Confirmation token is invalid')
      end

      it 'successfully confirms' do
        visit user_confirmation_path(confirmation_token: 'token_1')

        expect(page).to have_content "Your email address has been successfully confirmed"
      end

      it 'does not confirm if another email is already confirmed' do
        user2 = create(:user)
        user2.emails.create(email: user.email, confirmed_at: Time.now)

        visit user_confirmation_path(confirmation_token: 'token_1')

        expect(page).to have_content "This email address was confirmed to belong to another account"
      end
    end

  end
end
