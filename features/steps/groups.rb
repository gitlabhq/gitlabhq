class Spinach::Features::Groups < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedGroup
  include SharedUser

  step 'I should see group "Owned"' do
    expect(page).to have_content 'Owned'
  end

  step 'I am a signed out user' do
    logout
  end

  step 'Group "Owned" has a public project "Public-project"' do
    group = owned_group

    @project = create :project, :public,
                 group: group,
                 name: "Public-project"
  end

  step 'I should see project "Public-project"' do
    expect(page).to have_content 'Public-project'
  end

  step 'I should see group "Owned" projects list' do
    owned_group.projects.each do |project|
      expect(page).to have_link project.name
    end
  end

  step 'I should see projects activity feed' do
    expect(page).to have_content 'joined project'
  end

  step 'I should see issues from group "Owned" assigned to me' do
    assigned_to_me(:issues).each do |issue|
      expect(page).to have_content issue.title
    end
  end

  step 'I should not see issues from the archived project' do
    @archived_project.issues.each do |issue|
      expect(page).not_to have_content issue.title
    end
  end

  step 'I should not see merge requests from the archived project' do
    @archived_project.merge_requests.each do |mr|
      expect(page).not_to have_content mr.title
    end
  end

  step 'I should see merge requests from group "Owned" assigned to me' do
    assigned_to_me(:merge_requests).each do |issue|
      expect(page).to have_content issue.title[0..80]
    end
  end

  step 'project from group "Owned" has issues assigned to me' do
    create :issue,
      project: project,
      assignees: [current_user],
      author: current_user
  end

  step 'project from group "Owned" has merge requests assigned to me' do
    create :merge_request,
      source_project: project,
      target_project: project,
      assignee: current_user,
      author: current_user
  end

  step 'I change group "Owned" avatar' do
    attach_file(:group_avatar, File.join(Rails.root, 'spec', 'fixtures', 'banana_sample.gif'))
    click_button "Save group"
    owned_group.reload
  end

  step 'I should see new group "Owned" avatar' do
    expect(owned_group.avatar).to be_instance_of AvatarUploader
    expect(owned_group.avatar.url).to eq "/uploads/-/system/group/avatar/#{Group.find_by(name: "Owned").id}/banana_sample.gif"
  end

  step 'I should see the "Remove avatar" button' do
    expect(page).to have_link("Remove avatar")
  end

  step 'I have group "Owned" avatar' do
    attach_file(:group_avatar, File.join(Rails.root, 'spec', 'fixtures', 'banana_sample.gif'))
    click_button "Save group"
    owned_group.reload
  end

  step 'I remove group "Owned" avatar' do
    click_link "Remove avatar"
    owned_group.reload
  end

  step 'I should not see group "Owned" avatar' do
    expect(owned_group.avatar?).to eq false
  end

  step 'I should not see the "Remove avatar" button' do
    expect(page).not_to have_link("Remove avatar")
  end

  step 'Group "Owned" has archived project' do
    group = Group.find_by(name: 'Owned')
    @archived_project = create(:project, :archived, namespace: group, path: "archived-project")
  end

  step 'I should see "archived" label' do
    expect(page).to have_xpath("//span[@class='label label-warning']", text: 'archived')
  end

  step 'I visit group "NonExistentGroup" page' do
    visit group_path("NonExistentGroup")
  end

  step 'the archived project have some issues' do
    create :issue,
      project: @archived_project,
      assignees: [current_user],
      author: current_user
  end

  step 'the archived project have some merge requests' do
    create :merge_request,
      source_project: @archived_project,
      target_project: @archived_project,
      assignee: current_user,
      author: current_user
  end

  private

  def assigned_to_me(key)
    project.send(key).assigned_to(current_user)
  end

  def project
    owned_group.projects.first
  end
end
