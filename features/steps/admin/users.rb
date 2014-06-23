class AdminUsers < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedAdmin

  Then 'I should see all users' do
    User.all.each do |user|
      page.should have_content user.name
    end
  end

  And 'Click edit' do
    @user = User.first
    find("#edit_user_#{@user.id}").click
  end

  And 'Input non ascii char in username' do
    fill_in 'user_username', with: "\u3042\u3044"
  end

  And 'Click save' do
    click_button("Save")
  end

  Then 'See username error message' do
    within "#error_explanation" do
      page.should have_content "Username"
    end
  end

  And 'Not changed form action url' do
    page.should have_selector %(form[action="/admin/users/#{@user.username}"])
  end

  step 'I submit modified user' do
    check :user_can_create_group
    click_button 'Save'
  end

  step 'I see user attributes changed' do
    page.should have_content 'Can create groups: Yes'
  end

  step 'click edit on my user' do
    find("#edit_user_#{current_user.id}").click
  end

  step 'I view the user with secondary email' do
    @user_with_secondary_email = User.last
    @user_with_secondary_email.emails.new(email: "secondary@example.com")
    @user_with_secondary_email.save
    visit "/admin/users/#{@user_with_secondary_email.username}"
  end

  step 'I see the secondary email' do
    page.should have_content "Secondary email: #{@user_with_secondary_email.emails.last.email}"
  end

  step 'I click remove secondary email' do
    find("#remove_email_#{@user_with_secondary_email.emails.last.id}").click
  end

  step 'I should not see secondary email anymore' do
    page.should_not have_content "Secondary email:"
  end
end
