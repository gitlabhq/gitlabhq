class DashboardIssues < Spinach::FeatureSteps
  Then 'I should see issues assigned to me' do
    issues = @user.issues
    issues.each do |issue|
      page.should have_content(issue.title[0..10])
      page.should have_content(issue.project.name)
    end
  end

  Given 'I sign in as a user' do
    login_as :user
  end

  And 'I have assigned issues' do
    project = Factory :project
    project.add_access(@user, :read, :write)

    issue1 = Factory :issue,
      :author => @user,
      :assignee => @user,
      :project => project

    issue2 = Factory :issue,
      :author => @user,
      :assignee => @user,
      :project => project
  end

  And 'I visit dashboard issues page' do
    visit dashboard_issues_path
  end
end
