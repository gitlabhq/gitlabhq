class Spinach::Features::ProfileEmails < Spinach::FeatureSteps
  include SharedAuthentication

  step 'I visit profile emails page' do
    visit profile_emails_path
  end

  step 'I should see my emails' do
    expect(page).to have_content(@user.email)
    @user.emails.each do |email|
      expect(page).to have_content(email.email)
    end
  end

  step 'I submit new email "my@email.com"' do
    fill_in "email_email", with: "my@email.com"
    click_button "Add"
  end

  step 'I should see new email "my@email.com"' do
    email = @user.emails.find_by(email: "my@email.com")
    expect(email).not_to be_nil
    expect(page).to have_content("my@email.com")
  end

  step 'I should not see email "my@email.com"' do
    email = @user.emails.find_by(email: "my@email.com")
    expect(email).to be_nil
    expect(page).not_to have_content("my@email.com")
  end
  
  step 'I click link "Remove" for "my@email.com"' do
    # there should only be one remove button at this time
    click_link "Remove"
    # force these to reload as they have been cached
    @user.emails.reload
  end

  step 'I submit duplicate email @user.email' do
    fill_in "email_email", with: @user.email
    click_button "Add"
  end

  step 'I should not have @user.email added' do
    email = @user.emails.find_by(email: @user.email)
    expect(email).to be_nil
  end
end
