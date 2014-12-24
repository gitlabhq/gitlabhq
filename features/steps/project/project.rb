class Spinach::Features::Project < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  step 'change project settings' do
    fill_in 'project_name_edit', with: 'NewName'
    uncheck 'project_issues_enabled'
  end

  step 'I save project' do
    click_button 'Save changes'
  end

  step 'I should see project with new settings' do
    expect(find_field('project_name').value).to eq('NewName')
  end

  step 'change project path settings' do
    fill_in "project_path", with: "new-path"
    click_button "Rename"
  end

  step 'I should see project with new path settings' do
    expect(project.path).to eq("new-path")
  end

  step 'I should see project "Shop" version' do
    within '.project-side' do
      expect(page).to have_content "Version: 6.7.0.pre"
    end
  end

  step 'change project default branch' do
    select 'fix', from: 'project_default_branch'
    click_button 'Save changes'
  end

  step 'I should see project default branch changed' do
    expect(find(:css, 'select#project_default_branch').value).to eq('fix')
  end

  step 'I select project "Forum" README tab' do
    click_link 'Readme'
  end

  step 'I should see project "Forum" README' do
    expect(page).to have_link "README.md"
    expect(page).to have_content "Sample repo for testing gitlab features"
  end

  step 'I should see project "Shop" README' do
    expect(page).to have_link "README.md"
    expect(page).to have_content "testme"
  end
end
