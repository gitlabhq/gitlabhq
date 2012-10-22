class Groups < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths

  When 'I visit group page' do
    visit group_path(current_group)
  end

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

  protected

  def current_group
    @group ||= Group.first
  end
end
