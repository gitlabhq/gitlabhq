class Spinach::Features::NewProject < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject

  step 'I click "New Project" link' do
    page.within('.content') do
      click_link "New Project"
    end
  end

  step 'I see "New Project" page' do
    expect(page).to have_content('Project path')
    expect(page).to have_content('Project name')
  end

  step 'I see all possible import options' do
    expect(page).to have_link('GitHub')
    expect(page).to have_link('Bitbucket')
    expect(page).to have_link('GitLab.com')
    expect(page).to have_link('Gitorious.org')
    expect(page).to have_link('Google Code')
    expect(page).to have_link('Repo by URL')
  end

  step 'I click on "Import project from GitHub"' do
    first('.import_github').click
  end

  step 'I am redirected to the GitHub import page' do
    expect(current_path).to eq new_import_github_path
  end

  step 'I click on "Repo by URL"' do
    first('.import_git').click
  end

  step 'I see instructions on how to import from Git URL' do
    git_import_instructions = first('.js-toggle-content')
    expect(git_import_instructions).to be_visible
    expect(git_import_instructions).to have_content "Git repository URL"
  end

  step 'I click on "Google Code"' do
    first('.import_google_code').click
  end

  step 'I redirected to Google Code import page' do
    expect(current_path).to eq new_import_google_code_path
  end
end
