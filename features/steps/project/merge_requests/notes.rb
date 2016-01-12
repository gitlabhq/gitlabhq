class Spinach::Features::ProjectMergeRequestsNotes < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedUser

  step 'I own public project "Public Shop"' do
    project = create :project, :public, name: 'Public Shop', namespace: current_user.namespace
    project.team << [current_user, :master]
  end

  step 'project "Public Shop" has "Public Issue 01" open issue' do
    project = Project.find_by(name: 'Public Shop')

    create(:issue,
           title: 'Public Issue 01',
           project: project,
           author: current_user,
           description: '# Description header'
          )
  end

  step 'I own private project "Private Library"' do
    project = create :project, name: 'Private Library', namespace: current_user.namespace
    project.team << [current_user, :master]
  end

  step 'project "Private Library" has "Private MR 01" open merge request' do
    project = Project.find_by!(name: 'Private Library')

    create(:merge_request,
           title: 'Private MR 01',
           source_project: project,
           target_project: project,
           source_branch: 'fix',
           target_branch: 'master',
           author: current_user,
           description: '# Description header'
          )
  end

  step 'I visit merge request page "Private MR 01"' do
    mr = MergeRequest.find_by(title: "Private MR 01")
    visit namespace_project_merge_request_path(mr.target_project.namespace, mr.target_project, mr)
  end

  step 'I leave a comment with link to issue "Public Issue 01"' do
    issue = Issue.find_by!(title: 'Public Issue 01')

    page.within(".js-main-target-form") do
      fill_in "note[note]", with: namespace_project_issue_url(issue.project.namespace, issue.project, issue)
      click_button "Add Comment"
    end
  end

  step 'I visit issue page "Public Issue 01"' do
    issue = Issue.find_by(title: "Public Issue 01")
    visit namespace_project_issue_path(issue.project.namespace, issue.project, issue)
  end

  step 'I should not see any related merge requests' do
    page.within '.issue-details' do
      expect(page).not_to have_content('.merge-requests')
    end
  end

  step 'I should see the "Private MR 01" related merge request' do
    page.within '.merge-requests' do
      expect(page).to have_content("1 Related Merge Request")
      expect(page).to have_content("Private MR 01")
    end
  end
end
