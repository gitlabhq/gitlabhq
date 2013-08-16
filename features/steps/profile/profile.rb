class Profile < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths

  step 'I should see my profile info' do
    page.should have_content "Profile"
    page.should have_content @user.name
    page.should have_content @user.email
  end

  step 'I change my contact info' do
    fill_in "user_skype", with: "testskype"
    fill_in "user_linkedin", with: "testlinkedin"
    fill_in "user_twitter", with: "testtwitter"
    click_button "Save changes"
    @user.reload
  end

  step 'I should see new contact info' do
    @user.skype.should == 'testskype'
    @user.linkedin.should == 'testlinkedin'
    @user.twitter.should == 'testtwitter'
  end

  step 'I change my password' do
    within '.update-password' do
      fill_in "user_password", with: "222333"
      fill_in "user_password_confirmation", with: "222333"
      click_button "Save"
    end
  end

  step 'I unsuccessfully change my password' do
    within '.update-password' do
      fill_in "user_password", with: "password"
      fill_in "user_password_confirmation", with: "confirmation"
      click_button "Save"
    end
  end

  step "I should see a password error message" do
    page.should have_content "Password doesn't match confirmation"
  end

  step 'I should be redirected to sign in page' do
    current_path.should == new_user_session_path
  end

  step 'I reset my token' do
    within '.update-token' do
      @old_token = @user.private_token
      click_button "Reset"
    end
  end

  step 'I should see new token' do
    find("#token").value.should_not == @old_token
    find("#token").value.should == @user.reload.private_token
  end

  step 'I have activity' do
    create(:closed_issue_event, author: current_user)
  end

  step 'I should see my activity' do
    page.should have_content "#{current_user.name} closed issue"
  end

  step "I change my application theme" do
    within '.application-theme' do
      choose "Violet"
    end
  end

  step "I change my code preview theme" do
    within '.code-preview-theme' do
      choose "Solarized dark"
    end
  end

  step "I should see the theme change immediately" do
    page.should have_selector('body.ui_color')
    page.should_not have_selector('body.ui_basic')
  end

  step "I should receive feedback that the changes were saved" do
    page.should have_content("Saved")
  end

  step 'my password is expired' do
    current_user.update_attributes(password_expires_at: Time.now - 1.hour)
  end

  step 'I redirected to expired password page' do
    current_path.should == new_profile_password_path
  end

  step 'I submit new password' do
    fill_in :user_password, with: '12345678'
    fill_in :user_password_confirmation, with: '12345678'
    click_button "Set new password"
  end

  step 'I redirected to sign in page' do
    current_path.should == new_user_session_path
  end

  step 'I click on my profile picture' do
    click_link 'profile-pic'
  end

  step 'I should see my user page' do
    page.should have_content "User Activity"

    within '.navbar-gitlab' do
      page.should have_content current_user.name
    end
  end
end
