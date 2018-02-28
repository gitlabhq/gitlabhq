require 'spec_helper'

describe 'User manages emails' do
  let(:user) { create(:user) }

  before do
    sign_in(user)

    visit(profile_emails_path)
  end

  it "shows user's emails" do
    expect(page).to have_content(user.email)

    user.emails.each do |email|
      expect(page).to have_content(email.email)
    end
  end

  it 'adds an email' do
    fill_in('email_email', with: 'my@email.com')
    click_button('Add')

    email = user.emails.find_by(email: 'my@email.com')

    expect(email).not_to be_nil
    expect(page).to have_content('my@email.com')
    expect(page).to have_content(user.email)

    user.emails.each do |email|
      expect(page).to have_content(email.email)
    end
  end

  it 'does not add a duplicate email' do
    fill_in('email_email', with: user.email)
    click_button('Add')

    email = user.emails.find_by(email: user.email)

    expect(email).to be_nil
    expect(page).to have_content(user.email)

    user.emails.each do |email|
      expect(page).to have_content(email.email)
    end
  end

  it 'removes an email' do
    fill_in('email_email', with: 'my@email.com')
    click_button('Add')

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
