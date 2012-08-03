Given /^project "(.*?)" has milestone "(.*?)"$/ do |arg1, arg2|
  project = Project.find_by_name(arg1)

  milestone = Factory :milestone,
    :title => arg2,
    :project => project

  3.times do |i|
    issue = Factory :issue,
      :project => project,
      :milestone => milestone
  end
end

Given /^I visit project "(.*?)" milestones page$/ do |arg1|
  @project = Project.find_by_name(arg1)
  visit project_milestones_path(@project)
end

Then /^I should see active milestones$/ do
  milestone = @project.milestones.first
  page.should have_content(milestone.title[0..10])
  page.should have_content(milestone.expires_at)
  page.should have_content("Browse Issues")
end

Then /^I should see milestone "(.*?)"$/ do |arg1|
  milestone = @project.milestones.find_by_title(arg1)
  page.should have_content(milestone.title[0..10])
  page.should have_content(milestone.expires_at)
  page.should have_content("Browse Issues")
end

Given /^I submit new milestone "(.*?)"$/ do |arg1|
  fill_in "milestone_title", :with => arg1
  click_button "Create milestone"
end

