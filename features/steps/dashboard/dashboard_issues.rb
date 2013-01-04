class DashboardIssues < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths

  Then 'I should see issues assigned to me' do
    issues = @user.issues
    issues.each do |issue|
      page.should have_content(issue.title[0..10])
      page.should have_content(issue.project.name)
      page.should have_link(issue.project.name)
    end
  end

  And 'I have assigned issues' do
    project = create :project
    project.team << [@user, :master]

    2.times { create :issue, author: @user, assignee: @user, project: project }
  end
end
