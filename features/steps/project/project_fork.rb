class ForkProject < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject

  step 'I click link "Fork"' do
    page.should have_content "Shop"
    page.should have_content "Fork"
    Gitlab::Shell.any_instance.stub(:fork_repository).and_return(true)
    click_link "Fork"
  end

  step 'I am a member of project "Shop"' do
    @project = Project.find_by(name: "Shop")
    @project ||= create(:project, name: "Shop", group: create(:group))
    @project.team << [@user, :reporter]
  end

  step 'I should see the forked project page' do
    page.should have_content "Project was successfully forked."
    current_path.should include current_user.namespace.path
    @forked_project = Project.find_by(namespace_id: current_user.namespace.path)
  end

  step 'I already have a project named "Shop" in my namespace' do
    current_user.namespace ||= create(:namespace)
    current_user.namespace.should_not be_nil
    current_user.namespace.path.should_not be_nil
    @my_project = create(:project, name: "Shop", namespace: current_user.namespace)
  end

  step 'I should see a "Name has already been taken" warning' do
    page.should have_content "Name has already been taken"
  end

end
