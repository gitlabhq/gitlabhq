class Spinach::Features::ProjectFfMergeRequests < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedIssuable
  include SharedProject
  include SharedNote
  include SharedPaths
  include SharedMarkdown
  include SharedDiffNote
  include SharedUser
  include WaitForRequests

  step 'project "Shop" have "Bug NS-05" open merge request with diffs inside' do
    create(:merge_request_with_diffs,
           title: "Bug NS-05",
           source_project: project,
           target_project: project,
           author: project.users.first)
  end

  step 'merge request is mergeable' do
    expect(page).to have_button 'Merge'
  end

  step 'I should see ff-only merge button' do
    expect(page).to have_content "Fast-forward merge without a merge commit"
    expect(page).to have_button 'Merge'
  end

  step 'merge request "Bug NS-05" is mergeable' do
    merge_request.mark_as_mergeable
  end

  step 'I accept this merge request' do
    page.within '.mr-state-widget' do
      click_button "Merge"
    end
  end

  step 'I should see merged request' do
    page.within '.status-box' do
      expect(page).to have_content "Merged"
      wait_for_requests
    end
  end

  step 'ff merge enabled' do
    project = merge_request.target_project
    project.merge_requests_ff_only_enabled = true
    project.save!
  end

  step 'I should see rebase button' do
    expect(page).to have_button "Rebase"
  end

  step 'merge request "Bug NS-05" is rebased' do
    merge_request.source_branch = 'flatten-dir'
    merge_request.target_branch = 'improve/awesome'
    merge_request.reload_diff
    merge_request.save!
  end

  step 'merge request "Bug NS-05" merged target' do
    merge_request.source_branch = 'merged-target'
    merge_request.target_branch = 'improve/awesome'
    merge_request.reload_diff
    merge_request.save!
  end

  step 'rebase before merge enabled' do
    project = merge_request.target_project
    project.merge_requests_rebase_enabled = true
    project.save!
  end

  step 'I press rebase button' do
    click_button "Rebase"
  end

  step "I should see rebase in progress message" do
    expect(page).to have_content("Rebase in progress")
  end

  def merge_request
    @merge_request ||= MergeRequest.find_by!(title: "Bug NS-05")
  end
end
