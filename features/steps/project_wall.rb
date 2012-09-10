class ProjectWall < Spinach::FeatureSteps
  Given 'I write new comment "my special test message"' do
    fill_in "note_note", :with => "my special test message"
    click_button "Add Comment"
  end

  Then 'I should see project wall note "my special test message"' do
    page.should have_content "my special test message"
  end

  Then 'I visit project "Shop" wall page' do
    project = Project.find_by_name("Shop")
    visit wall_project_path(project)
  end

  Given 'I signin as a user' do
    login_as :user
  end

  And 'I own project "Shop"' do
    @project = Factory :project, :name => "Shop"
    @project.add_access(@user, :admin)
  end
end
