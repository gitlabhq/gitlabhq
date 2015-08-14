class Spinach::Features::ExploreGroups < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedGroup
  include SharedProject

  step 'group "TestGroup" has private project "Enterprise"' do
    group_has_project("TestGroup", "Enterprise", Gitlab::VisibilityLevel::PRIVATE)
  end

  step 'group "TestGroup" has internal project "Internal"' do
    group_has_project("TestGroup", "Internal", Gitlab::VisibilityLevel::INTERNAL)
  end

  step 'group "TestGroup" has public project "Community"' do
    group_has_project("TestGroup", "Community", Gitlab::VisibilityLevel::PUBLIC)
  end

  step '"John Doe" is owner of group "TestGroup"' do
    group = Group.find_by(name: "TestGroup") || create(:group, name: "TestGroup")
    user = create(:user, name: "John Doe")
    group.add_owner(user)
  end

  step 'I visit group "TestGroup" page' do
    visit group_path(Group.find_by(name: "TestGroup"))
  end

  step 'I visit group "TestGroup" issues page' do
    visit issues_group_path(Group.find_by(name: "TestGroup"))
  end

  step 'I visit group "TestGroup" merge requests page' do
    visit merge_requests_group_path(Group.find_by(name: "TestGroup"))
  end

  step 'I visit group "TestGroup" members page' do
    visit group_group_members_path(Group.find_by(name: "TestGroup"))
  end

  step 'I should not see project "Enterprise" items' do
    expect(page).not_to have_content "Enterprise"
  end

  step 'I should see project "Internal" items' do
    expect(page).to have_content "Internal"
  end

  step 'I should not see project "Internal" items' do
    expect(page).not_to have_content "Internal"
  end

  step 'I should see project "Community" items' do
    expect(page).to have_content "Community"
  end

  step 'I change filter to Everyone\'s' do
    click_link "Everyone's"
  end

  step 'I should see group member "John Doe"' do
    expect(page).to have_content "John Doe"
  end

  step 'I should not see member roles' do
    expect(body).not_to match(%r{owner|developer|reporter|guest}i)
  end

  protected

  def group_has_project(groupname, projectname, visibility_level)
    group = Group.find_by(name: groupname) || create(:group, name: groupname)
    project = create(:project,
      namespace: group,
      name: projectname,
      path: "#{groupname}-#{projectname}",
      visibility_level: visibility_level
    )
    create(:issue,
      title: "#{projectname} feature",
      project: project
    )
    create(:merge_request,
      title: "#{projectname} feature implemented",
      source_project: project,
      target_project: project
    )
    create(:closed_issue_event,
      project: project
    )
  end
end
