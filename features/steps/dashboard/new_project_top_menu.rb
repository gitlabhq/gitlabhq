class Spinach::Features::NewProjectTopMenu < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject

  step 'I click "New project" in top right menu' do
    page.within '.header-content' do
      click_link "New project"
    end
  end

  step 'I see "New Project" page' do
    expect(page).to have_content('Project path')
    expect(page).to have_content('Project name')
  end

end
