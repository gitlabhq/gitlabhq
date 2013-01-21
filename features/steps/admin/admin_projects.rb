class AdminProjects < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedAdmin

  And 'I should see all projects' do
    Project.all.each do |p|
      page.should have_content p.name_with_namespace
    end
  end

  And 'I click on first project' do
    click_link Project.first.name_with_namespace
  end

  Then 'I should see project details' do
    project = Project.first
    current_path.should == admin_project_path(project)

    page.should have_content(project.name_with_namespace)
    page.should have_content(project.creator.name)
    page.should have_content('Add new team member')
  end
end
