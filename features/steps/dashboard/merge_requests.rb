class Spinach::Features::DashboardMergeRequests < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include Select2Helper

  step 'I should see merge requests assigned to me' do
    should_see(assigned_merge_request)
    should_see(assigned_merge_request_from_fork)
    should_not_see(authored_merge_request)
    should_not_see(authored_merge_request_from_fork)
    should_not_see(other_merge_request)
  end

  step 'I should see merge requests authored by me' do
    should_see(authored_merge_request)
    should_see(authored_merge_request_from_fork)
    should_not_see(assigned_merge_request)
    should_not_see(assigned_merge_request_from_fork)
    should_not_see(other_merge_request)
  end

  step 'I should see all merge requests' do
    should_see(authored_merge_request)
    should_see(assigned_merge_request)
    should_see(other_merge_request)
  end

  step 'I have authored merge requests' do
    authored_merge_request
    authored_merge_request_from_fork
  end

  step 'I have assigned merge requests' do
    assigned_merge_request
    assigned_merge_request_from_fork
  end

  step 'I have other merge requests' do
    other_merge_request
  end

  step 'I click "Authored by me" link' do
    find("#assignee_id").set("")
    find(".js-author-search", match: :first).click
    find(".dropdown-menu-author li a", match: :first, text: current_user.to_reference).click
  end

  step 'I click "All" link' do
    find(".js-author-search").click
    find(".dropdown-menu-author li a", match: :first).click
    find(".js-assignee-search").click
    find(".dropdown-menu-assignee li a", match: :first).click
  end

  def should_see(merge_request)
    expect(page).to have_content(merge_request.title[0..10])
  end

  def should_not_see(merge_request)
    expect(page).not_to have_content(merge_request.title[0..10])
  end

  def assigned_merge_request
    @assigned_merge_request ||= create :merge_request,
                                  assignee: current_user,
                                  target_project: project,
                                  source_project: project
  end

  def authored_merge_request
    @authored_merge_request ||= create :merge_request,
                                  source_branch: 'markdown',
                                  author: current_user,
                                  target_project: project,
                                  source_project: project
  end

  def other_merge_request
    @other_merge_request ||= create :merge_request,
                              source_branch: 'fix',
                              target_project: project,
                              source_project: project
  end

  def authored_merge_request_from_fork
    @authored_merge_request_from_fork ||= create :merge_request,
                                            source_branch: 'feature_conflict',
                                            author: current_user,
                                            target_project: public_project,
                                            source_project: forked_project
  end

  def assigned_merge_request_from_fork
    @assigned_merge_request_from_fork ||= create :merge_request,
                                            source_branch: 'markdown',
                                            assignee: current_user,
                                            target_project: public_project,
                                            source_project: forked_project
  end

  def project
    @project ||= begin
                   project = create :project
                   project.team << [current_user, :master]
                   project
                 end
  end

  def public_project
    @public_project ||= create :project, :public
  end

  def forked_project
    @forked_project ||= Projects::ForkService.new(public_project, current_user).execute
    # The call to project.repository.after_import in RepositoryForkWorker does
    # not reset the @exists variable of @fork_project.repository so we have to
    # explicitely call this method to clear the @exists variable.
    @forked_project.repository.after_import
    @forked_project
  end
end
