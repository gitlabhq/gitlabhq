class Groups < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedGroup
  include SharedUser
  include Select2Helper

  Then 'I should see group "Owned" projects list' do
    Group.find_by(name: "Owned").projects.each do |project|
      page.should have_link project.name
    end
  end

  And 'I should see projects activity feed' do
    page.should have_content 'closed issue'
  end

  Then 'I should see issues from group "Owned" assigned to me' do
    assigned_to_me(:issues).each do |issue|
      page.should have_content issue.title
    end
  end

  Then 'I should see merge requests from group "Owned" assigned to me' do
    assigned_to_me(:merge_requests).each do |issue|
      page.should have_content issue.title[0..80]
    end
  end

  And 'I select user "Mary Jane" from list with role "Reporter"' do
    user = User.find_by(name: "Mary Jane") || create(:user, name: "Mary Jane")
    click_link 'Add members'
    within ".users-group-form" do
      select2(user.id, from: "#user_ids", multiple: true)
      select "Reporter", from: "group_access"
    end
    click_button "Add users into group"
  end

  Then 'I should see user "John Doe" in team list' do
    projects_with_access = find(".ui-box .well-list")
    projects_with_access.should have_content("John Doe")
  end

  Then 'I should not see user "John Doe" in team list' do
    projects_with_access = find(".ui-box .well-list")
    projects_with_access.should_not have_content("John Doe")
  end

  Then 'I should see user "Mary Jane" in team list' do
    projects_with_access = find(".ui-box .well-list")
    projects_with_access.should have_content("Mary Jane")
  end

  Then 'I should not see user "Mary Jane" in team list' do
    projects_with_access = find(".ui-box .well-list")
    projects_with_access.should_not have_content("Mary Jane")
  end

  Given 'project from group "Owned" has issues assigned to me' do
    create :issue,
      project: project,
      assignee: current_user,
      author: current_user
  end

  Given 'project from group "Owned" has merge requests assigned to me' do
    create :merge_request,
      source_project: project,
      target_project: project,
      assignee: current_user,
      author: current_user
  end

  When 'I click new group link' do
    click_link "New group"
  end

  And 'submit form with new group "Samurai" info' do
    fill_in 'group_name', with: 'Samurai'
    fill_in 'group_description', with: 'Tokugawa Shogunate'
    click_button "Create group"
  end

  Then 'I should be redirected to group "Samurai" page' do
    current_path.should == group_path(Group.last)
  end

  Then 'I should see newly created group "Samurai"' do
    page.should have_content "Samurai"
    page.should have_content "Tokugawa Shogunate"
    page.should have_content "You will only see events from projects in this group"
  end

  And 'I change group "Owned" name to "new-name"' do
    fill_in 'group_name', with: 'new-name'
    click_button "Save group"
  end

  Then 'I should see new group "Owned" name' do
    within ".navbar-gitlab" do
      page.should have_content "group: new-name"
    end
  end

  step 'I change group "Owned" avatar' do
    attach_file(:group_avatar, File.join(Rails.root, 'public', 'gitlab_logo.png'))
    click_button "Save group"
    Group.find_by(name: "Owned").reload
  end

  step 'I should see new group "Owned" avatar' do
    Group.find_by(name: "Owned").avatar.should be_instance_of AttachmentUploader
    Group.find_by(name: "Owned").avatar.url.should == "/uploads/group/avatar/#{ Group.find_by(name:"Owned").id }/gitlab_logo.png"
  end

  step 'I should see the "Remove avatar" button' do
    page.should have_link("Remove avatar")
  end

  step 'I have group "Owned" avatar' do
    attach_file(:group_avatar, File.join(Rails.root, 'public', 'gitlab_logo.png'))
    click_button "Save group"
    Group.find_by(name: "Owned").reload
  end

  step 'I remove group "Owned" avatar' do
    click_link "Remove avatar"
    Group.find_by(name: "Owned").reload
  end

  step 'I should not see group "Owned" avatar' do
    Group.find_by(name: "Owned").avatar?.should be_false
  end

  step 'I should not see the "Remove avatar" button' do
    page.should_not have_link("Remove avatar")
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
    find(:css, 'li', text: "John Doe").should_not have_selector(:css, 'a.btn-remove')
    # poltergeist always confirms popups.
  end

  step 'I should not see the "Remove User From Group" button for "Mary Jane"' do
    find(:css, 'li', text: "Mary Jane").should_not have_selector(:css, 'a.btn-remove')
    # poltergeist always confirms popups.
  end

  step 'I search for \'Mary\' member' do
    within '.member-search-form' do
      fill_in 'search', with: 'Mary'
      click_button 'Search'
    end
  end

  protected

  def assigned_to_me key
    project.send(key).where(assignee_id: current_user.id)
  end

  def project
    Group.find_by(name: "Owned").projects.first
  end
end
