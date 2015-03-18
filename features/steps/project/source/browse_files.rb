class Spinach::Features::ProjectSourceBrowseFiles < Spinach::FeatureSteps
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
    current_path.should == namespace_project_tree_path(@project.namespace, @project, "6d39438")
    page.should have_content ".gitignore"
    page.should have_content "LICENSE"
  end

  step 'I see the ".gitignore"' do
    page.should have_content '.gitignore'
  end

  step 'I don\'t see the ".gitignore"' do
    page.should_not have_content '.gitignore'
  end

  step 'I click on ".gitignore" file in repo' do
    click_link ".gitignore"
  end

  step 'I should see its content' do
    page.should have_content old_gitignore_content
  end

  step 'I should see its new content' do
    page.should have_content new_gitignore_content
  end

  step 'I click link "Raw"' do
    click_link 'Raw'
  end

  step 'I should see raw file content' do
    source.should == sample_blob.data
  end

  step 'I click button "Edit"' do
    click_link 'Edit'
  end

  step 'I cannot see the edit button' do
    page.should_not have_link 'edit'
  end

  step 'The edit button is disabled' do
    page.should have_css '.disabled', text: 'Edit'
  end

  step 'I can edit code' do
    set_new_content
    evaluate_script('blob.editor.getValue()').should == new_gitignore_content
  end

  step 'I edit code' do
    set_new_content
  end

  step 'I fill the new file name' do
    fill_in :file_name, with: new_file_name
  end

  step 'I fill the new branch name' do
    fill_in :new_branch, with: 'new_branch_name'
  end

  step 'I fill the new file name with an illegal name' do
    fill_in :file_name, with: '.git'
  end

  step 'I fill the commit message' do
    fill_in :commit_message, with: 'Not yet a commit message.'
  end

  step 'I click link "Diff"' do
    click_link 'Preview changes'
  end

  step 'I click on "Commit Changes"' do
    click_button 'Commit Changes'
  end

  step 'I click on "Remove"' do
    click_button 'Remove'
  end

  step 'I click on "Remove file"' do
    click_button 'Remove file'
  end

  step 'I see diff' do
    page.should have_css '.line_holder.new'
  end

  step 'I click on "new file" link in repo' do
    click_link 'new-file-link'
  end

  step 'I can see new file page' do
    page.should have_content "New file"
    page.should have_content "Commit message"
  end

  step 'I click on files directory' do
    click_link 'files'
  end

  step 'I click on History link' do
    click_link 'History'
  end

  step 'I see Browse dir link' do
    page.should have_link 'Browse Dir »'
    page.should_not have_link 'Browse Code »'
  end

  step 'I click on readme file' do
    within '.tree-table' do
      click_link 'README.md'
    end
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

  step 'I click on Permalink' do
    click_link 'Permalink'
  end

  step 'I am redirected to the files URL' do
    current_path.should == namespace_project_tree_path(@project.namespace, @project, 'master')
  end

  step 'I am redirected to the ".gitignore"' do
    expect(current_path).to eq(namespace_project_blob_path(@project.namespace, @project, 'master/.gitignore'))
  end

  step 'I am redirected to the ".gitignore" on new branch' do
    expect(current_path).to eq(namespace_project_blob_path(@project.namespace, @project, 'new_branch_name/.gitignore'))
  end

  step 'I am redirected to the permalink URL' do
    expect(current_path).to(
      eq(namespace_project_blob_path(@project.namespace, @project,
                                     @project.repository.commit.sha +
                                     '/.gitignore'))
    )
  end

  step 'I am redirected to the new file' do
    expect(current_path).to eq(namespace_project_blob_path(
      @project.namespace, @project, 'master/' + new_file_name))
  end

  step 'I am redirected to the new file on new branch' do
    expect(current_path).to eq(namespace_project_blob_path(
      @project.namespace, @project, 'new_branch_name/' + new_file_name))
  end

  step "I don't see the permalink link" do
    expect(page).not_to have_link('permalink')
  end

  step 'I see a commit error message' do
    expect(page).to have_content('Your changes could not be committed')
  end

  step 'I create bare repo' do
    click_link 'Create empty bare repository'
  end

  step 'I click on "add a file" link' do
    click_link 'add a file'

    # Remove pre-receive hook so we can push without auth
    FileUtils.rm_f(File.join(@project.repository.path, 'hooks', 'pre-receive'))
  end

  private

  def set_new_content
    execute_script("blob.editor.setValue('#{new_gitignore_content}')")
  end

  # Content of the gitignore file on the seed repository.
  def old_gitignore_content
    '*.rbc'
  end

  # Constant value that differs from the content
  # of the gitignore of the seed repository.
  def new_gitignore_content
    old_gitignore_content + 'a'
  end

  # Constant value that is a valid filename and
  # not a filename present at root of the seed repository.
  def new_file_name
    'not_a_file.md'
  end
end
