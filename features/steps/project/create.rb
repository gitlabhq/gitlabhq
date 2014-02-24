class CreateProject < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths

  And 'fill project form with valid data' do
    fill_in 'project_name', with: 'Empty'
    click_button "Create project"
  end

  Then 'I should see project page' do
    current_path.should == project_path(Project.last)
    page.should have_content "Empty"
  end

  And 'I should see empty project instuctions' do
    page.should have_content "git init"
    page.should have_content "git remote"
    page.should have_content Project.last.url_to_repo
  end

  Then 'I see empty project instuctions' do
    page.should have_content "git init"
    page.should have_content "git remote"
    page.should have_content Project.last.url_to_repo
  end

  And 'I click on HTTP' do
    click_button 'HTTP'
  end

  Then 'Remote url should update to http link' do
    page.should have_content "git remote add origin #{Project.last.http_url_to_repo}"
  end

  And 'If I click on SSH' do
    click_button 'SSH'
  end

  Then 'Remote url should update to ssh link' do
    page.should have_content "git remote add origin #{Project.last.url_to_repo}"
  end
end
