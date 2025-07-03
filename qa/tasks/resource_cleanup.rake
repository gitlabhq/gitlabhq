# frozen_string_literal: true

desc "Deletes subgroups within a provided group"
task :delete_subgroups, [:dry_run] do |_, args|
  args.with_defaults(dry_run: false)
  QA::Tools::DeleteSubgroups.new(dry_run: args[:dry_run]).run
end

desc "Deletes test ssh keys a user"
task :delete_test_ssh_keys, [:title_portion, :dry_run] do |_, args|
  args.with_defaults(title_portion: 'E2E test key:', dry_run: false)
  QA::Tools::DeleteTestSshKeys.new(title_portion: args[:title_portion], dry_run: args[:dry_run]).run
end

desc "Deletes projects directly under the provided group"
task :delete_projects, [:dry_run] do |_, args|
  args.with_defaults(dry_run: false)
  QA::Tools::DeleteProjects.new(dry_run: args[:dry_run]).run
end

desc "Deletes test users"
task :delete_test_users, [:dry_run, :exclude_users] do |_, args|
  args.with_defaults(dry_run: false, exclude_users: nil)
  QA::Tools::DeleteTestUsers.new(dry_run: args[:dry_run], exclude_users: args[:exclude_users]).run
end

desc "Deletes snippets"
task :delete_test_snippets, [:dry_run] do |_, args|
  args.with_defaults(dry_run: false)
  QA::Tools::DeleteTestSnippets.new(dry_run: args[:dry_run]).run
end

desc "Deletes user's projects"
task :delete_user_projects, [:dry_run] do |_, args|
  args.with_defaults(dry_run: false)
  QA::Tools::DeleteUserProjects.new(dry_run: args[:dry_run]).run
end

desc "Deletes user groups"
task :delete_user_groups, [:dry_run, :exclude_groups] do |_, args|
  args.with_defaults(dry_run: false, exclude_groups: nil)
  QA::Tools::DeleteUserGroups.new(dry_run: args[:dry_run], exclude_groups: args[:exclude_groups]).run
end

desc "Revokes user's personal access tokens"
task :revoke_user_pats, [:dry_run] do |_, args|
  args.with_defaults(dry_run: false)
  QA::Tools::RevokeUserPersonalAccessTokens.new(dry_run: !!(args[:dry_run].to_s =~ /true|1|y/i)).run
end

namespace :test_resources do
  desc "Deletes resources created during E2E test runs"
  task :delete, [:file_pattern] do |_, args|
    QA::Tools::TestResourcesHandler.new(args[:file_pattern]).run_delete
  end

  desc "Upload test resources JSON files to GCS"
  task :upload, [:file_pattern, :ci_project_name] do |_, args|
    QA::Tools::TestResourcesHandler.new(args[:file_pattern]).upload(args[:ci_project_name])
  end

  desc "Download test resources JSON files from GCS"
  task :download, [:ci_project_name] do |_, args|
    QA::Tools::TestResourcesHandler.new.download(args[:ci_project_name])
  end
end
