Given /^project "(.*?)" have "(.*?)" open merge request$/ do |arg1, arg2|
  project = Project.find_by_name(arg1)
  Factory.create(:merge_request, :title => arg2, :project => project, :author => project.users.first)
end

Given /^project "(.*?)" have "(.*?)" closed merge request$/ do |arg1, arg2|
  project = Project.find_by_name(arg1)
  Factory.create(:merge_request, :title => arg2, :project => project, :author => project.users.first, :closed => true)
end

Given /^I visit project "(.*?)" merge requests page$/ do |arg1|
  visit project_merge_requests_path(Project.find_by_name(arg1))
end

Then /^I should see "(.*?)" in merge requests$/ do |arg1|
  page.should have_content arg1 
end

Then /^I should not see "(.*?)" in merge requests$/ do |arg1|
  page.should_not have_content arg1 
end

Then /^I should see merge request "(.*?)"$/ do |arg1|
  merge_request = MergeRequest.find_by_title(arg1)
  page.should have_content(merge_request.title[0..10]) 
  page.should have_content(merge_request.target_branch)
  page.should have_content(merge_request.source_branch)
end

Given /^I submit new merge request "(.*?)"$/ do |arg1|
  fill_in "merge_request_title", :with => arg1
  select "master", :from => "merge_request_source_branch"
  select "stable", :from => "merge_request_target_branch"
  click_button "Save"
end

Given /^I visit merge request page "(.*?)"$/ do |arg1|
  mr = MergeRequest.find_by_title(arg1)
  visit project_merge_request_path(mr.project, mr)
end

Then /^I should see closed merge request "(.*?)"$/ do |arg1|
  mr = MergeRequest.find_by_title(arg1)
  mr.closed.should be_true
  page.should have_content "Closed by"
end

