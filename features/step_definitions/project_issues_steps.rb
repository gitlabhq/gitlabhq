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

Given /^I should see "(.*?)" open issue$/ do |arg1|
  page.should have_content arg1 
end

Given /^I should not see "(.*?)" closed issue$/ do |arg1|
  page.should_not have_content arg1 
end

