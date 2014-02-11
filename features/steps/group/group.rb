class Groups < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedUser
  include Select2Helper

  Then 'I should see projects list' do
    current_user.authorized_projects.each do |project|
      page.should have_link project.name
    end
  end

  And 'I have group with projects' do
    @group   = create(:group)
    @group.add_owner(current_user)
    @project = create(:project, namespace: @group)
    @event   = create(:closed_issue_event, project: @project)

    @project.team << [current_user, :master]
  end

  And 'I should see projects activity feed' do
    page.should have_content 'closed issue'
  end

  Then 'I should see issues from this group assigned to me' do
    assigned_to_me(:issues).each do |issue|
      page.should have_content issue.title
    end
  end

  Then 'I should see merge requests from this group assigned to me' do
    assigned_to_me(:merge_requests).each do |issue|
      page.should have_content issue.title[0..80]
    end
  end

  And 'I select user "John Doe" from list with role "Reporter"' do
    user = User.find_by(name: "John Doe")
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

  Given 'project from group has issues assigned to me' do
    create :issue,
      project: project,
      assignee: current_user,
      author: current_user
  end

  Given 'project from group has merge requests assigned to me' do
    create :merge_request,
      source_project: project,
      target_project: project,
      assignee: current_user,
      author: current_user
  end

  When 'I click new group link' do
    click_link "New group"
  end

  And 'submit form with new group info' do
    fill_in 'group_name', with: 'Samurai'
    fill_in 'group_description', with: 'Tokugawa Shogunate'
    click_button "Create group"
  end

  Then 'I should see newly created group' do
    page.should have_content "Samurai"
    page.should have_content "Tokugawa Shogunate"
    page.should have_content "You will only see events from projects in this group"
  end

  Then 'I should be redirected to group page' do
    current_path.should == group_path(Group.last)
  end

  And 'I change group name' do
    fill_in 'group_name', with: 'new-name'
    click_button "Save group"
  end

  Then 'I should see new group name' do
    within ".navbar-gitlab" do
      page.should have_content "group: new-name"
    end
  end

  step 'I change my group avatar' do
    attach_file(:group_avatar, File.join(Rails.root, 'public', 'gitlab_logo.png'))
    click_button "Save group"
    @group.reload
  end

  step 'I should see new group avatar' do
    @group.avatar.should be_instance_of AttachmentUploader
    @group.avatar.url.should == "/uploads/group/avatar/#{ @group.id }/gitlab_logo.png"
  end

  step 'I should see the "Remove avatar" button' do
    page.should have_link("Remove avatar")
  end

  step 'I have an group avatar' do
    attach_file(:group_avatar, File.join(Rails.root, 'public', 'gitlab_logo.png'))
    click_button "Save group"
    @group.reload
  end

  step 'I remove my group avatar' do
    click_link "Remove avatar"
    @group.reload
  end

  step 'I should not see my group avatar' do
    @group.avatar?.should be_false
  end

  step 'I should not see the "Remove avatar" button' do
    page.should_not have_link("Remove avatar")
  end

  protected

  def current_group
    @group ||= Group.first
  end

  def project
    current_group.projects.first
  end

  def assigned_to_me key
    project.send(key).where(assignee_id: current_user.id)
  end
end
