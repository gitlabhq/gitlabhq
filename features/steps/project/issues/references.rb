class Spinach::Features::ProjectIssuesReferences < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedNote
  include SharedProject
  include SharedUser

  step 'project "Community" has "Public Issue 01" open issue' do
    project = Project.find_by(name: 'Community')
    create(:issue,
           title: 'Public Issue 01',
           project: project,
           author: project.users.first,
           description: '# Description header'
          )
  end

  step 'project "Private Library" has "Fix NS-01" open merge request' do
    project = Project.find_by(name: 'Private Library')
    create(:merge_request,
           title: 'Fix NS-01',
           source_project: project,
           target_project: project,
           source_branch: 'fix',
           target_branch: 'master',
           author: project.users.first,
           description: '# Description header'
          )
  end

  step 'project "Private Library" has "Private Issue 01" open issue' do
    project = Project.find_by(name: 'Private Library')
    create(:issue,
           title: 'Private Issue 01',
           project: project,
           author: project.users.first,
           description: '# Description header'
          )
  end

  step 'I leave a comment referencing issue "Public Issue 01" from "Fix NS-01" merge request' do
    project = Project.find_by(name: 'Private Library')
    issue = Issue.find_by!(title: 'Public Issue 01')

    page.within(".js-main-target-form") do
      fill_in "note[note]", with: "##{issue.to_reference(project)}"
      click_button "Add Comment"
    end
  end

  step 'I leave a comment referencing issue "Public Issue 01" from "Private Issue 01" issue' do
    project = Project.find_by(name: 'Private Library')
    issue = Issue.find_by!(title: 'Public Issue 01')

    page.within(".js-main-target-form") do
      fill_in "note[note]", with: "##{issue.to_reference(project)}"
      click_button "Add Comment"
    end
  end

  step 'I visit merge request page "Fix NS-01"' do
    mr = MergeRequest.find_by(title: "Fix NS-01")
    visit namespace_project_merge_request_path(mr.target_project.namespace, mr.target_project, mr)
  end

  step 'I visit issue page "Private Issue 01"' do
    issue = Issue.find_by(title: "Private Issue 01")
    visit namespace_project_issue_path(issue.project.namespace, issue.project, issue)
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

  step 'I should see the "Fix NS-01" related merge request' do
    page.within '.merge-requests' do
      expect(page).to have_content("1 Related Merge Request")
      expect(page).to have_content('Fix NS-01')
    end
  end

  step 'I should see a note linking to "Fix NS-01" merge request' do
    project = Project.find_by(name: 'Community')
    mr = MergeRequest.find_by(title: 'Fix NS-01')
    page.within('.notes') do
      expect(page).to have_content('Mary Jane')
      expect(page).to have_content("mentioned in merge request #{mr.to_reference(project)}")
    end
  end

  step 'I should see a note linking to "Private Issue 01" issue' do
    project = Project.find_by(name: 'Community')
    issue = Issue.find_by(title: 'Private Issue 01')
    page.within('.notes') do
      expect(page).to have_content('Mary Jane')
      expect(page).to have_content("mentioned in issue #{issue.to_reference(project)}")
    end
  end

end
