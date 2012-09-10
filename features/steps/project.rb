class Projects < Spinach::FeatureSteps
  Given 'I sign in as a user' do
    login_as :user
  end

  And 'I own project "Shop"' do
    @project = Factory :project, :name => "Shop"
    @project.add_access(@user, :admin)
  end

  And 'I visit project "Shop" page' do
    project = Project.find_by_name("Shop")
    visit project_path(project)
  end
end
