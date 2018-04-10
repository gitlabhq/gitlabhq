class Spinach::Features::GroupMembers < Spinach::FeatureSteps
  include WaitForRequests
  include SharedAuthentication
  include SharedPaths
  include SharedGroup
  include SharedUser

  step 'I should see user "John Doe" in team list' do
    expect(group_members_list).to have_content("John Doe")
  end

  step 'I should not see user "Mary Jane" in team list' do
    expect(group_members_list).not_to have_content("Mary Jane")
  end

  step 'I click on the "Remove User From Group" button for "John Doe"' do
    find(:css, '.project-members-page li', text: "John Doe").find(:css, 'a.btn-remove').click
    # poltergeist always confirms popups.
  end

  step 'I click on the "Remove User From Group" button for "Mary Jane"' do
    find(:css, 'li', text: "Mary Jane").find(:css, 'a.btn-remove').click
    # poltergeist always confirms popups.
  end

  step 'I should not see the "Remove User From Group" button for "John Doe"' do
    expect(find(:css, '.project-members-page li', text: "John Doe")).not_to have_selector(:css, 'a.btn-remove')
    # poltergeist always confirms popups.
  end

  step 'I should not see the "Remove User From Group" button for "Mary Jane"' do
    expect(find(:css, 'li', text: "Mary Jane")).not_to have_selector(:css, 'a.btn-remove')
    # poltergeist always confirms popups.
  end

  step 'I change the "Mary Jane" role to "Developer"' do
    member = mary_jane_member

    page.within "#group_member_#{member.id}" do
      click_button member.human_access

      page.within '.dropdown-menu' do
        click_link 'Developer'
      end

      wait_for_requests
    end
  end

  step 'I should see "Mary Jane" as "Developer"' do
    member = mary_jane_member

    page.within "#group_member_#{member.id}" do
      expect(page).to have_content "Developer"
    end
  end

  private

  def mary_jane_member
    user = User.find_by(name: "Mary Jane")
    owned_group.members.find_by(user_id: user.id)
  end

  def group_members_list
    find(".card .content-list")
  end
end
