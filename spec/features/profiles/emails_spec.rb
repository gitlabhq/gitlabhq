# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Profile > Emails', feature_category: :user_profile do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'User adds an email' do
    before do
      visit profile_emails_path
    end

    it 'saves the new email' do
      fill_in('Email', with: 'my@email.com')
      click_button('Add email address')

      expect(page).to have_content('my@email.com Unverified')
      expect(page).to have_content("#{user.email} Verified")
      expect(page).to have_content('Resend confirmation email')
    end

    it 'does not add an email that is the primary email of another user' do
      fill_in('Email', with: other_user.email)
      click_button('Add email address')

      email = user.emails.find_by(email: other_user.email)
      expect(email).to be_nil
      expect(page).to have_content('Email has already been taken')
    end

    it 'adds an email that is the primary email of the same user' do
      fill_in('Email', with: user.email)
      click_button('Add email address')

      email = user.emails.find_by(email: user.email)
      expect(email).to be_present
      expect(page).to have_content("#{user.email} Verified")
      expect(page).not_to have_content("#{user.email} Unverified")
    end

    it 'does not add an invalid email' do
      fill_in('Email', with: 'test@@example.com')
      click_button('Add email address')

      email = user.emails.find_by(email: email)
      expect(email).to be_nil
      expect(page).to have_content('Email is invalid')
    end
  end

  it 'user removes email' do
    user.emails.create!(email: 'my@email.com')
    visit profile_emails_path
    expect(page).to have_content("my@email.com")

    click_link('Remove')
    expect(page).not_to have_content("my@email.com")
  end

  it 'user confirms email' do
    email = user.emails.create!(email: 'my@email.com')
    visit profile_emails_path
    expect(page).to have_content("#{email.email} Unverified")

    email.confirm
    expect(email.confirmed?).to be_truthy

    visit profile_emails_path
    expect(page).to have_content("#{email.email} Verified")
  end

  it 'user re-sends confirmation email' do
    email = user.emails.create!(email: 'my@email.com')
    visit profile_emails_path

    expect { click_link("Resend confirmation email") }.to have_enqueued_job.on_queue('mailers')
    expect(page).to have_content("Confirmation email sent to #{email.email}")
  end

  it 'old unconfirmed emails show Send Confirmation button' do
    email = user.emails.create!(email: 'my@email.com')
    email.update_attribute(:confirmation_sent_at, nil)
    visit profile_emails_path

    expect(page).not_to have_content('Resend confirmation email')
    expect(page).to have_content('Send confirmation email')
  end
end
