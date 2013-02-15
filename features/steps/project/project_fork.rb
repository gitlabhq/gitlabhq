class ForkProject < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject

  step 'I click link "Fork"' do
    click_link "Fork"
  end

  step 'I am a member of project "Shop"' do
    @project = Project.find_by_name "Shop"
    @project ||= create(:project, name: "Shop")
    @project.team << [@user, :reporter]
  end

  step 'I should see the forked project page' do
    page.should have_content "Project was successfully forked."
    current_path.should include current_user.namespace.path
  end

  step 'I should see a non-empty project page' do
    page.should_not have_content "Empty"
    page.should have_link "Files"
  end

  step 'I already have a project named "Shop" in my namespace' do
    @my_project = create(:project, name: "Shop", namespace: current_user.namespace)
  end

  step 'I should see a "Name has already been taken" warning' do
    page.should have_content "Name has already been taken"
  end

end