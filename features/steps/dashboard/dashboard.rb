class Dashboard < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject

  Then 'I should see "New Project" link' do
    page.should have_link "New Project"
  end

  Then 'I should see "Shop" project link' do
    page.should have_link "Shop"
  end

  Then 'I should see last push widget' do
    page.should have_content "You pushed to new_design"
    page.should have_link "Create Merge Request"
  end

  And 'I click "Create Merge Request" link' do
    click_link "Create Merge Request"
  end

  Then 'I see prefilled new Merge Request page' do
    current_path.should == new_project_merge_request_path(@project)
    find("#merge_request_source_branch").value.should == "new_design"
    find("#merge_request_target_branch").value.should == "master"
    find("#merge_request_title").value.should == "New Design"
  end

  Given 'user with name "John Doe" joined project "Shop"' do
    user = create(:user, {name: "John Doe"})
    project = Project.find_by_name "Shop"
    Event.create(
      project: project,
      author_id: user.id,
      action: Event::Joined
    )
  end

  Then 'I should see "John Doe joined project at Shop" event' do
    page.should have_content "John Doe joined project at Shop"
  end

  And 'user with name "John Doe" left project "Shop"' do
    user = User.find_by_name "John Doe"
    project = Project.find_by_name "Shop"
    Event.create(
      project: project,
      author_id: user.id,
      action: Event::Left
    )
  end

  Then 'I should see "John Doe left project at Shop" event' do
    page.should have_content "John Doe left project at Shop"
  end

  And 'I have group with projects' do
    @group   = create(:group)
    @project = create(:project, group: @group)
    @event   = create(:closed_issue_event, project: @project)

    @project.team << [current_user, :master]
  end

  Then 'I should see projects list' do
    @user.authorized_projects.all.each do |project|
      page.should have_link project.name_with_namespace
    end
  end

  Then 'I should see groups list' do
    Group.all.each do |group|
      page.should have_link group.name
    end
  end

  And 'group has a projects that does not belongs to me' do
    @forbidden_project1 = create(:project, group: @group)
    @forbidden_project2 = create(:project, group: @group)
  end

  Then 'I should see 1 project at group list' do
    page.find('span.last_activity/span').should have_content('1')
  end
end
