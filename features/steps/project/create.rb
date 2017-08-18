class Spinach::Features::ProjectCreate < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedUser

  step 'fill project form with valid data' do
    fill_in 'project_path', with: 'Empty'
    page.within '#content-body' do
      click_button "Create project"
    end
  end

  step 'I should see project page' do
    expect(page).to have_content "Empty"
    expect(current_path).to eq project_path(Project.last)
  end

  step 'I should see empty project instructions' do
    expect(page).to have_content "git init"
    expect(page).to have_content "git remote"
    expect(page).to have_content Project.last.url_to_repo
  end
end
