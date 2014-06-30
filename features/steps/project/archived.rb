class ProjectArchived < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  When 'project "Forum" is archived' do
    project = Project.find_by(name: "Forum")
    project.update_attribute(:archived, true)
  end

  When 'project "Shop" is archived' do
    project = Project.find_by(name: "Shop")
    project.update_attribute(:archived, true)
  end

  When 'I visit project "Forum" page' do
    project = Project.find_by(name: "Forum")
    visit project_path(project)
  end

  Then 'I should not see "Archived"' do
    page.should_not have_content "Archived"
  end

  Then 'I should see "Archived"' do
    page.should have_content "Archived"
  end

  When 'I set project archived' do
    click_link "Archive"
  end

  When 'I set project unarchived' do
    click_link "Unarchive"
  end

end
