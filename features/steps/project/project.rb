class ProjectFeature < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  And 'change project settings' do
    fill_in 'project_name', with: 'NewName'
    uncheck 'project_issues_enabled'
  end

  And 'I save project' do
    click_button 'Save'
  end

  Then 'I should see project with new settings' do
    find_field('project_name').value.should == 'NewName'
  end
end
