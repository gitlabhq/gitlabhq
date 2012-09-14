class DashboardMergeRequests < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths

  Then 'I should see my merge requests' do
    merge_requests = @user.merge_requests
    merge_requests.each do |mr|
      page.should have_content(mr.title[0..10])
      page.should have_content(mr.project.name)
    end
  end

  And 'I have authored merge requests' do
    project1 = Factory :project
    project2 = Factory :project

    project1.add_access(@user, :read, :write)
    project2.add_access(@user, :read, :write)

    merge_request1 = Factory :merge_request, :author => @user, :project => project1
    merge_request2 = Factory :merge_request, :author => @user, :project => project2
  end
end
