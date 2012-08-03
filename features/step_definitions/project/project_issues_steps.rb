Given /^project "(.*?)" have "(.*?)" open issue$/ do |arg1, arg2|
  project = Project.find_by_name(arg1)
  Factory.create(:issue, :title => arg2, :project => project, :author => project.users.first)
end

Given /^project "(.*?)" have "(.*?)" closed issue$/ do |arg1, arg2|
  project = Project.find_by_name(arg1)
  Factory.create(:issue, :title => arg2, :project => project, :author => project.users.first, :closed => true)
end

Given /^I visit project "(.*?)" issues page$/ do |arg1|
  visit project_issues_path(Project.find_by_name(arg1))
end

Given /^I should see "(.*?)" in issues$/ do |arg1|
  page.should have_content arg1 
end

Given /^I should not see "(.*?)" in issues$/ do |arg1|
  page.should_not have_content arg1 
end

Then /^I should see issue "(.*?)"$/ do |arg1|
  issue = Issue.find_by_title(arg1)
  page.should have_content issue.title
  page.should have_content issue.author_name
  page.should have_content issue.project.name
end

Given /^I visit issue page "(.*?)"$/ do |arg1|
  issue = Issue.find_by_title(arg1)
  visit project_issue_path(issue.project, issue)
end

Given /^I submit new issue "(.*?)"$/ do |arg1|
  fill_in "issue_title", :with => arg1
  click_button "Submit new issue"
end
