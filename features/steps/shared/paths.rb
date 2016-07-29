module SharedPaths
  include Spinach::DSL
  include RepoHelpers
  include DashboardHelper

  step 'I visit new project page' do
    visit new_project_path
  end

  step 'I visit login page' do
    visit new_user_session_path
  end

  # ----------------------------------------
  # User
  # ----------------------------------------

  step 'I visit user "John Doe" page' do
    visit user_path("john_doe")
  end

  # ----------------------------------------
  # Group
  # ----------------------------------------

  step 'I visit group "Owned" page' do
    visit group_path(Group.find_by(name: "Owned"))
  end

  step 'I visit group "Owned" activity page' do
    visit activity_group_path(Group.find_by(name: "Owned"))
  end

  step 'I visit group "Owned" issues page' do
    visit issues_group_path(Group.find_by(name: "Owned"))
  end

  step 'I visit group "Owned" merge requests page' do
    visit merge_requests_group_path(Group.find_by(name: "Owned"))
  end

  step 'I visit group "Owned" milestones page' do
    visit group_milestones_path(Group.find_by(name: "Owned"))
  end

  step 'I visit group "Owned" members page' do
    visit group_group_members_path(Group.find_by(name: "Owned"))
  end

  step 'I visit group "Owned" settings page' do
    visit edit_group_path(Group.find_by(name: "Owned"))
  end

  step 'I visit group "Owned" LDAP settings page' do
    visit group_ldap_group_links_path(Group.find_by(name: "Owned"))
  end

  step 'I visit group "Owned" projects page' do
    visit projects_group_path(Group.find_by(name: "Owned"))
  end

  step 'I visit group "Guest" page' do
    visit group_path(Group.find_by(name: "Guest"))
  end

  step 'I visit group "Guest" issues page' do
    visit issues_group_path(Group.find_by(name: "Guest"))
  end

  step 'I visit group "Guest" merge requests page' do
    visit merge_requests_group_path(Group.find_by(name: "Guest"))
  end

  step 'I visit group "Guest" members page' do
    visit group_group_members_path(Group.find_by(name: "Guest"))
  end

  step 'I visit group "Guest" settings page' do
    visit edit_group_path(Group.find_by(name: "Guest"))
  end

  # ----------------------------------------
  # Dashboard
  # ----------------------------------------

  step 'I visit dashboard page' do
    visit dashboard_projects_path
  end

  step 'I visit dashboard activity page' do
    visit activity_dashboard_path
  end

  step 'I visit dashboard projects page' do
    visit projects_dashboard_path
  end

  step 'I visit dashboard issues page' do
    visit assigned_issues_dashboard_path
  end

  step 'I visit dashboard merge requests page' do
    visit assigned_mrs_dashboard_path
  end

  step 'I visit dashboard search page' do
    visit search_path
  end

  step 'I visit dashboard help page' do
    visit help_path
  end

  step 'I visit dashboard groups page' do
    visit dashboard_groups_path
  end

  step 'I visit dashboard todos page' do
    visit dashboard_todos_path
  end

  step 'I should be redirected to the dashboard groups page' do
    expect(current_path).to eq dashboard_groups_path
  end

  step 'I visit dashboard starred projects page' do
    visit starred_dashboard_projects_path
  end

  # ----------------------------------------
  # Profile
  # ----------------------------------------

  step 'I visit profile page' do
    visit profile_path
  end

  step 'I visit profile applications page' do
    visit applications_profile_path
  end

  step 'I visit profile password page' do
    visit edit_profile_password_path
  end

  step 'I visit profile account page' do
    visit profile_account_path
  end

  step 'I visit profile SSH keys page' do
    visit profile_keys_path
  end

  step 'I visit profile preferences page' do
    visit profile_preferences_path
  end

  step 'I visit Audit Log page' do
    visit audit_log_profile_path
  end

  # ----------------------------------------
  # Admin
  # ----------------------------------------

  step 'I visit admin page' do
    visit admin_root_path
  end

  step 'I visit abuse reports page' do
    visit admin_abuse_reports_path
  end

  step 'I visit admin projects page' do
    visit admin_namespaces_projects_path
  end

  step 'I visit admin users page' do
    visit admin_users_path
  end

  step 'I visit admin logs page' do
    visit admin_logs_path
  end

  step 'I visit admin messages page' do
    visit admin_broadcast_messages_path
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

  step 'I visit admin appearance page' do
    visit admin_appearances_path
  end

  step 'I visit admin teams page' do
    visit admin_teams_path
  end

  step 'I visit admin email page' do
    visit admin_email_path
  end

  step 'I visit admin settings page' do
    visit admin_application_settings_path
  end

  step 'I visit spam logs page' do
    visit admin_spam_logs_path
  end

  step 'I visit applications page' do
    visit admin_applications_path
  end

  step 'I visit push rules page' do
    visit admin_push_rules_path
  end

  step 'I visit admin license page' do
    visit admin_license_path
  end

  # ----------------------------------------
  # Generic Project
  # ----------------------------------------

  step "I visit my project's home page" do
    visit namespace_project_path(@project.namespace, @project)
  end

  step "I visit my project's settings page" do
    visit edit_namespace_project_path(@project.namespace, @project)
  end

  step "I visit my project's files page" do
    visit namespace_project_tree_path(@project.namespace, @project, root_ref)
  end

  step 'I visit a binary file in the repo' do
    visit namespace_project_blob_path(@project.namespace, @project,
      File.join(root_ref, 'files/images/logo-black.png'))
  end

  step "I visit my project's commits page" do
    visit namespace_project_commits_path(@project.namespace, @project, root_ref, { limit: 5 })
  end

  step "I visit my project's commits page for a specific path" do
    visit namespace_project_commits_path(@project.namespace, @project, root_ref + "/app/models/project.rb", { limit: 5 })
  end

  step 'I visit my project\'s commits stats page' do
    visit stats_namespace_project_repository_path(@project.namespace, @project)
  end

  step "I visit my project's network page" do
    # Stub Graph max_size to speed up test (10 commits vs. 650)
    allow(Network::Graph).to receive(:max_count).and_return(10)

    visit namespace_project_network_path(@project.namespace, @project, root_ref)
  end

  step "I visit my project's issues page" do
    visit namespace_project_issues_path(@project.namespace, @project)
  end

  step "I visit my project's merge requests page" do
    visit namespace_project_merge_requests_path(@project.namespace, @project)
  end

  step "I visit my project's members page" do
    visit namespace_project_project_members_path(@project.namespace, @project)
  end

  step "I visit my project's wiki page" do
    visit namespace_project_wiki_path(@project.namespace, @project, :home)
  end

  step 'I visit project hooks page' do
    visit namespace_project_hooks_path(@project.namespace, @project)
  end

  step 'I visit group hooks page' do
    visit group_hooks_path(@group)
  end

  step 'I visit project push rules page' do
    visit namespace_project_push_rules_path(@project.namespace, @project)
  end

  step 'I visit project deploy keys page' do
    visit namespace_project_deploy_keys_path(@project.namespace, @project)
  end

  step 'I visit project find file page' do
    visit namespace_project_find_file_path(@project.namespace, @project, root_ref)
  end

  # ----------------------------------------
  # "Shop" Project
  # ----------------------------------------

  step 'I visit project "Shop" page' do
    visit namespace_project_path(project.namespace, project)
  end

  step 'I visit project "Shop" activity page' do
    visit activity_namespace_project_path(project.namespace, project)
  end

  step 'I visit project "Forked Shop" merge requests page' do
    visit namespace_project_merge_requests_path(@forked_project.namespace, @forked_project)
  end

  step 'I visit edit project "Shop" page' do
    visit edit_namespace_project_path(project.namespace, project)
  end

  step 'I visit project branches page' do
    visit namespace_project_branches_path(@project.namespace, @project)
  end

  step 'I visit project protected branches page' do
    visit namespace_project_protected_branches_path(@project.namespace, @project)
  end

  step 'I visit compare refs page' do
    visit namespace_project_compare_index_path(@project.namespace, @project)
  end

  step 'I visit project commits page' do
    visit namespace_project_commits_path(@project.namespace, @project, root_ref, { limit: 5 })
  end

  step 'I visit project commits page for stable branch' do
    visit namespace_project_commits_path(@project.namespace, @project, 'stable', { limit: 5 })
  end

  step 'I visit project source page' do
    visit namespace_project_tree_path(@project.namespace, @project, root_ref)
  end

  step 'I visit blob file from repo' do
    visit namespace_project_blob_path(@project.namespace, @project, File.join(sample_commit.id, sample_blob.path))
  end

  step 'I visit ".gitignore" file in repo' do
    visit namespace_project_blob_path(@project.namespace, @project, File.join(root_ref, '.gitignore'))
  end

  step 'I am on the new file page' do
    expect(current_path).to eq(namespace_project_create_blob_path(@project.namespace, @project, root_ref))
  end

  step 'I am on the ".gitignore" edit file page' do
    expect(current_path).to eq(
      namespace_project_edit_blob_path(@project.namespace, @project, File.join(root_ref, '.gitignore')))
  end

  step 'I visit project source page for "6d39438"' do
    visit namespace_project_tree_path(@project.namespace, @project, "6d39438")
  end

  step 'I visit project source page for' \
       ' "6d394385cf567f80a8fd85055db1ab4c5295806f"' do
    visit namespace_project_tree_path(@project.namespace, @project,
                            '6d394385cf567f80a8fd85055db1ab4c5295806f')
  end

  step 'I visit project tags page' do
    visit namespace_project_tags_path(@project.namespace, @project)
  end

  step 'I visit project commit page' do
    visit namespace_project_commit_path(@project.namespace, @project, sample_commit.id)
  end

  step 'I visit project "Shop" issues page' do
    visit namespace_project_issues_path(project.namespace, project)
  end

  step 'I visit issue page "Release 0.4"' do
    issue = Issue.find_by(title: "Release 0.4")
    visit namespace_project_issue_path(issue.project.namespace, issue.project, issue)
  end

  step 'I visit project "Shop" labels page' do
    project = Project.find_by(name: 'Shop')
    visit namespace_project_labels_path(project.namespace, project)
  end

  step 'I visit project "Forum" labels page' do
    project = Project.find_by(name: 'Forum')
    visit namespace_project_labels_path(project.namespace, project)
  end

  step 'I visit project "Shop" new label page' do
    project = Project.find_by(name: 'Shop')
    visit new_namespace_project_label_path(project.namespace, project)
  end

  step 'I visit project "Forum" new label page' do
    project = Project.find_by(name: 'Forum')
    visit new_namespace_project_label_path(project.namespace, project)
  end

  step 'I visit merge request page "Bug NS-04"' do
    visit merge_request_path("Bug NS-04")
  end

  step 'I visit merge request page "Bug NS-05"' do
    visit merge_request_path("Bug NS-05")
  end

  step 'I visit merge request page "Bug NS-07"' do
    visit merge_request_path("Bug NS-07")
  end

  step 'I visit merge request page "Bug NS-08"' do
    visit merge_request_path("Bug NS-08")
  end

  step 'I visit merge request page "Bug CO-01"' do
    mr = MergeRequest.find_by(title: "Bug CO-01")
    visit namespace_project_merge_request_path(mr.target_project.namespace, mr.target_project, mr)
  end

  step 'I visit project "Shop" merge requests page' do
    visit namespace_project_merge_requests_path(project.namespace, project)
  end

  step 'I visit forked project "Shop" merge requests page' do
    visit namespace_project_merge_requests_path(project.namespace, project)
  end

  step 'I visit project "Shop" milestones page' do
    visit namespace_project_milestones_path(project.namespace, project)
  end

  step 'I visit project "Shop" team page' do
    visit namespace_project_project_members_path(project.namespace, project)
  end

  step 'I visit project wiki page' do
    visit namespace_project_wiki_path(@project.namespace, @project, :home)
  end

  # ----------------------------------------
  # Visibility Projects
  # ----------------------------------------

  step 'I visit project "Community" page' do
    project = Project.find_by(name: "Community")
    visit namespace_project_path(project.namespace, project)
  end

  step 'I visit project "Community" source page' do
    project = Project.find_by(name: 'Community')
    visit namespace_project_tree_path(project.namespace, project, root_ref)
  end

  step 'I visit project "Internal" page' do
    project = Project.find_by(name: "Internal")
    visit namespace_project_path(project.namespace, project)
  end

  step 'I visit project "Enterprise" page' do
    project = Project.find_by(name: "Enterprise")
    visit namespace_project_path(project.namespace, project)
  end

  # ----------------------------------------
  # Empty Projects
  # ----------------------------------------

  step "I visit empty project page" do
    project = Project.find_by(name: "Empty Public Project")
    visit namespace_project_path(project.namespace, project)
  end

  step "I should not see command line instructions" do
    expect(page).not_to have_css('.empty_wrapper')
  end

  # ----------------------------------------
  # Public Projects
  # ----------------------------------------

  step 'I visit the public projects area' do
    visit explore_projects_path
  end

  step 'I visit the explore trending projects' do
    visit trending_explore_projects_path
  end

  step 'I visit the explore starred projects' do
    visit starred_explore_projects_path
  end

  step 'I visit the public groups area' do
    visit explore_groups_path
  end

  # ----------------------------------------
  # Snippets
  # ----------------------------------------

  step 'I visit project "Shop" snippets page' do
    visit namespace_project_snippets_path(project.namespace, project)
  end

  step 'I visit snippets page' do
    visit explore_snippets_path
  end

  step 'I visit new snippet page' do
    visit new_snippet_path
  end

  def root_ref
    @project.repository.root_ref
  end

  def project
    Project.find_by!(name: 'Shop')
  end

  def merge_request_path(title)
    mr = MergeRequest.find_by(title: title)
    namespace_project_merge_request_path(mr.target_project.namespace, mr.target_project, mr)
  end

  # ----------------------------------------
  # Errors
  # ----------------------------------------

  step 'page status code should be 404' do
    expect(status_code).to eq 404
  end
end
