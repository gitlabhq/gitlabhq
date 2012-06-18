Given /^gitlab user "(.*?)"$/ do |arg1|
  Factory :user, :name => arg1
end

Given /^"(.*?)" is "(.*?)" developer$/ do |arg1, arg2|
  user = User.find_by_name(arg1)
  project = Project.find_by_name(arg2)
  project.add_access(user, :write)
end

Given /^I visit project "(.*?)" team page$/ do |arg1|
  visit team_project_path(Project.find_by_name(arg1))
end

Then /^I should be able to see myself in team$/ do
  page.should have_content(@user.name)
  page.should have_content(@user.email)
end

Then /^I should see "(.*?)" in team list$/ do |arg1|
  user = User.find_by_name(arg1)
  page.should have_content(user.name)
  page.should have_content(user.email)
end

Given /^I click link "(.*?)"$/ do |arg1|
  click_link arg1
end

Given /^I select "(.*?)" as "(.*?)"$/ do |arg1, arg2|
  user = User.find_by_name(arg1)
  within "#new_team_member" do 
    select user.name, :from => "team_member_user_id"
    select arg2, :from => "team_member_project_access"
  end
  click_button "Save"
end

Then /^I should see "(.*?)" in team list as "(.*?)"$/ do |arg1, arg2|
  user = User.find_by_name(arg1)
  role_id = find(".user_#{user.id} #team_member_project_access").value
  role_id.should == UsersProject.access_roles[arg2].to_s
end

Given /^I change "(.*?)" role to "(.*?)"$/ do |arg1, arg2|
  user = User.find_by_name(arg1)
  within ".user_#{user.id}" do 
    select arg2, :from => "team_member_project_access"
  end
end

Then /^I should see "(.*?)" team profile$/ do |arg1|
  user = User.find_by_name(arg1)
  page.should have_content(user.name)
  page.should have_content(user.email)
  page.should have_content("To team list")
end

Then /^I should not see "(.*?)" in team list$/ do |arg1|
  user = User.find_by_name(arg1)
  page.should_not have_content(user.name)
  page.should_not have_content(user.email)
end
