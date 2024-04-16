---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Troubleshooting Geo synchronization

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** Self-managed

## Reverify all uploads (or any SSF data type which is verified)

1. SSH into a GitLab Rails node in the primary Geo site.
1. Open [Rails console](../../../operations/rails_console.md).
1. Mark all uploads as "pending verification":

WARNING:
Commands that change data can cause damage if not run correctly or under the right conditions. Always run commands in a test environment first and have a backup instance ready to restore.

   ```ruby
   Upload.verification_state_table_class.each_batch do |relation|
     relation.update_all(verification_state: 0)
   end
   ```

1. This causes the primary to start checksumming all Uploads.
1. When a primary successfully checksums a record, then all secondaries recalculate the checksum as well, and they compare the values.

You can perform a similar operation with other the Models handled by the [Geo Self-Service Framework](../../../../development/geo/framework.md) which have implemented verification:

- `LfsObject`
- `MergeRequestDiff`
- `Packages::PackageFile`
- `Terraform::StateVersion`
- `SnippetRepository`
- `Ci::PipelineArtifact`
- `PagesDeployment`
- `Upload`
- `Ci::JobArtifact`
- `Ci::SecureFile`

NOTE:
`GroupWikiRepository` is not in the previous list since verification is not implemented.
There is an [issue to implement this functionality in the Admin Area UI](https://gitlab.com/gitlab-org/gitlab/-/issues/364729).

## Message: `Synchronization failed - Error syncing repository`

WARNING:
If large repositories are affected by this problem,
their resync may take a long time and cause significant load on your Geo sites,
storage and network systems.

The following error message indicates a consistency check error when syncing the repository:

```plaintext
Synchronization failed - Error syncing repository [..] fatal: fsck error in packed object
```

Several issues can trigger this error. For example, problems with email addresses:

```plaintext
Error syncing repository: 13:fetch remote: "error: object <SHA>: badEmail: invalid author/committer line - bad email
   fatal: fsck error in packed object
   fatal: fetch-pack: invalid index-pack output
```

Another issue that can trigger this error is `object <SHA>: hasDotgit: contains '.git'`. Check the specific errors because you might have more than one problem across all
your repositories.

A second synchronization error can also be caused by repository check issues:

```plaintext
Error syncing repository: 13:Received RST_STREAM with error code 2.
```

These errors can be observed by [immediately syncing all failed repositories](#sync-all-failed-repositories-now).

Removing the malformed objects causing consistency errors involves rewriting the repository history, which is usually not an option.

To ignore these consistency checks, reconfigure Gitaly **on the secondary Geo sites** to ignore these `git fsck` issues.
The following configuration example:

- [Uses the new configuration structure](../../../../update/versions/gitlab_16_changes.md#gitaly-configuration-structure-change) required from GitLab 16.0.
- Ignores five common check failures.

[The Gitaly documentation has more details](../../../gitaly/consistency_checks.md)
about other Git check failures and earlier versions of GitLab.

```ruby
gitaly['configuration'] = {
  git: {
    config: [
      { key: "fsck.duplicateEntries", value: "ignore" },
      { key: "fsck.badFilemode", value: "ignore" },
      { key: "fsck.missingEmail", value: "ignore" },
      { key: "fsck.badEmail", value: "ignore" },
      { key: "fsck.hasDotgit", value: "ignore" },
      { key: "fetch.fsck.duplicateEntries", value: "ignore" },
      { key: "fetch.fsck.badFilemode", value: "ignore" },
      { key: "fetch.fsck.missingEmail", value: "ignore" },
      { key: "fetch.fsck.badEmail", value: "ignore" },
      { key: "fetch.fsck.hasDotgit", value: "ignore" },
      { key: "receive.fsck.duplicateEntries", value: "ignore" },
      { key: "receive.fsck.badFilemode", value: "ignore" },
      { key: "receive.fsck.missingEmail", value: "ignore" },
      { key: "receive.fsck.badEmail", value: "ignore" },
      { key: "receive.fsck.hasDotgit", value: "ignore" },
    ],
  },
}
```

GitLab 16.1 and later [include an enhancement](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/5879) that might resolve some of these issues.

[Gitaly issue 5625](https://gitlab.com/gitlab-org/gitaly/-/issues/5625) proposes to ensure that Geo replicates repositories even if the source repository contains
problematic commits.

### Related error `does not appear to be a git repository`

You can also get the error message `Synchronization failed - Error syncing repository` along with the following log messages.
This error indicates that the expected Geo remote is not present in the `.git/config` file
of a repository on the secondary Geo site's file system:

```json
{
  "created": "@1603481145.084348757",
  "description": "Error received from peer unix:/var/opt/gitlab/gitaly/gitaly.socket",
  …
  "grpc_message": "exit status 128",
  "grpc_status": 13
}
{  …
  "grpc.request.fullMethod": "/gitaly.RemoteService/FindRemoteRootRef",
  "grpc.request.glProjectPath": "<namespace>/<project>",
  …
  "level": "error",
  "msg": "fatal: 'geo' does not appear to be a git repository
          fatal: Could not read from remote repository. …",
}
```

To solve this:

1. Sign in on the web interface for the secondary Geo site.

1. Back up [the `.git` folder](../../../repository_storage_paths.md#translate-hashed-storage-paths).

1. Optional. [Spot-check](../../../logs/log_parsing.md#find-all-projects-affected-by-a-fatal-git-problem)
   a few of those IDs whether they indeed correspond
   to a project with known Geo replication failures.
   Use `fatal: 'geo'` as the `grep` term and the following API call:

   ```shell
   curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/<first_failed_geo_sync_ID>"
   ```

1. Enter the [Rails console](../../../operations/rails_console.md) and run:

   ```ruby
   failed_geo_syncs = Geo::ProjectRegistry.failed.pluck(:id)
   failed_geo_syncs.each do |fgs|
     puts Geo::ProjectRegistry.failed.find(fgs).project_id
   end
   ```

1. Run the following commands to reset each project's
   Geo-related attributes and execute a new sync:

   ```ruby
   failed_geo_syncs.each do |fgs|
     registry = Geo::ProjectRegistry.failed.find(fgs)
     registry.update(resync_repository: true, force_to_redownload_repository: false, repository_retry_count: 0)
     Geo::RepositorySyncService.new(registry.project).execute
   end
   ```

## Failures during backfill

During a [backfill](../../index.md#backfill), failures are scheduled to be retried at the end
of the backfill queue, therefore these failures only clear up **after** the backfill completes.

## Sync failure message: "Verification failed with: Error during verification: File is not checksummable"

### Missing files on the Geo primary site

In GitLab 14.5 and earlier, certain data types which were missing on the Geo primary site were marked as "synced" on Geo secondary sites. This was because from the perspective of Geo secondary sites, the state matched the primary site and nothing more could be done on secondary sites.

Secondaries would regularly try to sync these files again by using the "verification" feature:

- Verification fails since the file doesn't exist.
- The file is marked "sync failed".
- Sync is retried.
- The file is marked "sync succeeded".
- The file is marked "needs verification".
- Repeat until the file is available again on the primary site.

This can be confusing to troubleshoot, since the registry entries are moved through a logical loop by various background jobs. Also, `last_sync_failure` and `verification_failure` are empty after "sync succeeded" but before verification is retried.

If you see sync failures repeatedly and alternately increase, while successes decrease and vice versa, this is likely to be caused by missing files on the primary site. You can confirm this by searching `geo.log` on secondary sites for `File is not checksummable` affecting the same files over and over.

After confirming this is the problem, the files on the primary site need to be fixed. Some possible causes:

- An NFS share became unmounted.
- A disk died or became corrupted.
- Someone unintentionally deleted a file or directory.
- Bugs in GitLab application:
  - A file was moved when it shouldn't have been moved.
  - A file wasn't moved when it should have been moved.
  - A wrong path was generated in the code.
- A non-atomic backup was restored.
- Services or servers or network infrastructure was interrupted/restarted during use.

The appropriate action sometimes depends on the cause. For example, you can remount an NFS share. Often, a root cause may not be apparent or not useful to discover. If you have regular backups, it may be expedient to look through them and pull files from there.

In some cases, a file may be determined to be of low value, and so it may be worth deleting the record.

Geo itself is an excellent mitigation for files missing on the primary. If a file disappears on the primary but it was already synced to the secondary, you can grab the secondary's file. In cases like this, the `File is not checksummable` error message does not occur on Geo secondary sites, and only the primary logs this error message.

This problem is more likely to show up in Geo secondary sites which were set up long after the original GitLab site. In this case, Geo is only surfacing an existing problem.

This behavior affects only the following data types through GitLab 14.6:

| Data type                | From version |
| ------------------------ | ------------ |
| Package registry         | 13.10        |
| CI Pipeline Artifacts    | 13.11        |
| Terraform State Versions | 13.12        |
| Infrastructure Registry (renamed to Terraform Module Registry in GitLab 15.11) | 14.0 |
| External MR diffs        | 14.6         |
| LFS Objects              | 14.6         |
| Pages Deployments        | 14.6         |
| Uploads                  | 14.6         |
| CI Job Artifacts         | 14.6         |

[Since GitLab 14.7, files that are missing on the primary site are now treated as sync failures](https://gitlab.com/gitlab-org/gitlab/-/issues/348745)
to make Geo visibly surface data loss risks. The sync/verification loop is
therefore short-circuited. `last_sync_failure` is now set to `The file is missing on the Geo primary site`.

### Failed syncs with GitLab-managed object storage replication

There is [an issue in GitLab 14.2 through 14.7](https://gitlab.com/gitlab-org/gitlab/-/issues/299819#note_822629467)
that affects Geo when the GitLab-managed object storage replication is used, causing blob object types to fail synchronization.

Since GitLab 14.2, verification failures result in synchronization failures and cause
a re-synchronization of these objects.

As verification is not implemented for files stored in object storage (see
[issue 13845](https://gitlab.com/gitlab-org/gitlab/-/issues/13845) for more details), this
results in a loop that consistently fails for all objects stored in object storage.

You can work around this by marking the objects as synced and succeeded verification, however
be aware that can also mark objects that may be
[missing from the primary](#missing-files-on-the-geo-primary-site).

To do that, enter the [Rails console](../../../operations/rails_console.md)
and run:

```ruby
Gitlab::Geo.verification_enabled_replicator_classes.each do |klass|
  updated = klass.registry_class.failed.where(last_sync_failure: "Verification failed with: Error during verification: File is not checksummable").update_all(verification_checksum: '0000000000000000000000000000000000000000', verification_state: 2, verification_failure: nil, verification_retry_at: nil, state: 2, last_sync_failure: nil, retry_at: nil, verification_retry_count: 0, retry_count: 0)
  pp "Updated #{updated} #{klass.replicable_name_plural}"
end
```

## Message: curl 18 transfer closed with outstanding read data remaining & fetch-pack: unexpected disconnect while reading sideband packet

Unstable networking conditions can cause Gitaly to fail when trying to fetch large repository
data from the primary site. This is more likely to happen if a repository has to be
replicated from scratch between sites.

Geo retries several times, but if the transmission is consistently interrupted
by network hiccups, an alternative method such as `rsync` can be used to circumvent `git` and
create the initial copy of any repository that fails to be replicated by Geo.

We recommend transferring each failing repository individually and checking for consistency
after each transfer. Follow the [single target `rsync` instructions](../../../operations/moving_repositories.md#single-rsync-to-another-server)
to transfer each affected repository from the primary to the secondary site.

## Project or project wiki repositories

### Find repository verification failures

[Start a Rails console session](../../../../administration/operations/rails_console.md#starting-a-rails-console-session)
**on the secondary Geo site** to gather more information.

WARNING:
Commands that change data can cause damage if not run correctly or under the right conditions. Always run commands in a test environment first and have a backup instance ready to restore.

#### Get the number of verification failed repositories

```ruby
Geo::ProjectRegistry.verification_failed('repository').count
```

#### Find the verification failed repositories

```ruby
Geo::ProjectRegistry.verification_failed('repository')
```

#### Find repositories that failed to sync

```ruby
Geo::ProjectRegistry.sync_failed('repository')
```

### Resync project and project wiki repositories

[Start a Rails console session](../../../../administration/operations/rails_console.md#starting-a-rails-console-session)
**on the secondary Geo site** to perform the following changes.

WARNING:
Commands that change data can cause damage if not run correctly or under the right conditions. Always run commands in a test environment first and have a backup instance ready to restore.

#### Queue up all repositories for resync

When you run this, the sync is handled in the background by Sidekiq.

```ruby
Geo::ProjectRegistry.update_all(resync_repository: true, resync_wiki: true)
```

#### Sync individual repository now

```ruby
project = Project.find_by_full_path('<group/project>')

Geo::RepositorySyncService.new(project).execute
```

#### Sync all failed repositories now

The following script:

- Loops over all currently failed repositories.
- Displays the project details and the reasons for the last failure.
- Attempts to resync the repository.
- Reports back if a failure occurs, and why.
- Might take some time to complete. Each repository check must complete
  before reporting back the result. If your session times out, take measures
  to allow the process to continue running such as starting a `screen` session,
  or running it using [Rails runner](../../../operations/rails_console.md#using-the-rails-runner)
  and `nohup`.

```ruby
Geo::ProjectRegistry.sync_failed('repository').find_each do |p|
   begin
     project = p.project
     puts "#{project.full_path} | id: #{p.project_id} | last error: '#{p.last_repository_sync_failure}'"
     Geo::RepositorySyncService.new(project).execute
   rescue => e
     puts "ID: #{p.project_id} failed: '#{e}'", e.backtrace.join("\n")
   end
end ; nil
```

## Find repository check failures in a Geo secondary site

When [enabled for all projects](../../../repository_checks.md#enable-repository-checks-for-all-projects), [Repository checks](../../../repository_checks.md) are also performed on Geo secondary sites. The metadata is stored in the Geo tracking database.

Repository check failures on a Geo secondary site do not necessarily imply a replication problem. Here is a general approach to resolve these failures.

1. Find affected repositories as mentioned below, as well as their [logged errors](../../../repository_checks.md#what-to-do-if-a-check-failed).
1. Try to diagnose specific `git fsck` errors. The range of possible errors is wide, try putting them into search engines.
1. Test typical functions of the affected repositories. Pull from the secondary, view the files.
1. Check if the primary site's copy of the repository has an identical `git fsck` error. If you are planning a failover, then consider prioritizing that the secondary site has the same information that the primary site has. Ensure you have a backup of the primary, and follow [planned failover guidelines](../../disaster_recovery/planned_failover.md).
1. Push to the primary and check if the change gets replicated to the secondary site.
1. If replication is not automatically working, try to manually sync the repository.

[Start a Rails console session](../../../operations/rails_console.md#starting-a-rails-console-session)
to enact the following, basic troubleshooting steps.

WARNING:
Commands that change data can cause damage if not run correctly or under the right conditions. Always run commands in a test environment first and have a backup instance ready to restore.

### Get the number of repositories that failed the repository check

```ruby
Geo::ProjectRegistry.where(last_repository_check_failed: true).count
```

### Find the repositories that failed the repository check

```ruby
Geo::ProjectRegistry.where(last_repository_check_failed: true)
```

### Recheck repositories that failed the repository check

When you run this, `fsck` is executed against each failed repository.

The [`fsck` Rake command](../../../raketasks/check.md#check-project-code-repositories) can be used on the secondary site to understand why the repository check might be failing.

```ruby
Geo::ProjectRegistry.where(last_repository_check_failed: true).each do |pr|
    RepositoryCheck::SingleRepositoryWorker.new.perform(pr.project_id)
end
```
