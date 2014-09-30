class Spinach::Features::Dashboard < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject

  step 'I should see "New Project" link' do
    page.should have_link "New project"
  end

  step 'I should see "Shop" project link' do
    page.should have_link "Shop"
  end

  step 'I should see last push widget' do
    page.should have_content "You pushed to fix"
    page.should have_link "Create Merge Request"
  end

  step 'I click "Create Merge Request" link' do
    click_link "Create Merge Request"
  end

  step 'I see prefilled new Merge Request page' do
    current_path.should == new_project_merge_request_path(@project)
    find("#merge_request_target_project_id").value.should == @project.id.to_s
    find("#merge_request_source_branch").value.should == "fix"
    find("#merge_request_target_branch").value.should == "master"
  end

  step 'user with name "John Doe" joined project "Shop"' do
    user = create(:user, {name: "John Doe"})
    project.team << [user, :master]
    Event.create(
      project: project,
      author_id: user.id,
      action: Event::JOINED
    )
  end

  step 'I should see "John Doe joined project at Shop" event' do
    page.should have_content "John Doe joined project at #{project.name_with_namespace}"
  end

  step 'user with name "John Doe" left project "Shop"' do
    user = User.find_by(name: "John Doe")
    Event.create(
      project: project,
      author_id: user.id,
      action: Event::LEFT
    )
  end

  step 'I should see "John Doe left project at Shop" event' do
    page.should have_content "John Doe left project at #{project.name_with_namespace}"
  end

  step 'I have group with projects' do
    @group   = create(:group)
    @project = create(:project, namespace: @group)
    @event   = create(:closed_issue_event, project: @project)

    @project.team << [current_user, :master]
  end

  step 'I should see projects list' do
    @user.authorized_projects.all.each do |project|
      page.should have_link project.name_with_namespace
    end
  end

  step 'I should see groups list' do
    Group.all.each do |group|
      page.should have_link group.name
    end
  end

  step 'group has a projects that does not belongs to me' do
    @forbidden_project1 = create(:project, group: @group)
    @forbidden_project2 = create(:project, group: @group)
  end

  step 'I should see 1 project at group list' do
    find('span.last_activity/span').should have_content('1')
  end
end
