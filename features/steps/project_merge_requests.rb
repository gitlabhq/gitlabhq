class ProjectMergeRequests < Spinach::FeatureSteps
  Then 'I should see "Bug NS-04" in merge requests' do
    page.should have_content "Bug NS-04"
  end

  And 'I should not see "Feature NS-03" in merge requests' do
    page.should_not have_content "Feature NS-03"
  end

  Given 'I click link "Closed"' do
    click_link "Closed"
  end

  Then 'I should see "Feature NS-03" in merge requests' do
    page.should have_content "Feature NS-03"
  end

  And 'I should not see "Bug NS-04" in merge requests' do
    page.should_not have_content "Bug NS-04"
  end

  Given 'I click link "All"' do
    click_link "All"
  end

  Given 'I click link "Bug NS-04"' do
    click_link "Bug NS-04"
  end

  Then 'I should see merge request "Bug NS-04"' do
    page.should have_content "Bug NS-04"
  end

  And 'I click link "Close"' do
    click_link "Close"
  end

  Then 'I should see closed merge request "Bug NS-04"' do
    mr = MergeRequest.find_by_title("Bug NS-04")
    mr.closed.should be_true
    page.should have_content "Closed by"
  end

  Given 'I click link "New Merge Request"' do
    click_link "New Merge Request"
  end

  And 'I submit new merge request "Wiki Feature"' do
    fill_in "merge_request_title", :with => "Wiki Feature"
    select "master", :from => "merge_request_source_branch"
    select "stable", :from => "merge_request_target_branch"
    click_button "Save"
  end

  Then 'I should see merge request "Wiki Feature"' do
    page.should have_content "Wiki Feature"
  end

  Given 'I visit merge request page "Bug NS-04"' do
    mr = MergeRequest.find_by_title("Bug NS-04")
    visit project_merge_request_path(mr.project, mr)
  end

  And 'I leave a comment like "XML attached"' do
    fill_in "note_note", :with => "XML attached"
    click_button "Add Comment"
  end

  Then 'I should see comment "XML attached"' do
    page.should have_content "XML attached"
  end

  Given 'I sign in as a user' do
    login_as :user
  end

  And 'I own project "Shop"' do
    @project = Factory :project, :name => "Shop"
    @project.add_access(@user, :admin)
  end

  And 'project "Shop" have "Bug NS-04" open merge request' do
    project = Project.find_by_name("Shop")
    Factory.create(:merge_request,
      :title => "Bug NS-04",
      :project => project,
      :author => project.users.first)
  end

  And 'project "Shop" have "Feature NS-03" closed merge request' do
    project = Project.find_by_name("Shop")
    Factory.create(:merge_request,
      :title => "Feature NS-03",
      :project => project,
      :author => project.users.first,
      :closed => true)
  end

  And 'I visit project "Shop" merge requests page' do
    visit project_merge_requests_path(Project.find_by_name("Shop"))
  end
end
