class Spinach::Features::DashboardArchivedProjects < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject

  When 'project "Forum" is archived' do
    project = Project.find_by(name: "Forum")
    project.update_attribute(:archived, true)
  end

  step 'I should see "Shop" project link' do
    expect(page).to have_link "Shop"
  end

  step 'I should not see "Forum" project link' do
    expect(page).not_to have_link "Forum"
  end

  step 'I should see "Forum" project link' do
    expect(page).to have_link "Forum"
  end

  step 'I click "Show archived projects" link' do
    click_link "Show archived projects"
  end
end
