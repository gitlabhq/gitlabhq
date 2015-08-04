class Spinach::Features::ProjectArchived < Spinach::FeatureSteps
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
    visit namespace_project_path(project.namespace, project)
  end

  step 'I should not see "Archived"' do
    expect(page).not_to have_content "Archived"
  end

  step 'I should see "Archived"' do
    expect(page).to have_content "Archived"
  end

  When 'I set project archived' do
    click_link "Archive"
  end

  When 'I set project unarchived' do
    click_link "Unarchive"
  end

end
