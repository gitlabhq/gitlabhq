class Spinach::Features::DashboardIssues < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include Select2Helper

  step 'I should see issues assigned to me' do
    should_see(assigned_issue)
    should_not_see(authored_issue)
    should_not_see(other_issue)
  end

  step 'I should see issues authored by me' do
    should_see(authored_issue)
    should_see(authored_issue_on_public_project)
    should_not_see(assigned_issue)
    should_not_see(other_issue)
  end

  step 'I should see all issues' do
    should_see(authored_issue)
    should_see(assigned_issue)
    should_see(other_issue)
  end

  step 'I have authored issues' do
    authored_issue
    authored_issue_on_public_project
  end

  step 'I have assigned issues' do
    assigned_issue
  end

  step 'I have other issues' do
    other_issue
  end

  step 'I click "Authored by me" link' do
    find("#assignee_id").set("")
    find(".js-author-search", match: :first).click
    find(".dropdown-menu-author li a", match: :first, text: current_user.to_reference).click
  end

  step 'I click "All" link' do
    find(".js-author-search").click
    expect(page).to have_selector(".dropdown-menu-author li a")
    find(".dropdown-menu-author li a", match: :first).click
    expect(page).not_to have_selector(".dropdown-menu-author li a")

    find(".js-assignee-search").click
    expect(page).to have_selector(".dropdown-menu-assignee li a")
    find(".dropdown-menu-assignee li a", match: :first).click
    expect(page).not_to have_selector(".dropdown-menu-assignee li a")
  end

  def should_see(issue)
    expect(page).to have_content(issue.title[0..10])
  end

  def should_not_see(issue)
    expect(page).not_to have_content(issue.title[0..10])
  end

  def assigned_issue
    @assigned_issue ||= create :issue, assignee: current_user, project: project
  end

  def authored_issue
    @authored_issue ||= create :issue, author: current_user, project: project
  end

  def other_issue
    @other_issue ||= create :issue, project: project
  end

  def authored_issue_on_public_project
    @authored_issue_on_public_project ||= create :issue, author: current_user, project: public_project
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
end
