class Spinach::Features::Dashboard < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject

  step 'I should see "New Project" link' do
    expect(page).to have_link "New project"
  end

  step 'I should see "Shop" project link' do
    expect(page).to have_link "Shop"
  end

  step 'I should see "Shop" project CI status' do
    expect(page).to have_link "Build status: skipped"
  end

  step 'I should see last push widget' do
    expect(page).to have_content "You pushed to fix"
    expect(page).to have_link "Create Merge Request"
  end

  step 'I click "Create Merge Request" link' do
    click_link "Create Merge Request"
  end

  step 'I see prefilled new Merge Request page' do
    expect(current_path).to eq new_namespace_project_merge_request_path(@project.namespace, @project)
    expect(find("#merge_request_target_project_id").value).to eq @project.id.to_s
    expect(find("input#merge_request_source_branch").value).to eq "fix"
    expect(find("input#merge_request_target_branch").value).to eq "master"
  end

  step 'user with name "John Doe" joined project "Shop"' do
    user = create(:user, { name: "John Doe" })
    project.team << [user, :master]
    Event.create(
      project: project,
      author_id: user.id,
      action: Event::JOINED
    )
  end

  step 'I should see "John Doe joined project Shop" event' do
    expect(page).to have_content "John Doe joined project #{project.name_with_namespace}"
  end

  step 'user with name "John Doe" left project "Shop"' do
    user = User.find_by(name: "John Doe")
    Event.create(
      project: project,
      author_id: user.id,
      action: Event::LEFT
    )
  end

  step 'I should see "John Doe left project Shop" event' do
    expect(page).to have_content "John Doe left project #{project.name_with_namespace}"
  end

  step 'I have group with projects' do
    @group   = create(:group)
    @project = create(:project, namespace: @group)
    @event   = create(:closed_issue_event, project: @project)

    @project.team << [current_user, :master]
  end

  step 'I should see projects list' do
    @user.authorized_projects.all.each do |project|
      expect(page).to have_link project.name_with_namespace
    end
  end

  step 'I should see groups list' do
    Group.all.each do |group|
      expect(page).to have_link group.name
    end
  end

  step 'group has a projects that does not belongs to me' do
    @forbidden_project1 = create(:project, group: @group)
    @forbidden_project2 = create(:project, group: @group)
  end

  step 'I should see 1 project at group list' do
    expect(find('span.last_activity/span')).to have_content('1')
  end
end
