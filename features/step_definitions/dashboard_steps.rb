Given /^I visit dashboard page$/ do
  visit dashboard_path
end

Then /^I should see "(.*?)" link$/ do |arg1|
  page.should have_link(arg1)
end

Then /^I should see "(.*?)" project link$/ do |arg1|
  page.should have_link(arg1)
end

Then /^I should see project "(.*?)" activity feed$/ do |arg1|
  project = Project.find_by_name(arg1)
  page.should have_content "#{@user.name} pushed new branch new_design at #{project.name}"
end

Given /^project "(.*?)" has push event$/ do |arg1|
  @project = Project.find_by_name(arg1)

  data = {
    :before => "0000000000000000000000000000000000000000",
    :after => "0220c11b9a3e6c69dc8fd35321254ca9a7b98f7e",
    :ref => "refs/heads/new_design",
    :user_id => @user.id,
    :user_name => @user.name,
    :repository => {
      :name => @project.name,
      :url => "localhost/rubinius",
      :description => "",
      :homepage => "localhost/rubinius",
      :private => true
    }
  }

  @event = Event.create(
    :project => @project,
    :action => Event::Pushed,
    :data => data,
    :author_id => @user.id
  )
end

Then /^I should see last push widget$/ do
  page.should have_content "Your last push was to branch new_design"
  page.should have_link "Create Merge Request"
end

Then /^I click "(.*?)" link$/ do |arg1|
  click_link arg1 #Create Merge Request"
end

Then /^I see prefilled new Merge Request page$/ do
  current_path.should == new_project_merge_request_path(@project) 
  find("#merge_request_source_branch").value.should == "new_design" 
  find("#merge_request_target_branch").value.should == "master" 
  find("#merge_request_title").value.should == "New Design" 
end

Given /^I visit dashboard search page$/ do
  visit search_path
end

Given /^I search for "(.*?)"$/ do |arg1|
  fill_in "dashboard_search", :with => arg1
  click_button "Search"
end
