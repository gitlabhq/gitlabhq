class ProjectBrowseFiles < Spinach::FeatureSteps
  Then 'I should see files from repository' do
    page.should have_content "app"
    page.should have_content "History"
    page.should have_content "Gemfile"
  end

  Given 'I visit project source page for "8470d70"' do
    visit tree_project_ref_path(@project, "8470d70")
  end

  Then 'I should see files from repository for "8470d70"' do
    current_path.should == tree_project_ref_path(@project, "8470d70")
    page.should have_content "app"
    page.should have_content "History"
    page.should have_content "Gemfile"
  end

  Given 'I click on "Gemfile" file in repo' do
    click_link "Gemfile"
  end

  Then 'I should see it content' do
    page.should have_content "rubygems.org"
  end

  Given 'I visit blob file from repo' do
    visit tree_project_ref_path(@project, ValidCommit::ID, :path => ValidCommit::BLOB_FILE_PATH)
  end

  And 'I click link "raw"' do
    click_link "raw"
  end

  Then 'I should see raw file content' do
    page.source.should == ValidCommit::BLOB_FILE
  end

  Given 'I sign in as a user' do
    login_as :user
  end

  And 'I own project "Shop"' do
    @project = Factory :project, :name => "Shop"
    @project.add_access(@user, :admin)
  end

  Given 'I visit project source page' do
    visit tree_project_ref_path(@project, @project.root_ref)
  end
end
