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

### Reverify all uploads

```ruby
Upload.verification_state_table_class.each_batch do |relation|
  relation.update_all(verification_state: 0)
end
```

### Reverify failed uploads only

```ruby
Upload.verification_state_table_class.where(verification_state: 3).each_batch do |relation|
  relation.update_all(verification_state: 0)
end
```

### How the reverification process works

When you [reverify all uploads](#reverify-all-uploads) or [reverify failed uploads only](#reverify-failed-uploads-only):

1. This causes the primary to start checksumming the Uploads depending on which commands were executed.
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
There is an [issue to implement this functionality in the Admin area UI](https://gitlab.com/gitlab-org/gitlab/-/issues/364729).

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
   failed_project_registries = Geo::ProjectRepositoryRegistry.failed

   if failed_project_registries.any?
     puts "Found #{failed_project_registries.count} failed project repository registry entries:"

     failed_project_registries.each do |registry|
       puts "ID: #{registry.id}, Project ID: #{registry.project_id}, Last Sync Failure: '#{registry.last_sync_failure}'"
     end
   else
     puts "No failed project repository registry entries found."
   end
   ```

1. Run the following commands to execute a new sync for each project:

   ```ruby
   failed_project_registries.each do |registry|
     registry.replicator.sync
     puts "Sync initiated for registry ID: #{registry.id}, Project ID: #{registry.project_id}"
   end
   ```

## Failures during backfill

During a [backfill](../../index.md#backfill), failures are scheduled to be retried at the end
of the backfill queue, therefore these failures only clear up **after** the backfill completes.

## Message: `unexpected disconnect while reading sideband packet`

Unstable networking conditions can cause Gitaly to fail when trying to fetch large repository
data from the primary site. Those conditions can result in this error:

```plaintext
curl 18 transfer closed with outstanding read data remaining & fetch-pack:
unexpected disconnect while reading sideband packet
```

This error is more likely to happen if a repository has to be
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
Geo::ProjectRepositoryRegistry.verification_failed.count
```

#### Find the verification failed repositories

```ruby
Geo::ProjectRepositoryRegistry.verification_failed
```

#### Find repositories that failed to sync

```ruby
Geo::ProjectRepositoryRegistry.failed
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

project.replicator.sync
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
Geo::ProjectRepositoryRegistry.failed.find_each do |registry|
   begin
     puts "ID: #{registry.id}, Project ID: #{registry.project_id}, Last Sync Failure: '#{registry.last_sync_failure}'"
     registry.replicator.sync
     puts "Sync initiated for registry ID: #{id}"
   rescue => e
     puts "ID: #{registry.id}, Project ID: #{registry.project_id}, Failed: '#{e}'", e.backtrace.join("\n")
   end
end ; nil
```

## Find repository check failures in a Geo secondary site

NOTE:
All repositories data types have been migrated to the Geo Self-Service Framework in GitLab 16.3. There is an [issue to implement this functionality back in the Geo Self-Service Framework](https://gitlab.com/gitlab-org/gitlab/-/issues/364729).

For GitLab 16.2 and earlier:

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
