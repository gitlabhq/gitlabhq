class DashboardMergeRequests < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths

  step 'I should see merge requests assigned to me' do
    should_see(assigned_merge_request)
    should_not_see(authored_merge_request)
    should_not_see(other_merge_request)
  end

  step 'I should see merge requests authored by me' do
    should_see(authored_merge_request)
    should_not_see(assigned_merge_request)
    should_not_see(other_merge_request)
  end

  step 'I should see all merge requests' do
    should_see(authored_merge_request)
    should_see(assigned_merge_request)
    should_see(other_merge_request)
  end

  step 'I have authored merge requests' do
    authored_merge_request
  end

  step 'I have assigned merge requests' do
    assigned_merge_request
  end

  step 'I have other merge requests' do
    other_merge_request
  end

  step 'I click "Authored by me" link' do
    within ".scope-filter" do
      click_link 'Created by me'
    end
  end

  step 'I click "All" link' do
    within ".scope-filter" do
      click_link "Everyone's"
    end
  end

  def should_see(merge_request)
    page.should have_content(merge_request.title[0..10])
  end

  def should_not_see(merge_request)
    page.should_not have_content(merge_request.title[0..10])
  end

  def assigned_merge_request
    @assigned_merge_request ||= create :merge_request, assignee: current_user, target_project: project
  end

  def authored_merge_request
    @authored_merge_request ||= create :merge_request, author: current_user, target_project: project
  end

  def other_merge_request
    @other_merge_request ||= create :merge_request, target_project: project
  end

  def project
    @project ||= begin
                   project =create :project
                   project.team << [current_user, :master]
                   project
                 end
  end
end
