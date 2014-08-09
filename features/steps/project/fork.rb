class ForkProject < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject

  step 'I click link "Fork"' do
    page.should have_content "Shop"
    page.should have_content "Fork"
    click_link "Fork"
  end

  step 'I am a member of project "Shop"' do
    @project = create(:project, name: "Shop")
    @project.team << [@user, :reporter]
  end

  step 'I should see the forked project page' do
    page.should have_content "Project was successfully forked."
  end

  step 'I already have a project named "Shop" in my namespace' do
    @my_project = create(:project, name: "Shop", namespace: current_user.namespace)
  end

  step 'I should see a "Name has already been taken" warning' do
    page.should have_content "Name has already been taken"
  end
end
