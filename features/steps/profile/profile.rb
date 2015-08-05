class Spinach::Features::Profile < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths

  step 'I should see my profile info' do
    expect(page).to have_content "This information will appear on your profile"
  end

  step 'I change my profile info' do
    fill_in 'user_skype', with: 'testskype'
    fill_in 'user_linkedin', with: 'testlinkedin'
    fill_in 'user_twitter', with: 'testtwitter'
    fill_in 'user_website_url', with: 'testurl'
    fill_in 'user_location', with: 'Ukraine'
    fill_in 'user_bio', with: 'I <3 GitLab'
    click_button 'Save changes'
    @user.reload
  end

  step 'I should see new profile info' do
    expect(@user.skype).to eq 'testskype'
    expect(@user.linkedin).to eq 'testlinkedin'
    expect(@user.twitter).to eq 'testtwitter'
    expect(@user.website_url).to eq 'testurl'
    expect(@user.bio).to eq 'I <3 GitLab'
    expect(find('#user_location').value).to eq 'Ukraine'
  end

  step 'I change my avatar' do
    attach_file(:user_avatar, File.join(Rails.root, 'spec', 'fixtures', 'banana_sample.gif'))
    click_button "Save changes"
    @user.reload
  end

  step 'I should see new avatar' do
    expect(@user.avatar).to be_instance_of AvatarUploader
    expect(@user.avatar.url).to eq "/uploads/user/avatar/#{ @user.id }/banana_sample.gif"
  end

  step 'I should see the "Remove avatar" button' do
    expect(page).to have_link("Remove avatar")
  end

  step 'I have an avatar' do
    attach_file(:user_avatar, File.join(Rails.root, 'spec', 'fixtures', 'banana_sample.gif'))
    click_button "Save changes"
    @user.reload
  end

  step 'I remove my avatar' do
    click_link "Remove avatar"
    @user.reload
  end

  step 'I should see my gravatar' do
    expect(@user.avatar?).to eq false
  end

  step 'I should not see the "Remove avatar" button' do
    expect(page).not_to have_link("Remove avatar")
  end
  
  step 'I should see the gravatar host link' do
    expect(page).to have_link("gravatar.com")
  end

  step 'I try change my password w/o old one' do
    page.within '.update-password' do
      fill_in "user_password", with: "22233344"
      fill_in "user_password_confirmation", with: "22233344"
      click_button "Save"
    end
  end

  step 'I change my password' do
    page.within '.update-password' do
      fill_in "user_current_password", with: "12345678"
      fill_in "user_password", with: "22233344"
      fill_in "user_password_confirmation", with: "22233344"
      click_button "Save"
    end
  end

  step 'I unsuccessfully change my password' do
    page.within '.update-password' do
      fill_in "user_current_password", with: "12345678"
      fill_in "user_password", with: "password"
      fill_in "user_password_confirmation", with: "confirmation"
      click_button "Save"
    end
  end

  step "I should see a missing password error message" do
    page.within ".flash-container" do
      expect(page).to have_content "You must provide a valid current password"
    end
  end

  step "I should see a password error message" do
    page.within '.alert' do
      expect(page).to have_content "Password confirmation doesn't match"
    end
  end

  step 'I reset my token' do
    page.within '.update-token' do
      @old_token = @user.private_token
      click_button "Reset"
    end
  end

  step 'I should see new token' do
    expect(find("#token").value).not_to eq @old_token
    expect(find("#token").value).to eq @user.reload.private_token
  end

  step 'I have activity' do
    create(:closed_issue_event, author: current_user)
  end

  step 'I should see my activity' do
    expect(page).to have_content "Signed in with standard authentication"
  end

  step 'my password is expired' do
    current_user.update_attributes(password_expires_at: Time.now - 1.hour)
  end

  step "I am not an ldap user" do
    current_user.identities.delete
    expect(current_user.ldap_user?).to eq false
  end

  step 'I redirected to expired password page' do
    expect(current_path).to eq new_profile_password_path
  end

  step 'I submit new password' do
    fill_in :user_current_password, with: '12345678'
    fill_in :user_password, with: '12345678'
    fill_in :user_password_confirmation, with: '12345678'
    click_button "Set new password"
  end

  step 'I redirected to sign in page' do
    expect(current_path).to eq new_user_session_path
  end

  step 'I should be redirected to password page' do
    expect(current_path).to eq edit_profile_password_path
  end

  step 'I should be redirected to account page' do
    expect(current_path).to eq profile_account_path
  end

  step 'I click on my profile picture' do
    find(:css, '.sidebar-user').click
  end

  step 'I should see my user page' do
    expect(page).to have_content "User Activity"

    page.within '.navbar-gitlab' do
      expect(page).to have_content current_user.name
    end
  end

  step 'I have group with projects' do
    @group   = create(:group)
    @group.add_owner(current_user)
    @project = create(:project, namespace: @group)
    @event   = create(:closed_issue_event, project: @project)

    @project.team << [current_user, :master]
  end

  step 'I should see groups I belong to' do
    expect(page).to have_css('.profile-groups-avatars', visible: true)
  end

  step 'I click on new application button' do
    click_on 'New Application'
  end

  step 'I should see application form' do
    expect(page).to have_content "New Application"
  end

  step 'I fill application form out and submit' do
    fill_in :doorkeeper_application_name, with: 'test'
    fill_in :doorkeeper_application_redirect_uri, with: 'https://test.com'
    click_on "Submit"
  end

  step 'I see application' do
    expect(page).to have_content "Application: test"
    expect(page).to have_content "Application Id"
    expect(page).to have_content "Secret"
  end

  step 'I click edit' do
    click_on "Edit"
  end

  step 'I see edit application form' do
    expect(page).to have_content "Edit application"
  end

  step 'I change name of application and submit' do
    expect(page).to have_content "Edit application"
    fill_in :doorkeeper_application_name, with: 'test_changed'
    click_on "Submit"
  end

  step 'I see that application was changed' do
    expect(page).to have_content "test_changed"
    expect(page).to have_content "Application Id"
    expect(page).to have_content "Secret"
  end

  step 'I click to remove application' do
    page.within '.oauth-applications' do
      click_on "Destroy"
    end
  end

  step "I see that application is removed" do
    expect(page.find(".oauth-applications")).not_to have_content "test_changed"
  end
end
