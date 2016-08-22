class Spinach::Features::GroupMembers < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedGroup
  include SharedUser
  include Select2Helper

  step 'I select "Mike" as "Reporter"' do
    user = User.find_by(name: "Mike")

    page.within ".users-group-form" do
      select2(user.id, from: "#user_ids", multiple: true)
      select "Reporter", from: "access_level"
    end

    click_button "Add users to group"
  end

  step 'I select "Mike" as "Master"' do
    user = User.find_by(name: "Mike")

    page.within ".users-group-form" do
      select2(user.id, from: "#user_ids", multiple: true)
      select "Master", from: "access_level"
    end

    click_button "Add users to group"
  end

  step 'I should see "Mike" in team list as "Reporter"' do
    page.within '.content-list' do
      expect(page).to have_content('Mike')
      expect(page).to have_content('Reporter')
    end
  end

  step 'I should see "Mike" in team list as "Owner"' do
    page.within '.content-list' do
      expect(page).to have_content('Mike')
      expect(page).to have_content('Owner')
    end
  end

  step 'I select "sjobs@apple.com" as "Reporter"' do
    page.within ".users-group-form" do
      select2("sjobs@apple.com", from: "#user_ids", multiple: true)
      select "Reporter", from: "access_level"
    end

    click_button "Add users to group"
  end

  step 'I should see "sjobs@apple.com" in team list as invited "Reporter"' do
    page.within '.content-list' do
      expect(page).to have_content('sjobs@apple.com')
      expect(page).to have_content('Invited')
      expect(page).to have_content('Reporter')
    end
  end

  step 'I select user "Mary Jane" from list with role "Reporter"' do
    user = User.find_by(name: "Mary Jane") || create(:user, name: "Mary Jane")

    page.within ".users-group-form" do
      select2(user.id, from: "#user_ids", multiple: true)
      select "Reporter", from: "access_level"
    end

    click_button "Add users to group"
  end

  step 'I should see user "John Doe" in team list' do
    expect(group_members_list).to have_content("John Doe")
  end

  step 'I should not see user "John Doe" in team list' do
    expect(group_members_list).not_to have_content("John Doe")
  end

  step 'I should see user "Mary Jane" in team list' do
    expect(group_members_list).to have_content("Mary Jane")
  end

  step 'I should not see user "Mary Jane" in team list' do
    expect(group_members_list).not_to have_content("Mary Jane")
  end

  step 'I click on the "Remove User From Group" button for "John Doe"' do
    find(:css, 'li', text: "John Doe").find(:css, 'a.btn-remove').click
    # poltergeist always confirms popups.
  end

  step 'I click on the "Remove User From Group" button for "Mary Jane"' do
    find(:css, 'li', text: "Mary Jane").find(:css, 'a.btn-remove').click
    # poltergeist always confirms popups.
  end

  step 'I should not see the "Remove User From Group" button for "John Doe"' do
    expect(find(:css, 'li', text: "John Doe")).not_to have_selector(:css, 'a.btn-remove')
    # poltergeist always confirms popups.
  end

  step 'I should not see the "Remove User From Group" button for "Mary Jane"' do
    expect(find(:css, 'li', text: "Mary Jane")).not_to have_selector(:css, 'a.btn-remove')
    # poltergeist always confirms popups.
  end

  step 'I search for \'Mary\' member' do
    page.within '.member-search-form' do
      fill_in 'search', with: 'Mary'
      click_button 'Search'
    end
  end

  step 'I change the "Mary Jane" role to "Developer"' do
    member = mary_jane_member

    page.within "#group_member_#{member.id}" do
      click_button 'Edit'
      select 'Developer', from: "member_access_level_#{member.id}"
      click_on 'Save'
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
    find(".panel .content-list")
  end
end
