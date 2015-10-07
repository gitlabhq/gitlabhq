class Spinach::Features::ProjectFork < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject

  step 'I click link "Fork"' do
    expect(page).to have_content "Shop"
    click_link "Fork project"
  end

  step 'I am a member of project "Shop"' do
    @project = create(:project, name: "Shop")
    @project.team << [@user, :reporter]
  end

  step 'I should see the forked project page' do
    expect(page).to have_content "Forked from"
  end

  step 'I already have a project named "Shop" in my namespace' do
    @my_project = create(:project, name: "Shop", namespace: current_user.namespace)
  end

  step 'I should see a "Name has already been taken" warning' do
    expect(page).to have_content "Name has already been taken"
  end

  step 'I fork to my namespace' do
    page.within '.fork-namespaces' do
      click_link current_user.name
    end
  end
end
