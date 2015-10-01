class Spinach::Features::Project < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  step 'change project settings' do
    fill_in 'project_name_edit', with: 'NewName'
    uncheck 'project_issues_enabled'
  end

  step 'I save project' do
    click_button 'Save changes'
  end

  step 'I should see project with new settings' do
    expect(find_field('project_name').value).to eq 'NewName'
  end

  step 'change project path settings' do
    fill_in 'project_path', with: 'new-path'
    click_button 'Rename'
  end

  step 'I should see project with new path settings' do
    expect(project.path).to eq 'new-path'
  end

  step 'I change the project avatar' do
    attach_file(
      :project_avatar,
      File.join(Rails.root, 'spec', 'fixtures', 'banana_sample.gif')
    )
    click_button 'Save changes'
    @project.reload
  end

  step 'I should see new project avatar' do
    expect(@project.avatar).to be_instance_of AvatarUploader
    url = @project.avatar.url
    expect(url).to eq "/uploads/project/avatar/#{ @project.id }/banana_sample.gif"
  end

  step 'I should see the "Remove avatar" button' do
    expect(page).to have_link('Remove avatar')
  end

  step 'I have an project avatar' do
    attach_file(
      :project_avatar,
      File.join(Rails.root, 'spec', 'fixtures', 'banana_sample.gif')
    )
    click_button 'Save changes'
    @project.reload
  end

  step 'I remove my project avatar' do
    click_link 'Remove avatar'
    @project.reload
  end

  step 'I should see the default project avatar' do
    expect(@project.avatar?).to eq false
  end

  step 'I should not see the "Remove avatar" button' do
    expect(page).not_to have_link('Remove avatar')
  end

  step 'I should see project "Shop" version' do
    page.within '.project-side' do
      expect(page).to have_content '6.7.0.pre'
    end
  end

  step 'change project default branch' do
    select 'fix', from: 'project_default_branch'
    click_button 'Save changes'
  end

  step 'I should see project default branch changed' do
    expect(find(:css, 'select#project_default_branch').value).to eq 'fix'
  end

  step 'I select project "Forum" README tab' do
    click_link 'Readme'
  end

  step 'I should see project "Forum" README' do
    page.within('#README') do
      expect(page).to have_content 'Sample repo for testing gitlab features'
    end
  end

  step 'I should see project "Shop" README' do
    page.within('#README') do
      expect(page).to have_content 'testme'
    end
  end

  step 'I add project tags' do
    fill_in 'Tags', with: 'tag1, tag2'
  end

  step 'I should see project tags' do
    expect(find_field('Tags').value).to eq 'tag1, tag2'
  end

  step 'I should not see "New Issue" button' do
    expect(page).not_to have_link 'New Issue'
  end

  step 'I should not see "New Merge Request" button' do
    expect(page).not_to have_link 'New Merge Request'
  end

  step 'I should not see "Snippets" button' do
    expect(page).not_to have_link 'Snippets'
  end

  step 'project "Shop" belongs to group' do
    group = create(:group)
    @project.namespace = group
    @project.save!
  end

  step 'I should see back to dashboard button' do
    expect(page).to have_content 'Back to dashboard'
  end

  step 'I should see back to group button' do
    expect(page).to have_content 'Back to group'
  end

  step 'I click notifications drop down button' do
    click_link 'notifications-button'
  end

  step 'I choose Mention setting' do
    click_link 'On mention'
  end

  step 'I should see Notification saved message' do
    page.within '.flash-container' do
      expect(page).to have_content 'Notification settings saved'
    end
  end
end
