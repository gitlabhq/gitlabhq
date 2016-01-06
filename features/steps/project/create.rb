class Spinach::Features::ProjectCreate < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedUser

  step 'fill project form with valid data' do
    fill_in 'project_path', with: 'Empty'
    click_button "Create project"
  end

  step 'I should see project page' do
    expect(page).to have_content "Empty"
    expect(current_path).to eq namespace_project_path(Project.last.namespace, Project.last)
  end

  step 'I should see empty project instuctions' do
    expect(page).to have_content "git init"
    expect(page).to have_content "git remote"
    expect(page).to have_content Project.last.url_to_repo
  end

  step 'I see empty project instuctions' do
    expect(page).to have_content "git init"
    expect(page).to have_content "git remote"
    expect(page).to have_content Project.last.url_to_repo
  end

  step 'I click on HTTP' do
    find('#clone-dropdown').click
    find('#http-selector').click
  end

  step 'Remote url should update to http link' do
    expect(page).to have_content "git remote add origin #{Project.last.http_url_to_repo}"
  end

  step 'If I click on SSH' do
    find('#clone-dropdown').click
    find('#ssh-selector').click
  end

  step 'Remote url should update to ssh link' do
    expect(page).to have_content "git remote add origin #{Project.last.url_to_repo}"
  end
end
