class DashboardIssues < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths

  step 'I should see issues assigned to me' do
    should_see(assigned_issue)
    should_not_see(authored_issue)
    should_not_see(other_issue)
  end

  step 'I should see issues authored by me' do
    should_see(authored_issue)
    should_not_see(assigned_issue)
    should_not_see(other_issue)
  end

  step 'I should see all issues' do
    should_see(authored_issue)
    should_see(assigned_issue)
    should_see(other_issue)
  end

  step 'I have authored issues' do
    authored_issue
  end

  step 'I have assigned issues' do
    assigned_issue
  end

  step 'I have other issues' do
    other_issue
  end

  step 'I click "Authored by me" link' do
    within ".scope-filter" do
      click_link 'Created by me'
    end
  end

  step 'I click "All" link' do
    within ".scope-filter" do
      click_link "Everyone's"
    end
  end

  def should_see(issue)
    page.should have_content(issue.title[0..10])
  end

  def should_not_see(issue)
    page.should_not have_content(issue.title[0..10])
  end

  def assigned_issue
    @assigned_issue ||= create :issue, assignee: current_user, project: project
  end

  def authored_issue
    @authored_issue ||= create :issue, author: current_user, project: project
  end

  def other_issue
    @other_issue ||= create :issue, project: project
  end

  def project
    @project ||= begin
                   project =create :project
                   project.team << [current_user, :master]
                   project
                 end
  end
end
