class Spinach::Features::Invites < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedUser
  include SharedGroup

  step '"John Doe" has invited "user@example.com" to group "Owned"' do
    user = User.find_by(name: "John Doe")
    group = Group.find_by(name: "Owned")
    group.add_developer("user@example.com", user)
  end

  step 'I visit the invitation page' do
    group = Group.find_by(name: "Owned")
    invite = group.group_members.invite.last
    invite.generate_invite_token!
    @raw_invite_token = invite.raw_invite_token
    visit invite_path(@raw_invite_token)
  end

  step 'I should be redirected to the sign in page' do
    expect(current_path).to eq(new_user_session_path)
  end

  step 'I should see a notice telling me to sign in' do
    expect(page).to have_content "To accept this invitation, sign in"
  end

  step 'I should be redirected to the invitation page' do
    expect(current_path).to eq(invite_path(@raw_invite_token))
  end

  step 'I should see the invitation details' do
    expect(page).to have_content("You have been invited by John Doe to join group Owned as Developer.")
  end

  step "I should see a message telling me I'm already a member" do
    expect(page).to have_content("However, you are already a member of this group.")
  end

  step 'I should see an "Accept invitation" button' do
    expect(page).to have_link("Accept invitation")
  end

  step 'I should see a "Decline" button' do
    expect(page).to have_link("Decline")
  end

  step 'I click the "Accept invitation" button' do
    page.click_link "Accept invitation"
  end

  step 'I should be redirected to the group page' do
    group = Group.find_by(name: "Owned")
    expect(current_path).to eq(group_path(group))
  end

  step 'I should see a notice telling me I have access' do
    expect(page).to have_content("You have been granted Developer access to group Owned.")
  end

  step 'I click the "Decline" button' do
    page.click_link "Decline"
  end

  step 'I should be redirected to the dashboard' do
    expect(current_path).to eq(dashboard_path)
  end

  step 'I should see a notice telling me I have declined' do
    expect(page).to have_content("You have declined the invitation to join group Owned.")
  end

  step "I visit the invitation's decline page" do
    group = Group.find_by(name: "Owned")
    invite = group.group_members.invite.last
    invite.generate_invite_token!
    @raw_invite_token = invite.raw_invite_token
    visit decline_invite_path(@raw_invite_token)
  end
end
