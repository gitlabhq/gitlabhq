class Spinach::Features::Profile < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths

  step 'I should see my profile info' do
    expect(page).to have_content "Profile settings"
  end

  step 'I change my profile info' do
    fill_in "user_skype", with: "testskype"
    fill_in "user_linkedin", with: "testlinkedin"
    fill_in "user_twitter", with: "testtwitter"
    fill_in "user_website_url", with: "testurl"
    click_button "Save changes"
    @user.reload
  end

  step 'I should see new profile info' do
    expect(@user.skype).to eq('testskype')
    expect(@user.linkedin).to eq('testlinkedin')
    expect(@user.twitter).to eq('testtwitter')
    expect(@user.website_url).to eq('testurl')
  end

  step 'I change my avatar' do
    attach_file(:user_avatar, File.join(Rails.root, 'public', 'gitlab_logo.png'))
    click_button "Save changes"
    @user.reload
  end

  step 'I should see new avatar' do
    expect(@user.avatar).to be_instance_of AttachmentUploader
    expect(@user.avatar.url).to eq("/uploads/user/avatar/#{ @user.id }/gitlab_logo.png")
  end

  step 'I should see the "Remove avatar" button' do
    expect(page).to have_link("Remove avatar")
  end

  step 'I have an avatar' do
    attach_file(:user_avatar, File.join(Rails.root, 'public', 'gitlab_logo.png'))
    click_button "Save changes"
    @user.reload
  end

  step 'I remove my avatar' do
    click_link "Remove avatar"
    @user.reload
  end

  step 'I should see my gravatar' do
    expect(@user.avatar?).to be_falsey
  end

  step 'I should not see the "Remove avatar" button' do
    expect(page).not_to have_link("Remove avatar")
  end

  step 'I try change my password w/o old one' do
    within '.update-password' do
      fill_in "user_password_profile", with: "22233344"
      fill_in "user_password_confirmation", with: "22233344"
      click_button "Save"
    end
  end

  step 'I try to set a weak password' do
    within '.update-password' do
      fill_in "user_password_profile", with: "22233344"
    end
  end

  step 'I try to set a short password' do
    within '.update-password' do
      fill_in "user_password_profile", with: "short"
    end
  end

  step 'I try to set a strong password' do
    within '.update-password' do
      fill_in "user_password_profile", with: "Itulvo9z8uud%$"
    end
  end

  step 'I change my password' do
    within '.update-password' do
      fill_in "user_current_password", with: "12345678"
      fill_in "user_password_profile", with: "22233344"
      fill_in "user_password_confirmation", with: "22233344"
      click_button "Save"
    end
  end

  step 'I unsuccessfully change my password' do
    within '.update-password' do
      fill_in "user_current_password", with: "12345678"
      fill_in "user_password_profile", with: "password"
      fill_in "user_password_confirmation", with: "confirmation"
      click_button "Save"
    end
  end

  step "I should see a missing password error message" do
    expect(page).to have_content "You must provide a valid current password"
  end

  step 'I should see the input field yellow' do
    expect(page).to have_css 'div.has-warning'
  end

  step 'I should see the input field green' do
    expect(page).to have_css 'div.has-success'
  end

  step 'I should see the input field red' do
    expect(page).to have_css 'div.has-error'
  end

  step 'I should see the password error message' do
    expect(page).to have_content 'Your password is too short'
  end

  step "I should see a password error message" do
    expect(page).to have_content "Password confirmation doesn't match"
  end

  step 'I reset my token' do
    within '.update-token' do
      @old_token = @user.private_token
      click_button "Reset"
    end
  end

  step 'I should see new token' do
    expect(find("#token").value).not_to eq(@old_token)
    expect(find("#token").value).to eq(@user.reload.private_token)
  end

  step 'I have activity' do
    create(:closed_issue_event, author: current_user)
  end

  step 'I should see my activity' do
    expect(page).to have_content "#{current_user.name} closed issue"
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
    expect(page).to have_selector('body.ui_color')
    expect(page).not_to have_selector('body.ui_basic')
  end

  step "I should receive feedback that the changes were saved" do
    expect(page).to have_content("saved")
  end

  step 'my password is expired' do
    current_user.update_attributes(password_expires_at: Time.now - 1.hour)
  end

  step "I am not an ldap user" do
    current_user.identities.delete
    expect(current_user.ldap_user?).to be_falsey
  end

  step 'I redirected to expired password page' do
    expect(current_path).to eq(new_profile_password_path)
  end

  step 'I submit new password' do
    fill_in :user_current_password, with: '12345678'
    fill_in :user_password_profile, with: '12345678'
    fill_in :user_password_confirmation, with: '12345678'
    click_button "Set new password"
  end

  step 'I redirected to sign in page' do
    expect(current_path).to eq(new_user_session_path)
  end

  step 'I should be redirected to password page' do
    expect(current_path).to eq(edit_profile_password_path)
  end

  step 'I should be redirected to account page' do
    expect(current_path).to eq(profile_account_path)
  end

  step 'I click on my profile picture' do
    click_link 'profile-pic'
  end

  step 'I should see my user page' do
    expect(page).to have_content "User Activity"

    within '.navbar-gitlab' do
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
end
