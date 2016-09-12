class Spinach::Features::AdminGroups < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedGroup
  include SharedPaths
  include SharedUser
  include SharedActiveTab
  include Select2Helper

  When 'I visit admin group page' do
    visit admin_group_path(current_group)
  end

  When 'I click new group link' do
    click_link "New Group"
  end

  step 'I have group with projects' do
    @group   = create(:group)
    @project = create(:project, group: @group)
    @event   = create(:closed_issue_event, project: @project)

    @project.team << [current_user, :master]
  end

  step 'submit form with new group info' do
    fill_in 'group_path', with: 'gitlab'
    fill_in 'group_description', with: 'Group description'
    click_button "Create group"
  end

  step 'I should see newly created group' do
    expect(page).to have_content "Group: gitlab"
    expect(page).to have_content "Group description"
  end

  step 'I should be redirected to group page' do
    expect(current_path).to eq admin_group_path(Group.find_by(path: 'gitlab'))
  end

  When 'I select user "John Doe" from user list as "Reporter"' do
    find('#js-member-user-ids', visible: false).set(user_john.id)
    page.within "#new_project_member" do
      select "Reporter", from: "access_level"
    end
    click_button "Add users to group"
  end

  When 'I select user "johndoe@gitlab.com" from user list as "Reporter"' do
    find('#js-member-user-ids', visible: false).set('johndoe@gitlab.com')
    page.within "#new_project_member" do
      select "Reporter", from: "access_level"
    end
    click_button "Add users to group"
  end

  step 'I should see "John Doe" in team list in every project as "Reporter"' do
    page.within ".group-users-list" do
      expect(page).to have_content "John Doe"
      expect(page).to have_content "Reporter"
    end
  end

  step 'I should see "johndoe@gitlab.com" in team list in every project as "Reporter"' do
    page.within ".group-users-list" do
      expect(page).to have_content "johndoe@gitlab.com"
      expect(page).to have_content "Invited by"
      expect(page).to have_content "Reporter"
    end
  end

  step 'I should be all groups' do
    Group.all.each do |group|
      expect(page).to have_content group.name
    end
  end

  step 'group has shared projects' do
    share_link = shared_project.project_group_links.new(group_access: Gitlab::Access::MASTER)
    share_link.group_id = current_group.id
    share_link.save!
  end

  step 'I visit group page' do
    visit admin_group_path(current_group)
  end

  step 'I should see project shared with group' do
    expect(page).to have_content(shared_project.name_with_namespace)
    expect(page).to have_content "Projects shared with"
  end

  step 'we have user "John Doe" in group' do
    current_group.add_reporter(user_john)
  end

  step 'I should not see "John Doe" in team list' do
    page.within ".group-users-list" do
      expect(page).not_to have_content "John Doe"
    end
  end

  step 'I select current user as "Developer"' do
    page.within ".users-group-form" do
      find('#js-member-user-ids', visible: false).set(current_user.id)
      select "Developer", from: "access_level"
    end

    click_button "Add to group"
  end

  step 'I should see current user as "Developer"' do
    page.within '.content-list' do
      expect(page).to have_content(current_user.name)
      expect(page).to have_content('Developer')
    end
  end

  step 'I click on the "Remove User From Group" button for current user' do
    find(:css, 'li', text: current_user.name).find(:css, 'a.btn-remove').click
    # poltergeist always confirms popups.
  end

  step 'I should not see current user as "Developer"' do
    page.within '.content-list' do
      expect(page).not_to have_content(current_user.name)
      expect(page).not_to have_content('Developer')
    end
  end

  protected

  def current_group
    @group ||= Group.first
  end

  def shared_project
    @shared_project ||= create(:empty_project)
  end

  def user_john
    @user_john ||= User.find_by(name: "John Doe")
  end
end
