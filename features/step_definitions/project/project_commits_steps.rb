Given /^I visit project commits page$/ do
  visit project_commits_path(@project)
end

Then /^I see project commits$/ do
  current_path.should == project_commits_path(@project)

  commit = @project.commit
  page.should have_content(@project.name)
  page.should have_content(commit.message)
  page.should have_content(commit.id.to_s[0..5])
end

Given /^I click atom feed link$/ do
  click_link "Feed"
end

Then /^I see commits atom feed$/ do
  commit = CommitDecorator.decorate(@project.commit)
  page.response_headers['Content-Type'].should have_content("application/atom+xml")
  page.body.should have_selector("title", :text => "Recent commits to #{@project.name}")
  page.body.should have_selector("author email", :text => commit.author_email)
  page.body.should have_selector("entry summary", :text => commit.description)
end

Given /^I click on commit link$/ do
  visit project_commit_path(@project, ValidCommit::ID)
end

Then /^I see commit info$/ do
  page.should have_content ValidCommit::MESSAGE
  page.should have_content "Showing 1 changed file"
end

Given /^I visit compare refs page$/ do
  visit compare_project_commits_path(@project)
end

Given /^I fill compare fields with refs$/ do
  fill_in "from", :with => "master"
  fill_in "to", :with => "stable"
  click_button "Compare"
end

Given /^I see compared refs$/ do
  page.should have_content "Commits (27)"
  page.should have_content "Compare View"
  page.should have_content "Showing 73 changed files"
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

Then /^I should see "(.*?)" recent branches list$/ do |arg1|
  page.should have_content("Branches")
  page.should have_content("master")
end

Then /^I should see "(.*?)" all branches list$/ do |arg1|
  page.should have_content("Branches")
  page.should have_content("master")
end

Then /^I should see "(.*?)" all tags list$/ do |arg1|
  page.should have_content("Tags")
  page.should have_content("v1.2.1")
end

Then /^I should see "(.*?)" protected branches list$/ do |arg1|
  within "table" do 
    page.should have_content "stable"
    page.should_not have_content "master"
  end
end

Given /^project "(.*?)" has protected branches$/ do |arg1|
  project = Project.find_by_name(arg1)
  project.protected_branches.create(:name => "stable")
end
