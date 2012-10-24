class Groups < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths

  Then 'I should see projects list' do
    current_user.projects.each do |project|
      page.should have_link project.name
    end
  end

  And 'I have group with projects' do
    @group   = Factory :group
    @project = Factory :project, group: @group
    @event   = Factory :closed_issue_event, project: @project

    @project.add_access current_user, :admin
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
      page.should have_content issue.title
    end
  end

  Given 'project from group has issues assigned to me' do
    create :issue,
      project: project,
      assignee: current_user,
      author: current_user
  end

  Given 'project from group has merge requests assigned to me' do
    create :merge_request,
      project: project,
      assignee: current_user,
      author: current_user
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
