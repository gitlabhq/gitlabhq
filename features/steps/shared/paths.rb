module SharedPaths
  include Spinach::DSL

  And 'I visit dashboard search page' do
    visit search_path
  end

  And 'I visit dashboard merge requests page' do
    visit dashboard_merge_requests_path
  end

  And 'I visit dashboard issues page' do
    visit dashboard_issues_path
  end

  When 'I visit dashboard page' do
    visit dashboard_path
  end

  Given 'I visit profile page' do
    visit profile_path
  end

  Given 'I visit profile password page' do
    visit profile_password_path
  end

  Given 'I visit profile token page' do
    visit profile_token_path
  end

  When 'I visit new project page' do
    visit new_project_path
  end

  And 'I visit project "Shop" page' do
    project = Project.find_by_name("Shop")
    visit project_path(project)
  end

  Given 'I visit project branches page' do
    visit branches_project_repository_path(@project)
  end

  Given 'I visit compare refs page' do
    visit compare_project_commits_path(@project)
  end

  Given 'I visit project commits page' do
    visit project_commits_path(@project)
  end

  Given 'I visit project source page' do
    visit tree_project_ref_path(@project, @project.root_ref)
  end

  Given 'I visit blob file from repo' do
    visit tree_project_ref_path(@project, ValidCommit::ID, :path => ValidCommit::BLOB_FILE_PATH)
  end

  Given 'I visit project source page for "8470d70"' do
    visit tree_project_ref_path(@project, "8470d70")
  end

  Given 'I visit project tags page' do
    visit tags_project_repository_path(@project)
  end

  Given 'I visit project commit page' do
    visit project_commit_path(@project, ValidCommit::ID)
  end

  And 'I visit project "Shop" issues page' do
    visit project_issues_path(Project.find_by_name("Shop"))
  end

  Given 'I visit issue page "Release 0.4"' do
    issue = Issue.find_by_title("Release 0.4")
    visit project_issue_path(issue.project, issue)
  end

  Given 'I visit project "Shop" labels page' do
    visit project_labels_path(Project.find_by_name("Shop"))
  end

  Given 'I visit merge request page "Bug NS-04"' do
    mr = MergeRequest.find_by_title("Bug NS-04")
    visit project_merge_request_path(mr.project, mr)
  end

  And 'I visit project "Shop" merge requests page' do
    visit project_merge_requests_path(Project.find_by_name("Shop"))
  end

  Given 'I visit project "Shop" milestones page' do
    @project = Project.find_by_name("Shop")
    visit project_milestones_path(@project)
  end

  Then 'I visit project "Shop" team page' do
    visit team_project_path(Project.find_by_name("Shop"))
  end

  Then 'I visit project "Shop" wall page' do
    project = Project.find_by_name("Shop")
    visit wall_project_path(project)
  end

  Given 'I visit project wiki page' do
    visit project_wiki_path(@project, :index)
  end
end
