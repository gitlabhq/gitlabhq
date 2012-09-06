Given /^I visit project "(.*?)" issues page$/ do |arg1|
  visit project_issues_path(Project.find_by_name(arg1))
end

Given /^I visit issue page "(.*?)"$/ do |arg1|
  issue = Issue.find_by_title(arg1)
  visit project_issue_path(issue.project, issue)
end

Given /^I visit project "(.*?)" merge requests page$/ do |arg1|
  visit project_merge_requests_path(Project.find_by_name(arg1))
end

Given /^I visit merge request page "(.*?)"$/ do |arg1|
  mr = MergeRequest.find_by_title(arg1)
  visit project_merge_request_path(mr.project, mr)
end

Given /^I visit project "(.*?)" milestones page$/ do |arg1|
  @project = Project.find_by_name(arg1)
  visit project_milestones_path(@project)
end

Given /^I visit project commits page$/ do
  visit project_commits_path(@project)
end

Given /^I visit compare refs page$/ do
  visit compare_project_commits_path(@project)
end

Given /^I visit project branches page$/ do
  visit branches_project_repository_path(@project)
end

Given /^I visit project commit page$/ do
  visit project_commit_path(@project, ValidCommit::ID)
end

Given /^I visit project tags page$/ do
  visit tags_project_repository_path(@project)
end

Given /^I click on commit link$/ do
  visit project_commit_path(@project, ValidCommit::ID)
end

Given /^I visit project source page$/ do
  visit tree_project_ref_path(@project, @project.root_ref)
end

Given /^I visit project source page for "(.*?)"$/ do |arg1|
  visit tree_project_ref_path(@project, arg1)
end

Given /^I visit blob file from repo$/ do
  visit tree_project_ref_path(@project, ValidCommit::ID, :path => ValidCommit::BLOB_FILE_PATH)
end

Given /^I visit project "(.*?)" team page$/ do |arg1|
  visit team_project_path(Project.find_by_name(arg1))
end

Given /^I visit project wiki page$/ do
  visit project_wiki_path(@project, :index)
end

Given /^I visit profile page$/ do
  visit profile_path
end

Given /^I visit profile token page$/ do
  visit profile_token_path
end

Given /^I visit profile password page$/ do
  visit profile_password_path
end

Given /^I visit dashboard page$/ do
  visit dashboard_path
end

Given /^I visit dashboard issues page$/ do
  visit dashboard_issues_path
end

Given /^I visit dashboard merge requests page$/ do
  visit dashboard_merge_requests_path
end

