class Profile < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths

  Then 'I should see my profile info' do
    page.should have_content "Profile"
    page.should have_content @user.name
    page.should have_content @user.email
  end

  Then 'I change my contact info' do
    fill_in "user_skype", :with => "testskype"
    fill_in "user_linkedin", :with => "testlinkedin"
    fill_in "user_twitter", :with => "testtwitter"
    click_button "Save"
    @user.reload
  end

  And 'I should see new contact info' do
    @user.skype.should == 'testskype'
    @user.linkedin.should == 'testlinkedin'
    @user.twitter.should == 'testtwitter'
  end

  Then 'I change my password' do
    fill_in "user_password", :with => "222333"
    fill_in "user_password_confirmation", :with => "222333"
    click_button "Save"
  end

  And 'I should be redirected to sign in page' do
    current_path.should == new_user_session_path
  end

  Then 'I reset my token' do
    @old_token = @user.private_token
    click_button "Reset"
  end

  And 'I should see new token' do
    find("#token").value.should_not == @old_token
    find("#token").value.should == @user.reload.private_token
  end

  Given 'I have activity' do
    Factory :closed_issue_event, author: current_user
  end

  Then 'I should see my activity' do
    page.should have_content "#{current_user.name} closed issue"
  end
end
