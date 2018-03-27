# coding: utf-8
class Spinach::Features::ProjectSourceBrowseFiles < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths
  include RepoHelpers
  include WaitForRequests

  step "I don't have write access" do
    @project = create(:project, :repository, name: "Other Project", path: "other-project")
    @project.add_reporter(@user)
    visit project_tree_path(@project, root_ref)
  end

  step 'I should see files from repository' do
    expect(page).to have_content "VERSION"
    expect(page).to have_content ".gitignore"
    expect(page).to have_content "LICENSE"
  end

  step 'I should see files from repository for "6d39438"' do
    expect(current_path).to eq project_tree_path(@project, "6d39438")
    expect(page).to have_content ".gitignore"
    expect(page).to have_content "LICENSE"
  end

  step 'I see the ".gitignore"' do
    expect(page).to have_content '.gitignore'
  end

  step 'I don\'t see the ".gitignore"' do
    expect(page).not_to have_content '.gitignore'
  end

  step 'I click on ".gitignore" file in repo' do
    click_link ".gitignore"
  end

  step 'I should see its content' do
    wait_for_requests
    expect(page).to have_content old_gitignore_content
  end

  step 'I should see its new content' do
    wait_for_requests
    expect(page).to have_content new_gitignore_content
  end

  step 'I click link "Raw"' do
    click_link 'Open raw'
  end

  step 'I should see raw file content' do
    expect(source).to eq '' # Body is filled in by gitlab-workhorse
  end

  step 'I click button "Edit"' do
    find('.js-edit-blob').click
  end

  step 'I cannot see the edit button' do
    expect(page).not_to have_link 'edit'
  end

  step 'I click button "Fork"' do
    click_link 'Fork'
  end

  step 'I edit code' do
    expect(page).to have_selector('.file-editor')
    set_new_content
  end

  step 'I fill the new file name' do
    fill_in :file_name, with: new_file_name
  end

  step 'I fill the new branch name' do
    fill_in :branch_name, with: 'new_branch_name', visible: true
  end

  step 'I fill the new file name with a new directory' do
    fill_in :file_name, with: new_file_name_with_directory
  end

  step 'I fill the commit message' do
    fill_in :commit_message, with: 'New commit message', visible: true
  end

  step 'I click link "Diff"' do
    click_link 'Preview changes'
  end

  step 'I click on "Commit changes"' do
    click_button 'Commit changes'
  end

  step 'I click on "Changes" tab' do
    click_link 'Changes'
  end

  step 'I click on "Create directory"' do
    click_button 'Create directory'
  end

  step 'I click on "Delete"' do
    click_on 'Delete'
  end

  step 'I click on "Delete file"' do
    click_button 'Delete file'
  end

  step 'I click on "Replace"' do
    click_on  "Replace"
  end

  step 'I click on "Replace file"' do
    click_button  'Replace file'
  end

  step 'I see diff' do
    expect(page).to have_css '.line_holder.new'
  end

  step 'I click on "New file" link in repo' do
    find('.add-to-tree').click
    click_link 'New file'
    expect(page).to have_selector('.file-editor')
  end

  step 'I click on "Upload file" link in repo' do
    find('.add-to-tree').click
    click_link 'Upload file'
  end

  step 'I click on "New directory" link in repo' do
    find('.add-to-tree').click
    click_link 'New directory'
  end

  step 'I fill the new directory name' do
    fill_in :dir_name, with: new_dir_name
  end

  step 'I fill an existing directory name' do
    fill_in :dir_name, with: 'files'
  end

  step 'I can see new file page' do
    expect(page).to have_content "New File"
    expect(page).to have_content "Commit message"
  end

  step 'I click on "Upload file"' do
    click_button 'Upload file'
  end

  step 'I can see the new commit message' do
    expect(page).to have_content "New commit message"
  end

  step 'I upload a new text file' do
    drop_in_dropzone test_text_file
  end

  step 'I fill the upload file commit message' do
    page.within('#modal-upload-blob') do
      fill_in :commit_message, with: 'New commit message'
    end
  end

  step 'I replace it with a text file' do
    drop_in_dropzone test_text_file
  end

  step 'I fill the replace file commit message' do
    page.within('#modal-upload-blob') do
      fill_in :commit_message, with: 'Replacement file commit message'
    end
  end

  step 'I can see the replacement commit message' do
    expect(page).to have_content "Replacement file commit message"
  end

  step 'I can see the new text file' do
    expect(page).to have_content "Lorem ipsum dolor sit amet"
    expect(page).to have_content "Sed ut perspiciatis unde omnis"
  end

  step 'I click on files directory' do
    click_link 'files'
  end

  step 'I click on History link' do
    click_link 'History'
  end

  step 'I see Browse dir link' do
    expect(page).to have_link 'Browse Directory'
    expect(page).not_to have_link 'Browse Code'
  end

  step 'I click on readme file' do
    page.within '.tree-table' do
      click_link 'README.md'
    end
  end

  step 'I see Browse file link' do
    expect(page).to have_link 'Browse File'
    expect(page).not_to have_link 'Browse Files'
  end

  step 'I see Browse code link' do
    expect(page).to have_link 'Browse Files'
    expect(page).not_to have_link 'Browse Directory'
  end

  step 'I click on Permalink' do
    click_link 'Permalink'
  end

  step 'I am redirected to the files URL' do
    expect(current_path).to eq project_tree_path(@project, 'master')
  end

  step 'I am redirected to the ".gitignore"' do
    expect(current_path).to eq(project_blob_path(@project, 'master/.gitignore'))
  end

  step 'I am redirected to the permalink URL' do
    expect(current_path).to(
      eq(project_blob_path(@project,
                                     @project.repository.commit.sha +
                                     '/.gitignore'))
    )
  end

  step 'I am redirected to the new file' do
    expect(current_path).to eq(
      project_blob_path(@project, 'master/' + new_file_name))
  end

  step 'I am redirected to the new file with directory' do
    expect(current_path).to eq(
      project_blob_path(@project, 'master/' + new_file_name_with_directory))
  end

  step 'I am redirected to the new merge request page' do
    expect(current_path).to eq(project_new_merge_request_path(@project))
  end

  step "I am redirected to the fork's new merge request page" do
    fork = @user.fork_of(@project)
    expect(current_path).to eq(project_new_merge_request_path(fork))
  end

  step 'I am redirected to the root directory' do
    expect(current_path).to eq(
      project_tree_path(@project, 'master'))
  end

  step "I don't see the permalink link" do
    expect(page).not_to have_link('permalink')
  end

  step 'I see "Unable to create directory"' do
    expect(page).to have_content('A directory with this name already exists')
  end

  step 'I see "Path can contain only..."' do
    expect(page).to have_content('Path can contain only')
  end

  step 'I see a commit error message' do
    expect(page).to have_content('Your changes could not be committed')
  end

  step "I switch ref to 'test'" do
    first('.js-project-refs-dropdown').click

    page.within '.project-refs-form' do
      click_link "'test'"
    end
  end

  step "I switch ref to fix" do
    first('.js-project-refs-dropdown').click

    page.within '.project-refs-form' do
      click_link 'fix'
    end
  end

  step "I see the ref 'test' has been selected" do
    expect(page).to have_selector '.dropdown-toggle-text', text: "'test'"
  end

  step "I visit the 'test' tree" do
    visit project_tree_path(@project, "'test'")
  end

  step "I visit the fix tree" do
    visit project_tree_path(@project, "fix/.testdir")
  end

  step 'I see the commit data' do
    expect(page).to have_css('.tree-commit-link', visible: true)
    expect(page).not_to have_content('Loading commit data...')
  end

  step 'I see the commit data for a directory with a leading dot' do
    expect(page).to have_css('.tree-commit-link', visible: true)
    expect(page).not_to have_content('Loading commit data...')
  end

  step 'I click on "files/lfs/lfs_object.iso" file in repo' do
    allow_any_instance_of(Project).to receive(:lfs_enabled?).and_return(true)
    visit project_tree_path(@project, "lfs")
    click_link 'files'
    click_link "lfs"
    click_link "lfs_object.iso"
  end

  step 'I should see download link and object size' do
    expect(page).to have_content 'Download (1.5 MB)'
  end

  step 'I should not see lfs pointer details' do
    expect(page).not_to have_content 'version https://git-lfs.github.com/spec/v1'
    expect(page).not_to have_content 'oid sha256:91eff75a492a3ed0dfcb544d7f31326bc4014c8551849c192fd1e48d4dd2c897'
    expect(page).not_to have_content 'size 1575078'
  end

  step 'I should see buttons for allowed commands' do
    page.within '.content' do
      expect(page).to have_link 'Download'
      expect(page).to have_content 'History'
      expect(page).to have_content 'Permalink'
      expect(page).not_to have_content 'Edit'
      expect(page).not_to have_content 'Blame'
      expect(page).to have_content 'Delete'
      expect(page).to have_content 'Replace'
    end
  end

  step 'I should see a Fork/Cancel combo' do
    expect(page).to have_link 'Fork'
    expect(page).to have_button 'Cancel'
  end

  step 'I should see a notice about a new fork having been created' do
    expect(page).to have_content "You're not allowed to make changes to this project directly. A fork of this project has been created that you can make changes in, so you can submit a merge request."
  end

  # SVG files
  step 'I upload a new SVG file' do
    drop_in_dropzone test_svg_file
  end

  step 'I visit the SVG file' do
    visit project_blob_path(@project, 'new_branch_name/logo_sample.svg')
  end

  step 'I can see the new rendered SVG image' do
    expect(page).to have_css('.file-content img')
  end

  private

  def set_new_content
    find('#editor')
    execute_script("ace.edit('editor').setValue('#{new_gitignore_content}')")
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

  # Constant value that is a valid filename with directory and
  # not a filename present at root of the seed repository.
  def new_file_name_with_directory
    'foo/bar/baz.txt'
  end

  # Constant value that is a valid directory and
  # not a directory present at root of the seed repository.
  def new_dir_name
    'new_dir/subdir'
  end

  def drop_in_dropzone(file_path)
    # Generate a fake input selector
    page.execute_script <<-JS
      var fakeFileInput = window.$('<input/>').attr(
        {id: 'fakeFileInput', type: 'file'}
      ).appendTo('body');
    JS
    # Attach the file to the fake input selector with Capybara
    attach_file("fakeFileInput", file_path)
    # Add the file to a fileList array and trigger the fake drop event
    page.execute_script <<-JS
      var fileList = [$('#fakeFileInput')[0].files[0]];
      var e = jQuery.Event('drop', { dataTransfer : { files : fileList } });
      $('.dropzone')[0].dropzone.listeners[0].events.drop(e);
    JS
  end

  def test_text_file
    File.join(Rails.root, 'spec', 'fixtures', 'doc_sample.txt')
  end

  def test_image_file
    File.join(Rails.root, 'spec', 'fixtures', 'banana_sample.gif')
  end

  def test_svg_file
    File.join(Rails.root, 'spec', 'fixtures', 'logo_sample.svg')
  end
end
