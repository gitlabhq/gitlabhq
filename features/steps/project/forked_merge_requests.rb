class Spinach::Features::ProjectForkedMergeRequests < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedNote
  include SharedPaths
  include Select2Helper
  include WaitForRequests
  include ProjectForksHelper

  step 'I am a member of project "Shop"' do
    @project = ::Project.find_by(name: "Shop")
    @project ||= create(:project, :repository, name: "Shop")
    @project.add_reporter(@user)
  end

  step 'I have a project forked off of "Shop" called "Forked Shop"' do
    @forked_project = fork_project(@project, @user,
                                   namespace: @user.namespace,
                                   repository: true)
  end

  step 'I click link "New Merge Request"' do
    page.within '#content-body' do
      page.has_link?('New Merge Request') ? click_link("New Merge Request") : click_link('New merge request')
    end
  end

  step 'I should see merge request "Merge Request On Forked Project"' do
    expect(@project.merge_requests.size).to be >= 1
    @merge_request = @project.merge_requests.last
    expect(current_path).to eq project_merge_request_path(@project, @merge_request)
    expect(@merge_request.title).to eq "Merge Request On Forked Project"
    expect(@merge_request.source_project).to eq @forked_project
    expect(@merge_request.source_branch).to eq "fix"
    expect(@merge_request.target_branch).to eq "master"
    expect(page).to have_content @forked_project.full_path
    expect(page).to have_content @project.full_path
    expect(page).to have_content @merge_request.source_branch
    expect(page).to have_content @merge_request.target_branch

    wait_for_requests
  end

  step 'I fill out a "Merge Request On Forked Project" merge request' do
    expect(page).to have_content('Source branch')
    expect(page).to have_content('Target branch')

    first('.js-source-project').click
    first('.dropdown-source-project a', text: @forked_project.full_path)

    first('.js-target-project').click
    first('.dropdown-target-project a', text: @project.full_path)

    first('.js-source-branch').click
    wait_for_requests
    first('.dropdown-source-branch .dropdown-content a', text: 'fix').click

    click_button "Compare branches and continue"

    expect(page).to have_css("h3.page-title", text: "New Merge Request")

    page.within 'form#new_merge_request' do
      fill_in "merge_request_title", with: "Merge Request On Forked Project"
    end
  end

  step 'I submit the merge request' do
    click_button "Submit merge request"
  end

  step 'I update the merge request title' do
    fill_in "merge_request_title", with: "An Edited Forked Merge Request"
  end

  step 'I save the merge request' do
    click_button "Save changes"
  end

  step 'I should see the edited merge request' do
    expect(page).to have_content "An Edited Forked Merge Request"
    expect(@project.merge_requests.size).to be >= 1
    @merge_request = @project.merge_requests.last
    expect(current_path).to eq project_merge_request_path(@project, @merge_request)
    expect(@merge_request.source_project).to eq @forked_project
    expect(@merge_request.source_branch).to eq "fix"
    expect(@merge_request.target_branch).to eq "master"
    expect(page).to have_content @forked_project.full_path
    expect(page).to have_content @project.full_path
    expect(page).to have_content @merge_request.source_branch
    expect(page).to have_content @merge_request.target_branch
  end

  step 'I should see last push widget' do
    expect(page).to have_content "You pushed to new_design"
    expect(page).to have_link "Create Merge Request"
  end

  step 'I click link edit "Merge Request On Forked Project"' do
    find("#edit_merge_request").click
  end

  step 'I see the edit page prefilled for "Merge Request On Forked Project"' do
    expect(current_path).to eq edit_project_merge_request_path(@project, @merge_request)
    expect(page).to have_content "Edit merge request #{@merge_request.to_reference}"
    expect(find("#merge_request_title").value).to eq "Merge Request On Forked Project"
  end

  step 'I fill out an invalid "Merge Request On Forked Project" merge request' do
    expect(find_by_id("merge_request_source_project_id", visible: false).value).to eq @forked_project.id.to_s
    expect(find_by_id("merge_request_target_project_id", visible: false).value).to eq @project.id.to_s
    expect(find_by_id("merge_request_source_branch", visible: false).value).to eq nil
    expect(find_by_id("merge_request_target_branch", visible: false).value).to eq "master"
    click_button "Compare branches"
  end

  step 'I should see validation errors' do
    expect(page).to have_content "You must select source and target branch"
  end

  step 'the target repository should be the original repository' do
    expect(find_by_id("merge_request_target_project_id").value).to eq "#{@project.id}"
  end

  step 'I click "Assign to" dropdown"' do
    click_button 'Assignee'
  end

  step 'I should see the target project ID in the input selector' do
    expect(find('.js-assignee-search')["data-project-id"]).to eq "#{@project.id}"
  end

  step 'I should see the users from the target project ID' do
    page.within '.dropdown-menu-user' do
      expect(page).to have_content 'Unassigned'
      expect(page).to have_content current_user.name
      expect(page).to have_content @project.users.first.name
    end
  end
end
