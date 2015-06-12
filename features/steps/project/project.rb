class Spinach::Features::Project < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths
  include Select2Helper

  step 'change project settings' do
    fill_in 'project_name_edit', with: 'NewName'
    uncheck 'project_issues_enabled'
  end

  step 'I save project' do
    click_button 'Save changes'
  end

  step 'I should see project with new settings' do
    expect(find_field('project_name').value).to eq 'NewName'
    expect(find('#project_issues_enabled')).to_not be_checked
    expect(find('#project_merge_requests_enabled')).to be_checked
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
      File.join(Rails.root, 'public', 'gitlab_logo.png')
    )
    click_button 'Save changes'
    @project.reload
  end

  step 'I should see new project avatar' do
    expect(@project.avatar).to be_instance_of AvatarUploader
    url = @project.avatar.url
    expect(url).to eq "/uploads/project/avatar/#{ @project.id }/gitlab_logo.png"
  end

  step 'I should see the "Remove avatar" button' do
    expect(page).to have_link('Remove avatar')
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
    expect(@project.avatar?).to be_false
  end

  step 'I should not see the "Remove avatar" button' do
    expect(page).not_to have_link('Remove avatar')
  end

  step 'I fill in merge request template' do
    fill_in 'project_merge_requests_template', with: "This merge request should contain the following."
  end

  step 'I should see project with merge request template saved' do
    find_field('project_merge_requests_template').value.should == 'This merge request should contain the following.'
  end

  step 'I should see project "Shop" README link' do
    within '.project-side' do
      page.should have_content "README.md"
    end
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
    expect(page).to have_link 'README.md'
    expect(page).to have_content 'Sample repo for testing gitlab features'
  end

  step 'I should see project "Shop" README' do
    expect(page).to have_link 'README.md'
    expect(page).to have_content 'testme'
  end

  step 'gitlab user "Pete"' do
    create(:user, name: "Pete")
  end

  step '"Pete" is "Shop" developer' do
    user = User.find_by(name: "Pete")
    project = Project.find_by(name: "Shop")
    project.team << [user, :developer]
  end

  step 'I visit project "Shop" settings page' do
    click_link 'Settings'
  end

  step 'I go to "Members"' do
    click_link 'Members'
  end

  step 'I change "Pete" access level to master' do
    user = User.find_by(name: "Pete")
    project_member = @project.project_members.find_by(user_id: user)

    within "#project_member_#{project_member.id}" do
      click_button "Edit access level"
      select "Master", from: "project_member_access_level"
      click_button "Save"
    end

    sleep 0.05
  end

  step 'I go to "Audit Events"' do
    click_link 'Audit Events'
  end

  step 'I should see the audit event listed' do
    within ('table#audits') do
      page.should have_content "Change access level from developer to master"
      page.should have_content(project.owner.name)
      page.should have_content('Pete')
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
end
