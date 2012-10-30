class ProjectMergeRequests < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedNote
  include SharedPaths

  Given 'I click link "New Merge Request"' do
    click_link "New Merge Request"
  end

  Given 'I click link "Bug NS-04"' do
    click_link "Bug NS-04"
  end

  Given 'I click link "All"' do
    click_link "All"
  end

  Given 'I click link "Closed"' do
    click_link "Closed"
  end

  Then 'I should see merge request "Wiki Feature"' do
    page.should have_content "Wiki Feature"
  end

  Then 'I should see closed merge request "Bug NS-04"' do
    mr = MergeRequest.find_by_title("Bug NS-04")
    mr.closed.should be_true
    page.should have_content "Closed by"
  end

  Then 'I should see merge request "Bug NS-04"' do
    page.should have_content "Bug NS-04"
  end

  Then 'I should see "Bug NS-04" in merge requests' do
    page.should have_content "Bug NS-04"
  end

  Then 'I should see "Feature NS-03" in merge requests' do
    page.should have_content "Feature NS-03"
  end

  And 'I should not see "Feature NS-03" in merge requests' do
    page.should_not have_content "Feature NS-03"
  end


  And 'I should not see "Bug NS-04" in merge requests' do
    page.should_not have_content "Bug NS-04"
  end

  And 'I click link "Close"' do
    click_link "Close"
  end

  And 'I submit new merge request "Wiki Feature"' do
    fill_in "merge_request_title", with: "Wiki Feature"
    select "master", from: "merge_request_source_branch"
    select "stable", from: "merge_request_target_branch"
    click_button "Save"
  end

  And 'project "Shop" have "Bug NS-04" open merge request' do
    project = Project.find_by_name("Shop")
    Factory.create(:merge_request,
      title: "Bug NS-04",
      project: project,
      author: project.users.first)
  end

  And 'project "Shop" have "Bug NS-05" open merge request with diffs inside' do
    project = Project.find_by_name("Shop")
    Factory.create(:merge_request_with_diffs,
      title: "Bug NS-05",
      project: project,
      author: project.users.first)
  end

  And 'project "Shop" have "Feature NS-03" closed merge request' do
    project = Project.find_by_name("Shop")
    Factory.create(:merge_request,
      title: "Feature NS-03",
      project: project,
      author: project.users.first,
      closed: true)
  end

  And 'I switch to the diff tab' do
    mr = MergeRequest.find_by_title("Bug NS-05")
    visit diffs_project_merge_request_path(mr.project, mr)
  end

  And 'I switch to the merge request\'s comments tab' do
    mr = MergeRequest.find_by_title("Bug NS-05")
    visit project_merge_request_path(mr.project, mr)
  end

  And 'I click on the first commit in the merge request' do
    mr = MergeRequest.find_by_title("Bug NS-05")
    click_link mr.st_commits.first.short_id(8)
  end

  And 'I leave a comment on the diff page' do
    within(:xpath, "//div[@class='note-form-holder']") do
      fill_in "note_note", with: "One comment to rule them all"
      click_button "Add Comment"
    end
  end

  And 'I leave a comment like "Line is wrong" on line 185 of the first file' do
    within(:xpath, "//div[@class='diff_file'][1]") do
      click_link "Add note on line 185"
    end

    within(:xpath, "//div[@class='line-note-form-holder']") do
      fill_in "note_note", with: "Line is wrong"
      click_button "Add note"
    end
  end

  Then 'I should see a discussion has started on line 185' do
    mr = MergeRequest.find_by_title("Bug NS-05")
    first_commit = mr.st_commits.first
    first_diff   = mr.st_diffs.first
    page.should have_content "#{current_user.name} started a discussion on this merge request diff"
    page.should have_content "#{first_diff.b_path}:L185"
    page.should have_content "Line is wrong"
  end

  Then 'I should see a discussion has started on commit bcf03b5de6c:L185' do
    mr = MergeRequest.find_by_title("Bug NS-05")
    first_commit = mr.st_commits.first
    first_diff   = mr.st_diffs.first
    page.should have_content "#{current_user.name} started a discussion on commit"
    page.should have_content first_commit.short_id(8)
    page.should have_content "#{first_diff.b_path}:L185"
    page.should have_content "Line is wrong"
  end

  Then 'I should see a discussion has started on commit bcf03b5de6c' do
    mr = MergeRequest.find_by_title("Bug NS-05")
    first_commit = mr.st_commits.first
    first_diff   = mr.st_diffs.first
    page.should have_content "#{current_user.name} started a discussion on commit"
    page.should have_content first_commit.short_id(8)
    page.should have_content "One comment to rule them all"
    page.should_not have_content "#{first_diff.b_path}:L185"
  end
end
