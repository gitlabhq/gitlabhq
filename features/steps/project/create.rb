class Spinach::Features::ProjectCreate < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths

  step 'fill project form with valid data' do
    fill_in 'project_name', with: 'Empty'
    click_button "Create project"
  end

  step 'I should see project page' do
    page.should have_content "Empty"
    current_path.should == project_path(Project.last)
  end

  step 'I should see empty project instuctions' do
    page.should have_content "git init"
    page.should have_content "git remote"
    page.should have_content Project.last.url_to_repo
  end

  step 'I see empty project instuctions' do
    page.should have_content "git init"
    page.should have_content "git remote"
    page.should have_content Project.last.url_to_repo
  end

  step 'I click on HTTP' do
    click_button 'HTTP'
  end

  step 'Remote url should update to http link' do
    page.should have_content "git remote add origin #{Project.last.http_url_to_repo}"
  end

  step 'If I click on SSH' do
    click_button 'SSH'
  end

  step 'Remote url should update to ssh link' do
    page.should have_content "git remote add origin #{Project.last.url_to_repo}"
  end
end
