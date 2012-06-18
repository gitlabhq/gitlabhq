include LoginMacros

Given /^I signin as a user$/ do
  login_as :user
end

When /^I visit new project page$/ do
  visit new_project_path
end

When /^fill project form with valid data$/ do
  fill_in 'project_name', :with => 'NewProject'
  fill_in 'project_code', :with => 'NPR'
  fill_in 'project_path', :with => 'newproject'
  click_button "Create project"
end

Then /^I should see project page$/ do
  current_path.should == project_path(Project.last)
  page.should have_content('NewProject')
end

Then /^I should see empty project instuctions$/ do
  page.should have_content("git init")
  page.should have_content("git remote")
  page.should have_content(Project.last.url_to_repo)
end

Given /^I own project "(.*?)"$/ do |arg1|
  @project = Factory :project, :name => arg1
  @project.add_access(@user, :admin)
end

Given /^I visit project "(.*?)" wall page$/ do |arg1|
  project = Project.find_by_name(arg1)
  visit wall_project_path(project)
end

Then /^I should see project wall note "(.*?)"$/ do |arg1|
  page.should have_content arg1
end

Given /^project "(.*?)" has comment "(.*?)"$/ do |arg1, arg2|
  project = Project.find_by_name(arg1)
  project.notes.create(:note => arg1, :author => project.users.first)
end

Given /^I write new comment "(.*?)"$/ do |arg1|
  fill_in "note_note", :with => arg1
  click_button "Add Comment"
end

Given /^I visit project "(.*?)" network page$/ do |arg1|
  project = Project.find_by_name(arg1)
  visit graph_project_path(project)
end

Given /^show me page$/ do
  save_and_open_page
end

Given /^page should have network graph$/ do
  page.should have_content "Project Network Graph"
  within ".graph" do
    page.should have_content "stable"
    page.should have_content "notes_refacto..."
  end
end
