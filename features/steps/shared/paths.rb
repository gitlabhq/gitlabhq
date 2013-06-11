module SharedPaths
  include Spinach::DSL

  step 'I visit new project page' do
    visit new_project_path
  end

  # ----------------------------------------
  # Group
  # ----------------------------------------

  step 'I visit group page' do
    visit group_path(current_group)
  end

  step 'I visit group issues page' do
    visit issues_group_path(current_group)
  end

  step 'I visit group merge requests page' do
    visit merge_requests_group_path(current_group)
  end

  step 'I visit group people page' do
    visit people_group_path(current_group)
  end

  step 'I visit group settings page' do
    visit edit_group_path(current_group)
  end

  # ----------------------------------------
  # Dashboard
  # ----------------------------------------

  step 'I visit dashboard page' do
    visit dashboard_path
  end

  step 'I visit dashboard projects page' do
    visit projects_dashboard_path
  end

  step 'I visit dashboard issues page' do
    visit issues_dashboard_path
  end

  step 'I visit dashboard merge requests page' do
    visit merge_requests_dashboard_path
  end

  step 'I visit dashboard search page' do
    visit search_path
  end

  step 'I visit dashboard help page' do
    visit help_path
  end

  # ----------------------------------------
  # Profile
  # ----------------------------------------

  step 'I visit profile page' do
    visit profile_path
  end

  step 'I visit profile account page' do
    visit account_profile_path
  end

  step 'I visit profile SSH keys page' do
    visit keys_path
  end

  step 'I visit profile design page' do
    visit design_profile_path
  end

  step 'I visit profile history page' do
    visit history_profile_path
  end

  # ----------------------------------------
  # Admin
  # ----------------------------------------

  step 'I visit admin page' do
    visit admin_root_path
  end

  step 'I visit admin projects page' do
    visit admin_projects_path
  end

  step 'I visit admin users page' do
    visit admin_users_path
  end

  step 'I visit admin logs page' do
    visit admin_logs_path
  end

  step 'I visit admin hooks page' do
    visit admin_hooks_path
  end

  step 'I visit admin Resque page' do
    visit admin_background_jobs_path
  end

  step 'I visit admin groups page' do
    visit admin_groups_path
  end

  step 'I visit admin teams page' do
    visit admin_teams_path
  end

  # ----------------------------------------
  # Generic Project
  # ----------------------------------------

  step "I visit my project's home page" do
    visit project_path(@project)
  end

  step "I visit my project's settings page" do
    visit edit_project_path(@project)
  end

  step "I visit my project's files page" do
    visit project_tree_path(@project, root_ref)
  end

  step "I visit my project's commits page" do
    visit project_commits_path(@project, root_ref, {limit: 5})
  end

  step "I visit my project's commits page for a specific path" do
    visit project_commits_path(@project, root_ref + "/app/models/project.rb", {limit: 5})
  end

  step 'I visit my project\'s commits stats page' do
    visit stats_project_repository_path(@project)
  end

  step "I visit my project's network page" do
    # Stub Graph max_size to speed up test (10 commits vs. 650)
    Network::Graph.stub(max_count: 10)

    visit project_network_path(@project, root_ref)
  end

  step "I visit my project's issues page" do
    visit project_issues_path(@project)
  end

  step "I visit my project's merge requests page" do
    visit project_merge_requests_path(@project)
  end

  step "I visit my project's wall page" do
    visit project_wall_path(@project)
  end

  step "I visit my project's wiki page" do
    visit project_wiki_path(@project, :home)
  end

  step 'I visit project hooks page' do
    visit project_hooks_path(@project)
  end

  step 'I visit project deploy keys page' do
    visit project_deploy_keys_path(@project)
  end

  # ----------------------------------------
  # "Shop" Project
  # ----------------------------------------

  step 'I visit project "Shop" page' do
    visit project_path(project)
  end

  step 'I visit edit project "Shop" page' do
    visit edit_project_path(project)
  end

  step 'I visit project branches page' do
    visit branches_project_repository_path(@project)
  end

  step 'I visit compare refs page' do
    visit project_compare_index_path(@project)
  end

  step 'I visit project commits page' do
    visit project_commits_path(@project, root_ref, {limit: 5})
  end

  step 'I visit project commits page for stable branch' do
    visit project_commits_path(@project, 'stable', {limit: 5})
  end

  step 'I visit project source page' do
    visit project_tree_path(@project, root_ref)
  end

  step 'I visit blob file from repo' do
    visit project_blob_path(@project, File.join(ValidCommit::ID, ValidCommit::BLOB_FILE_PATH))
  end

  step 'I visit project source page for "8470d70"' do
    visit project_tree_path(@project, "8470d70")
  end

  step 'I visit project tags page' do
    visit tags_project_repository_path(@project)
  end

  step 'I visit project commit page' do
    visit project_commit_path(@project, ValidCommit::ID)
  end

  step 'I visit project "Shop" issues page' do
    visit project_issues_path(project)
  end

  step 'I visit issue page "Release 0.4"' do
    issue = Issue.find_by_title("Release 0.4")
    visit project_issue_path(issue.project, issue)
  end

  step 'I visit project "Shop" labels page' do
    visit project_labels_path(project)
  end

  step 'I visit merge request page "Bug NS-04"' do
    mr = MergeRequest.find_by_title("Bug NS-04")
    visit project_merge_request_path(mr.project, mr)
  end

  step 'I visit merge request page "Bug NS-05"' do
    mr = MergeRequest.find_by_title("Bug NS-05")
    visit project_merge_request_path(mr.project, mr)
  end

  step 'I visit project "Shop" merge requests page' do
    visit project_merge_requests_path(project)
  end

  step 'I visit project "Shop" milestones page' do
    visit project_milestones_path(project)
  end

  step 'I visit project "Shop" team page' do
    visit project_team_index_path(project)
  end

  step 'I visit project "Shop" wall page' do
    visit project_wall_path(project)
  end

  step 'I visit project wiki page' do
    visit project_wiki_path(@project, :home)
  end

  # ----------------------------------------
  # Public Projects
  # ----------------------------------------

  step 'I visit the public projects area' do
    visit public_root_path
  end

  # ----------------------------------------
  # Snippets
  # ----------------------------------------

  Given 'I visit project "Shop" snippets page' do
    visit project_snippets_path(project)
  end

  Given 'I visit snippets page' do
    visit snippets_path
  end

  Given 'I visit new snippet page' do
    visit new_snippet_path
  end

  def root_ref
    @project.repository.root_ref
  end

  def project
    project = Project.find_by_name!("Shop")
  end
end
