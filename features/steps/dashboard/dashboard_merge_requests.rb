class DashboardMergeRequests < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths

  Then 'I should see my merge requests' do
    merge_requests = @user.merge_requests
    merge_requests.each do |mr|
      page.should have_content(mr.title[0..10])
      page.should have_content(mr.target_project.name)
      page.should have_content(mr.source_project.name)
    end
  end

  And 'I have authored merge requests' do
    project1_source = create :project
    project1_target= create :project
    project2_source = create :project
    project2_target = create :project


    project1_source.team << [@user, :master]
    project1_target.team << [@user, :master]
    project2_source.team << [@user, :master]
    project2_target.team << [@user, :master]

    merge_request1 = create :merge_request, author: @user, source_project: project1_source, target_project: project1_target
    merge_request2 = create :merge_request, author: @user, source_project: project2_source, target_project: project2_target
  end
end
