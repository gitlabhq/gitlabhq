class ProjectBrowseFiles < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths
  include RepoHelpers

  step 'I should see files from repository' do
    page.should have_content "VERSION"
    page.should have_content ".gitignore"
    page.should have_content "LICENSE"
  end

  step 'I should see files from repository for "6d39438"' do
    current_path.should == project_tree_path(@project, "6d39438")
    page.should have_content ".gitignore"
    page.should have_content "LICENSE"
  end

  step 'I click on ".gitignore" file in repo' do
    click_link ".gitignore"
  end

  step 'I should see it content' do
    page.should have_content "*.rbc"
  end

  step 'I click link "raw"' do
    click_link "raw"
  end

  step 'I should see raw file content' do
    page.source.should == sample_blob.data
  end

  step 'I click button "edit"' do
    click_link 'edit'
  end

  step 'I can edit code' do
    page.execute_script('editor.setValue("GitlabFileEditor")')
    page.evaluate_script('editor.getValue()').should == "GitlabFileEditor"
  end

  step 'I edit code' do
    page.execute_script('editor.setValue("GitlabFileEditor")')
  end

  step 'I click link "Diff"' do
    click_link 'Diff'
  end

  step 'I see diff' do
    page.should have_css '.line_holder.new'
  end

  step 'I click on "new file" link in repo' do
    click_link 'new-file-link'
  end

  step 'I can see new file page' do
    page.should have_content "New file"
    page.should have_content "File name"
    page.should have_content "Commit message"
  end

  step 'I click on files directory' do
    click_link 'files'
  end

  step 'I click on history link' do
    click_link 'history'
  end

  step 'I see Browse dir link' do
    page.should have_link 'Browse Dir »'
    page.should_not have_link 'Browse Code »'
  end

  step 'I click on readme file' do
    click_link 'README.md'
  end

  step 'I see Browse file link' do
    page.should have_link 'Browse File »'
    page.should_not have_link 'Browse Code »'
  end

  step 'I see Browse code link' do
    page.should have_link 'Browse Code »'
    page.should_not have_link 'Browse File »'
    page.should_not have_link 'Browse Dir »'
  end
end
