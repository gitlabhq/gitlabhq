class ProjectIssueTracker < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  step 'project "Shop" has issues enabled' do
    @project = Project.find_by(name: "Shop")
    @project ||= create(:project, name: "Shop", namespace: @user.namespace)
    @project.issues_enabled = true
  end

  step 'change the issue tracker to "GitLab"' do
    select 'GitLab', from: 'project_issues_tracker'
  end

  step 'I the project should have "GitLab" as issue tracker' do
    find_field('project_issues_tracker').value.should == 'gitlab'
  end

  step 'change the issue tracker to "Redmine"' do
    select 'Redmine', from: 'project_issues_tracker'
  end

  step 'I the project should have "Redmine" as issue tracker' do
    find_field('project_issues_tracker').value.should == 'redmine'
  end

  And 'I save project' do
    click_button 'Save changes'
  end
end
