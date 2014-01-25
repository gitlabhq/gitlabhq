class ProjectFeature < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  step 'change project settings' do
    fill_in 'project_name', with: 'NewName'
    uncheck 'project_issues_enabled'
  end

  step 'I save project' do
    click_button 'Save changes'
  end

  step 'I should see project with new settings' do
    find_field('project_name').value.should == 'NewName'
  end

  step 'change project path settings' do
    fill_in 'project_path', with: 'new-path'
    click_button 'Rename'
  end

  step 'I should see project with new path settings' do
    project.path.should == 'new-path'
  end

  step 'I change the project avatar' do
    attach_file(
      :project_avatar,
      File.join(Rails.root, 'public', 'gitlab_logo.png')
    )
    click_button 'Save changes'
    @project.reload
  end

  step 'I should see new project avatar' do
    @project.avatar.should be_instance_of AttachmentUploader
    url = @project.avatar.url
    url.should == "/uploads/project/avatar/#{ @project.id }/gitlab_logo.png"
  end

  step 'I should see the "Remove avatar" button' do
    page.should have_link('Remove avatar')
  end

  step 'I have an project avatar' do
    attach_file(
      :project_avatar,
      File.join(Rails.root, 'public', 'gitlab_logo.png')
    )
    click_button 'Save changes'
    @project.reload
  end

  step 'I remove my project avatar' do
    click_link 'Remove avatar'
    @project.reload
  end

  step 'I should see the default project avatar' do
    @project.avatar?.should be_false
  end

  step 'I should not see the "Remove avatar" button' do
    page.should_not have_link('Remove avatar')
  end

  step 'I should see project "Shop" README link' do
    within '.project-side' do
      page.should have_content "README.md"
    end
  end

  step 'I should see project "Shop" version' do
    within '.project-side' do
      page.should have_content "Version: 2.2.0"
    end
  end

  step 'change project default branch' do
    select 'stable', from: 'project_default_branch'
  end

  step 'I should see project default branch changed' do
    # TODO: Uncomment this when we can do real gitlab-shell calls
    # from spinach tests. Right now gitlab-shell calls are stubbed so this test
    # will not pass
    # find(:css, 'select#project_default_branch').value.should == 'stable'
  end
end
