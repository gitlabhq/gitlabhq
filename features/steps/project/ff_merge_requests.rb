class Spinach::Features::ProjectFfMergeRequests < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedIssuable
  include SharedProject
  include SharedNote
  include SharedPaths
  include SharedMarkdown
  include SharedDiffNote
  include SharedUser

  step 'project "Shop" have "Bug NS-05" open merge request with diffs inside' do
    create(:merge_request_with_diffs,
           title: "Bug NS-05",
           source_project: project,
           target_project: project,
           author: project.users.first)
  end

  step 'merge request is mergeable' do
    expect(page).to have_button 'Accept Merge Request'
  end

  step 'I should see ff-only merge button' do
    expect(page).to have_content "Fast-forward merge without creating merge commit"
    expect(page).to have_button 'Accept Merge Request'
  end

  step 'merge request "Bug NS-05" is mergeable' do
    merge_request.mark_as_mergeable
  end

  step 'I accept this merge request' do
    page.within '.mr-state-widget' do
      click_button "Accept Merge Request"
    end
  end

  step 'I should see merged request' do
    page.within '.issue-box' do
      expect(page).to have_content "Merged"
    end
  end

  step 'ff merge enabled' do
    project = merge_request.target_project
    project.merge_requests_ff_only_enabled = true
    project.save!
  end

  step 'I should not see rebase button' do
    expect(page).to_not have_button "Rebase"
  end

  step 'I should see rebase button' do
    expect(page).to have_button "Rebase"
  end

  step 'I should see rebase message' do
    expect(page).to have_content "Fast-forward merge is not possible. Branch must be rebased first"
  end

  step 'merge request "Bug NS-05" is rebased' do
    merge_request.source_branch = 'flatten-dir'
    merge_request.target_branch = 'improve/awesome'
    merge_request.reload_code
    merge_request.save!
  end

  step 'rebase before merge enabled' do
    project = merge_request.target_project
    project.merge_requests_rebase_enabled = true
    project.save!
  end

  step 'I press rebase button' do
    allow(RebaseWorker).to receive(:perform_async){ true }
    click_button "Rebase"
  end

  step "I should see rebase in progress message" do
    expect(page).to have_content("Rebase in progress")
  end

  def merge_request
    @merge_request ||= MergeRequest.find_by!(title: "Bug NS-05")
  end
end
