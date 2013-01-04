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
    project1 = create :project
    project2 = create :project

    project1.team << [@user, :master]
    project2.team << [@user, :master]

    merge_request1 = create :merge_request, author: @user, project: project1
    merge_request2 = create :merge_request, author: @user, project: project2
  end
end
