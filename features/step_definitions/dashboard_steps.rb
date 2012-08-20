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
  page.should have_content "Your pushed to branch new_design"
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

Given /^I visit dashboard issues page$/ do
  visit dashboard_issues_path
end

Then /^I should see issues assigned to me$/ do
  issues = @user.issues
  issues.each do |issue|
    page.should have_content(issue.title[0..10])
    page.should have_content(issue.project.name)
  end
end

Given /^I visit dashboard merge requests page$/ do
  visit dashboard_merge_requests_path
end

Then /^I should see my merge requests$/ do
  merge_requests = @user.merge_requests
  merge_requests.each do |mr|
    page.should have_content(mr.title[0..10])
    page.should have_content(mr.project.name)
  end
end

Given /^I have assigned issues$/ do
  project1 = Factory :project,
   :path => "project1",
   :code => "gitlabhq_1"

  project2 = Factory :project,
   :path => "project2",
   :code => "gitlabhq_2"

  project1.add_access(@user, :read, :write)
  project2.add_access(@user, :read, :write)

  issue1 = Factory :issue,
   :author => @user,
   :assignee => @user,
   :project => project1

  issue2 = Factory :issue,
   :author => @user,
   :assignee => @user,
   :project => project2
end

Given /^I have authored merge requests$/ do
  project1 = Factory :project,
   :path => "project1",
   :code => "gitlabhq_1"

  project2 = Factory :project,
   :path => "project2",
   :code => "gitlabhq_2"

  project1.add_access(@user, :read, :write)
  project2.add_access(@user, :read, :write)

  merge_request1 = Factory :merge_request,
   :author => @user,
   :project => project1

  merge_request2 = Factory :merge_request,
   :author => @user,
   :project => project2
end
