---
stage: Foundations
group: Import and Integrate
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
title: Troubleshooting file export project migrations
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

If you have problems with [migrating projects by using file exports](import_export.md), see the possible solutions below.

## Troubleshooting commands

Finds information about the status of the import and further logs using the JID,
using the [Rails console](../../../administration/operations/rails_console.md):

```ruby
Project.find_by_full_path('group/project').import_state.slice(:jid, :status, :last_error)
> {"jid"=>"414dec93f941a593ea1a6894", "status"=>"finished", "last_error"=>nil}
```

```shell
# Logs
grep JID /var/log/gitlab/sidekiq/current
grep "Import/Export error" /var/log/gitlab/sidekiq/current
grep "Import/Export backtrace" /var/log/gitlab/sidekiq/current
tail /var/log/gitlab/gitlab-rails/importer.log
```

## Project fails to import due to mismatch

If the [instance runners enablement](../../../ci/runners/runners_scope.md#enable-instance-runners-for-a-project)
does not match between the exported project, and the project import, the project fails to import.
Review [issue 276930](https://gitlab.com/gitlab-org/gitlab/-/issues/276930), and either:

- Ensure instance runners are enabled in both the source and destination projects.
- Disable instance runners on the parent group when you import the project.

## Users missing from imported project

If users aren't imported with imported projects, see the [preserving user contributions](import_export.md#preserving-user-contributions) requirements.

A common reason for missing users is that the [public email setting](../../profile/_index.md#set-your-public-email) isn't configured for users.
To resolve this issue, ask users to configure this setting using the GitLab UI.

If there are too many users for manual configuration to be feasible,
you can set all user profiles to use a public email address using the
[Rails console](../../../administration/operations/rails_console.md#starting-a-rails-console-session):

```ruby
User.where("public_email IS NULL OR public_email = '' ").find_each do |u|
  next if u.bot?

  puts "Setting #{u.username}'s currently empty public email to #{u.email}…"
  u.public_email = u.email
  u.save!
end
```

## Import workarounds for large repositories

[Maximum import size limitations](import_export.md#import-a-project-and-its-data)
can prevent an import from being successful. If changing the import limits is not possible, you can
try one of the workarounds listed here.

### Workaround option 1

The following local workflow can be used to temporarily
reduce the repository size for another import attempt:

1. Create a temporary working directory from the export:

   ```shell
   EXPORT=<filename-without-extension>

   mkdir "$EXPORT"
   tar -xf "$EXPORT".tar.gz --directory="$EXPORT"/
   cd "$EXPORT"/
   git clone project.bundle

   # Prevent interference with recreating an importable file later
   mv project.bundle ../"$EXPORT"-original.bundle
   mv ../"$EXPORT".tar.gz ../"$EXPORT"-original.tar.gz

   git switch --create smaller-tmp-main
   ```

1. To reduce the repository size, work on this `smaller-tmp-main` branch:
   [identify and remove large files](../repository/repository_size.md#methods-to-reduce-repository-size)
   or [interactively rebase and fixup](../../../topics/git/git_rebase.md#interactive-rebase)
   to reduce the number of commits.

   ```shell
   # Reduce the .git/objects/pack/ file size
   cd project
   git reflog expire --expire=now --all
   git gc --prune=now --aggressive

   # Prepare recreating an importable file
   git bundle create ../project.bundle <default-branch-name>
   cd ..
   mv project/ ../"$EXPORT"-project
   cd ..

   # Recreate an importable file
   tar -czf "$EXPORT"-smaller.tar.gz --directory="$EXPORT"/ .
   ```

1. Import this new, smaller file into GitLab.
1. In a full clone of the original repository,
   use `git remote set-url origin <new-url> && git push --force --all`
   to complete the import.
1. Update the imported repository's
   [branch protection rules](../repository/branches/protected.md) and
   its [default branch](../repository/branches/default.md), and
   delete the temporary, `smaller-tmp-main` branch, and
   the local, temporary data.

### Workaround option 2

NOTE:
This workaround does not account for LFS objects.

Rather than attempting to push all changes at once, this workaround:

- Separates the project import from the Git Repository import
- Incrementally pushes the repository to GitLab

1. Make a local clone of the repository to migrate. In a later step, you push this clone outside of
   the project export.
1. Download the export and remove the `project.bundle` (which contains the Git repository):

   ```shell
   tar -czvf new_export.tar.gz --exclude='project.bundle' @old_export.tar.gz
   ```

1. Import the export without a Git repository. It asks you to confirm to import without a
   repository.
1. Save this bash script as a file and run it after adding the appropriate origin.

   ```shell
   #!/bin/sh

   # ASSUMPTIONS:
   # - The GitLab location is "origin"
   # - The default branch is "main"
   # - This will attempt to push in chunks of 500MB (dividing the total size by 500MB).
   #   Decrease this size to push in smaller chunks if you still receive timeouts.

   git gc
   SIZE=$(git count-objects -v 2> /dev/null | grep size-pack | awk '{print $2}')

   # Be conservative... and try to push 2GB at a time
   # (given this assumes each commit is the same size - which is wrong)
   BATCHES=$(($SIZE / 500000))
   TOTAL_COMMITS=$(git rev-list --count HEAD)
   if (( BATCHES > TOTAL_COMMITS )); then
       BATCHES=$TOTAL_COMMITS
   fi

   INCREMENTS=$(( ($TOTAL_COMMITS / $BATCHES) - 1 ))

   for (( BATCH=BATCHES; BATCH>=1; BATCH-- ))
   do
     COMMIT_NUM=$(( $BATCH - $INCREMENTS ))
     COMMIT_SHA=$(git log -n $COMMIT_NUM --format=format:%H | tail -1)
     git push -u origin ${COMMIT_SHA}:refs/heads/main
   done
   git push -u origin main
   git push -u origin --all
   git push -u origin --tags
   ```

## Sidekiq process fails to export a project

Occasionally the Sidekiq process can fail to export a project, for example if
it is terminated during execution.

GitLab.com users should [contact Support](https://about.gitlab.com/support/#contact-support) to resolve this issue.

GitLab Self-Managed administrators can use the Rails console to bypass the Sidekiq process and
manually trigger the project export:

```ruby
project = Project.find(1)
current_user = User.find_by(username: 'my-user-name')
RequestStore.begin!
ActiveRecord::Base.logger = Logger.new(STDOUT)
params = {}

::Projects::ImportExport::ExportService.new(project, current_user, params).execute(nil)
```

This makes the export available through the UI, but does not trigger an email to the user.
To manually trigger the project export and send an email:

```ruby
project = Project.find(1)
current_user = User.find_by(username: 'my-user-name')
RequestStore.begin!
ActiveRecord::Base.logger = Logger.new(STDOUT)
params = {}

ProjectExportWorker.new.perform(current_user.id, project.id)
```

## Manually execute export steps

You usually export a project through [the web interface](import_export.md#export-a-project-and-its-data) or through [the API](../../../api/project_import_export.md). Exporting using these
methods can sometimes fail without giving enough information to troubleshoot. In these cases,
[open a Rails console session](../../../administration/operations/rails_console.md#starting-a-rails-console-session) and loop through
[all the defined exporters](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/services/projects/import_export/export_service.rb).
Execute each line individually, rather than pasting the entire block at once, so you can see any
errors each command returns.

```ruby
# User needs to have permission to export
u = User.find_by_username('someuser')
p = Project.find_by_full_path('some/project')
e = Projects::ImportExport::ExportService.new(p,u)

e.send(:version_saver).send(:save)
e.send(:repo_saver).send(:save)
e.send(:avatar_saver).send(:save)
e.send(:project_tree_saver).send(:save)
e.send(:uploads_saver).send(:save)
e.send(:wiki_repo_saver).send(:save)
e.send(:lfs_saver).send(:save)
e.send(:snippets_repo_saver).send(:save)
e.send(:design_repo_saver).send(:save)
## continue using `e.send(:exporter_name).send(:save)` going through the list of exporters

# The following line should show you the export_path similar to /var/opt/gitlab/gitlab-rails/shared/tmp/gitlab_exports/@hashed/49/94/4994....
s = Gitlab::ImportExport::Saver.new(exportable: p, shared: p.import_export_shared, user: u)

# Prior to GitLab 17.0, the `user` parameter was not supported. If you encounter an
# error with the above or are unsure whether or not to supply the `user`
# argument, use the following check:
Gitlab::ImportExport::Saver.instance_method(:initialize).parameters.include?([:keyreq, :user])
# If the preceding check returns false, omit the user argument:
s = Gitlab::ImportExport::Saver.new(exportable: p, shared: p.import_export_shared)

# To try and upload use:
s.send(:compress_and_save)
s.send(:save_upload)
```

After the project is successfully uploaded, the exported project is located in a `.tar.gz` file in `/var/opt/gitlab/gitlab-rails/uploads/-/system/import_export_upload/export_file/`.

## Import using the REST API fails when using a group access token

[Group access tokens](../../group/settings/group_access_tokens.md)
don't work for project or group import operations. When a group access token initiates an import,
the import fails with this message:

```plaintext
Error adding importer user to Project members.
Validation failed: User project bots cannot be added to other groups / projects
```

To use [Import REST API](../../../api/project_import_export.md),
pass regular user account credentials such as [personal access tokens](../../profile/personal_access_tokens.md).

## Error: `PG::QueryCanceled: ERROR: canceling statement due to statement timeout`

Some migrations can time out with the error: `PG::QueryCanceled: ERROR: canceling statement due to statement timeout`.
One way to avoid this problem is to have the migration batch size reduced. This makes a migration less likely to time
out, but makes migrations slower.

To have the batch sized reduced, you must have a feature flag enabled. For more information, see
[issue 456948](https://gitlab.com/gitlab-org/gitlab/-/issues/456948).

## Error: `command exited with error code 15 and Unable to save [FILTERED] into [FILTERED]`

You might receive the error `command exited with error code 15 and Unable to save [FILTERED] into [FILTERED]` in logs
when migrating projects by using file exports. If you receive this error:

- When exporting a file export, you can safely ignore the error. GitLab retries the exited command.
- When importing a file import, you must retry the import. GitLab doesn't automatically retry the import.

## Troubleshooting performance issues

Read through the current performance problems using the Import/Export below.

### OOM errors

Out of memory (OOM) errors are usually caused by the [Sidekiq Memory Killer](../../../administration/sidekiq/sidekiq_memory_killer.md):

```shell
SIDEKIQ_MEMORY_KILLER_MAX_RSS = 2000000
SIDEKIQ_MEMORY_KILLER_HARD_LIMIT_RSS = 3000000
SIDEKIQ_MEMORY_KILLER_GRACE_TIME = 900
```

An import status `started`, and the following Sidekiq logs signal a memory issue:

```shell
WARN: Work still in progress <struct with JID>
```

### Timeouts

Timeout errors occur due to the `Gitlab::Import::StuckProjectImportJobsWorker` marking the process as failed:

```ruby
module Gitlab
  module Import
    class StuckProjectImportJobsWorker
      include Gitlab::Import::StuckImportJob
      # ...
    end
  end
end

module Gitlab
  module Import
    module StuckImportJob
      # ...
      IMPORT_JOBS_EXPIRATION = 15.hours.to_i
      # ...
      def perform
        stuck_imports_without_jid_count = mark_imports_without_jid_as_failed!
        stuck_imports_with_jid_count = mark_imports_with_jid_as_failed!

        track_metrics(stuck_imports_with_jid_count, stuck_imports_without_jid_count)
      end
      # ...
    end
  end
end
```

```shell
Marked stuck import jobs as failed. JIDs: xyz
```

```plaintext
  +-----------+    +-----------------------------------+
  |Export Job |--->| Calls ActiveRecord `as_json` and  |
  +-----------+    | `to_json` on all project models   |
                   +-----------------------------------+

  +-----------+    +-----------------------------------+
  |Import Job |--->| Loads all JSON in memory, then    |
  +-----------+    | inserts into the DB in batches    |
                   +-----------------------------------+
```

### Problems and solutions

| Problem | Possible solutions |
| -------- | -------- |
| [Slow JSON](https://gitlab.com/gitlab-org/gitlab/-/issues/25251) loading/dumping models from the database | [split the worker](https://gitlab.com/gitlab-org/gitlab/-/issues/25252) |
| | Batch export |
| | Optimize SQL |
| | Move away from `ActiveRecord` callbacks (difficult) |
| High memory usage (see also some [analysis](https://gitlab.com/gitlab-org/gitlab/-/issues/18857)) | DB Commit sweet spot that uses less memory |
| | [Netflix Fast JSON API](https://github.com/Netflix/fast_jsonapi) may help |
| | Batch reading/writing to disk and any SQL |
