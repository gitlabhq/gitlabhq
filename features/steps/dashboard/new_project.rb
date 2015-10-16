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
  end

  step 'I see all possible import optios' do
    expect(page).to have_link('GitHub')
    expect(page).to have_link('Bitbucket')
    expect(page).to have_link('GitLab.com')
    expect(page).to have_link('Gitorious.org')
    expect(page).to have_link('Google Code')
    expect(page).to have_link('Any repo by URL')
  end

  step 'I click on "Import project from GitHub"' do
    first('.import_github').click
  end

  step 'I see instructions on how to import from GitHub' do
    github_modal = first('.modal-body')
    expect(github_modal).to be_visible
    expect(github_modal).to have_content "To enable importing projects from GitHub"

    page.all('.modal-body').each do |element|
      expect(element).not_to be_visible unless element == github_modal
    end
  end

  step 'I click on "Any repo by URL"' do
    first('.import_git').click
  end

  step 'I see instructions on how to import from Git URL' do
    git_import_instructions = first('.js-toggle-content')
    expect(git_import_instructions).to be_visible
    expect(git_import_instructions).to have_content "Git repository URL"
    expect(git_import_instructions).to have_content "The repository must be accessible over HTTP(S). If it is not publicly accessible, you can add authentication information to the URL:"
  end

  step 'I click on "Google Code"' do
    first('.import_google_code').click
  end

  step 'I redirected to Google Code import page' do
    expect(current_path).to eq new_import_google_code_path
  end

end
