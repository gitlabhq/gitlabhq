module SharedPaths
  include Spinach::DSL

  When 'I visit new project page' do
    visit new_project_path
  end

  # ----------------------------------------
  # Group
  # ----------------------------------------

  When 'I visit group page' do
    visit group_path(current_group)
  end

  When 'I visit group issues page' do
    visit issues_group_path(current_group)
  end

  When 'I visit group merge requests page' do
    visit merge_requests_group_path(current_group)
  end

  When 'I visit group people page' do
    visit people_group_path(current_group)
  end

  When 'I visit group settings page' do
    visit edit_group_path(current_group)
  end

  # ----------------------------------------
  # Dashboard
  # ----------------------------------------

  Given 'I visit dashboard page' do
    visit dashboard_path
  end

  Given 'I visit dashboard projects page' do
    visit projects_dashboard_path
  end

  Given 'I visit dashboard issues page' do
    visit issues_dashboard_path
  end

  Given 'I visit dashboard merge requests page' do
    visit merge_requests_dashboard_path
  end

  Given 'I visit dashboard search page' do
    visit search_path
  end

  Given 'I visit dashboard help page' do
    visit help_path
  end

  # ----------------------------------------
  # Profile
  # ----------------------------------------

  Given 'I visit profile page' do
    visit profile_path
  end

  Given 'I visit profile account page' do
    visit account_profile_path
  end

  Given 'I visit profile SSH keys page' do
    visit keys_path
  end

  Given 'I visit profile design page' do
    visit design_profile_path
  end

  Given 'I visit profile history page' do
    visit history_profile_path
  end

  # ----------------------------------------
  # Admin
  # ----------------------------------------

  Given 'I visit admin page' do
    visit admin_root_path
  end

  Given 'I visit admin projects page' do
    visit admin_projects_path
  end

  Given 'I visit admin users page' do
    visit admin_users_path
  end

  Given 'I visit admin logs page' do
    visit admin_logs_path
  end

  Given 'I visit admin hooks page' do
    visit admin_hooks_path
  end

  Given 'I visit admin Resque page' do
    visit admin_resque_path
  end

  And 'I visit admin groups page' do
    visit admin_groups_path
  end

  When 'I visit admin teams page' do
    visit admin_teams_path
  end

  # ----------------------------------------
  # Generic Project
  # ----------------------------------------

  Given "I visit my project's home page" do
    visit project_path(@project)
  end

  Given "I visit my project's files page" do
    visit project_tree_path(@project, root_ref)
  end

  Given "I visit my project's commits page" do
    visit project_commits_path(@project, root_ref, {limit: 5})
  end

  Given "I visit my project's commits page for a specific path" do
    visit project_commits_path(@project, root_ref + "/app/models/project.rb", {limit: 5})
  end

  Given 'I visit my project\'s commits stats page' do
    visit stats_project_repository_path(@project)
  end

  Given "I visit my project's network page" do
    # Stub Graph::JsonBuilder max_size to speed up test (10 commits vs. 650)
    Gitlab::Graph::JsonBuilder.stub(max_count: 10)

    visit project_graph_path(@project, root_ref)
  end

  Given "I visit my project's issues page" do
    visit project_issues_path(@project)
  end

  Given "I visit my project's merge requests page" do
    visit project_merge_requests_path(@project)
  end

  Given "I visit my project's wall page" do
    visit wall_project_path(@project)
  end

  Given "I visit my project's wiki page" do
    visit project_wiki_path(@project, :index)
  end

  When 'I visit project hooks page' do
    visit project_hooks_path(@project)
  end

  # ----------------------------------------
  # "Shop" Project
  # ----------------------------------------

  And 'I visit project "Shop" page' do
    project = Project.find_by_name("Shop")
    visit project_path(project)
  end

  When 'I visit edit project "Shop" page' do
    project = Project.find_by_name("Shop")
    visit edit_project_path(project)
  end

  Given 'I visit project branches page' do
    visit branches_project_repository_path(@project)
  end

  Given 'I visit compare refs page' do
    visit project_compare_index_path(@project)
  end

  Given 'I visit project commits page' do
    visit project_commits_path(@project, root_ref, {limit: 5})
  end

  Given 'I visit project commits page for stable branch' do
    visit project_commits_path(@project, 'stable', {limit: 5})
  end

  Given 'I visit project source page' do
    visit project_tree_path(@project, root_ref)
  end

  Given 'I visit blob file from repo' do
    visit project_tree_path(@project, File.join(ValidCommit::ID, ValidCommit::BLOB_FILE_PATH))
  end

  Given 'I visit project source page for "8470d70"' do
    visit project_tree_path(@project, "8470d70")
  end

  Given 'I visit project tags page' do
    visit tags_project_repository_path(@project)
  end

  Given 'I visit project commit page' do
    visit project_commit_path(@project, ValidCommit::ID)
  end

  And 'I visit project "Shop" issues page' do
    visit project_issues_path(Project.find_by_name("Shop"))
  end

  Given 'I visit issue page "Release 0.4"' do
    issue = Issue.find_by_title("Release 0.4")
    visit project_issue_path(issue.project, issue)
  end

  Given 'I visit project "Shop" labels page' do
    visit project_labels_path(Project.find_by_name("Shop"))
  end

  Given 'I visit merge request page "Bug NS-04"' do
    mr = MergeRequest.find_by_title("Bug NS-04")
    visit project_merge_request_path(mr.project, mr)
  end

  Given 'I visit merge request page "Bug NS-05"' do
    mr = MergeRequest.find_by_title("Bug NS-05")
    visit project_merge_request_path(mr.project, mr)
  end

  And 'I visit project "Shop" merge requests page' do
    visit project_merge_requests_path(Project.find_by_name("Shop"))
  end

  Given 'I visit project "Shop" milestones page' do
    @project = Project.find_by_name("Shop")
    visit project_milestones_path(@project)
  end

  Then 'I visit project "Shop" team page' do
    visit project_team_index_path(Project.find_by_name("Shop"))
  end

  Then 'I visit project "Shop" wall page' do
    project = Project.find_by_name("Shop")
    visit wall_project_path(project)
  end

  Given 'I visit project wiki page' do
    visit project_wiki_path(@project, :index)
  end

  def root_ref
    @project.repository.root_ref
  end
end
