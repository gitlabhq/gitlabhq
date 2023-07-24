# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User manages emails', feature_category: :user_profile do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  before do
    sign_in(user)

    visit(profile_emails_path)
  end

  it "shows user's emails", :aggregate_failures do
    expect(page).to have_content(user.email)

    user.emails.each do |email|
      expect(page).to have_content(email.email)
    end
  end

  it 'adds an email', :aggregate_failures do
    fill_in('email_email', with: 'my@email.com')
    click_button('Add email address')

    email = user.emails.find_by(email: 'my@email.com')

    expect(email).not_to be_nil
    expect(page).to have_content('my@email.com')
    expect(page).to have_content(user.email)

    user.emails.each do |email|
      expect(page).to have_content(email.email)
    end
  end

  it 'does not add an email that is the primary email of another user', :aggregate_failures do
    fill_in('email_email', with: other_user.email)
    click_button('Add email address')

    email = user.emails.find_by(email: other_user.email)

    expect(email).to be_nil
    expect(page).to have_content('Email has already been taken')

    user.emails.each do |email|
      expect(page).to have_content(email.email)
    end
  end

  it 'removes an email', :aggregate_failures do
    fill_in('email_email', with: 'my@email.com')
    click_button('Add email address')

    email = user.emails.find_by(email: 'my@email.com')

    expect(email).not_to be_nil
    expect(page).to have_content('my@email.com')
    expect(page).to have_content(user.email)

    user.emails.each do |email|
      expect(page).to have_content(email.email)
    end

    # There should be only one remove button at this time
    click_link('Remove')

    # Force these to reload as they have been cached
    user.emails.reload
    email = user.emails.find_by(email: 'my@email.com')

    expect(email).to be_nil
    expect(page).not_to have_content('my@email.com')
    expect(page).to have_content(user.email)

    user.emails.each do |email|
      expect(page).to have_content(email.email)
    end
  end
end
