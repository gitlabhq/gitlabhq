require 'rails_helper'

feature 'Profile > Emails' do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'User adds an email' do
    before do
      visit profile_emails_path
    end

    scenario 'saves the new email' do
      fill_in('Email', with: 'my@email.com')
      click_button('Add email address')

      expect(page).to have_content('my@email.com Unverified')
      expect(page).to have_content("#{user.email} Verified")
      expect(page).to have_content('Resend confirmation email')
    end

    scenario 'does not add a duplicate email' do
      fill_in('Email', with: user.email)
      click_button('Add email address')

      email = user.emails.find_by(email: user.email)
      expect(email).to be_nil
      expect(page).to have_content('Email has already been taken')
    end
  end

  scenario 'User removes email' do
    user.emails.create(email: 'my@email.com')
    visit profile_emails_path
    expect(page).to have_content("my@email.com")

    click_link('Remove')
    expect(page).not_to have_content("my@email.com")
  end

  scenario 'User confirms email' do
    email = user.emails.create(email: 'my@email.com')
    visit profile_emails_path
    expect(page).to have_content("#{email.email} Unverified")

    email.confirm
    expect(email.confirmed?).to be_truthy

    visit profile_emails_path
    expect(page).to have_content("#{email.email} Verified")
  end

  scenario 'User re-sends confirmation email' do
    email = user.emails.create(email: 'my@email.com')
    visit profile_emails_path

    expect { click_link("Resend confirmation email") }.to change { ActionMailer::Base.deliveries.size }
    expect(page).to have_content("Confirmation email sent to #{email.email}")
  end

  scenario 'old unconfirmed emails show Send Confirmation button' do
    email = user.emails.create(email: 'my@email.com')
    email.update_attribute(:confirmation_sent_at, nil)
    visit profile_emails_path

    expect(page).not_to have_content('Resend confirmation email')
    expect(page).to have_content('Send confirmation email')
  end
end
