class ProjectBrowseFiles < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  Then 'I should see files from repository' do
    page.should have_content "app"
    page.should have_content "history"
    page.should have_content "Gemfile"
  end

  Then 'I should see files from repository for "8470d70"' do
    current_path.should == project_tree_path(@project, "8470d70")
    page.should have_content "app"
    page.should have_content "history"
    page.should have_content "Gemfile"
  end

  Given 'I click on "Gemfile" file in repo' do
    click_link "Gemfile"
  end

  Then 'I should see it content' do
    page.should have_content "rubygems.org"
  end

  And 'I click link "raw"' do
    click_link "raw"
  end

  Then 'I should see raw file content' do
    page.source.should == ValidCommit::BLOB_FILE
  end

  Given 'I click button "edit"' do
    click_link 'edit'
  end

  Then 'I can edit code' do
    page.execute_script('editor.setValue("GitlabFileEditor")')
    page.evaluate_script('editor.getValue()').should == "GitlabFileEditor"
  end

end
