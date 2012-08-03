Given /^I visit project source page$/ do
  visit tree_project_ref_path(@project, @project.root_ref)
end

Then /^I should see files from repository$/ do
  page.should have_content("app")
  page.should have_content("History")
  page.should have_content("Gemfile")
end

Given /^I visit project source page for "(.*?)"$/ do |arg1|
  visit tree_project_ref_path(@project, arg1)
end

Then /^I should see files from repository for "(.*?)"$/ do |arg1|
  current_path.should == tree_project_ref_path(@project, arg1)
  page.should have_content("app")
  page.should have_content("History")
  page.should have_content("Gemfile")
end

Given /^I click on file from repo$/ do
  click_link "Gemfile"
end

Then /^I should see it content$/ do
  page.should have_content("rubygems.org")
end

Given /^I click on raw button$/ do
  click_link "raw"
end

Given /^I visit blob file from repo$/ do
  visit tree_project_ref_path(@project, ValidCommit::ID, :path => ValidCommit::BLOB_FILE_PATH)
end

Then /^I should see raw file content$/ do
  page.source.should == ValidCommit::BLOB_FILE
end

Given /^I click blame button$/ do
  click_link "blame"
end

Then /^I should see git file blame$/ do
  page.should have_content("rubygems.org")
  page.should have_content("Dmitriy Zaporozhets")
  page.should have_content("bc3735004cb Moving to rails 3.2")
end
