---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting Geo synchronization and verification errors
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

If you notice replication or verification failures in `Admin > Geo > Sites` or the [Sync status Rake task](common.md#sync-status-rake-task), you can try to resolve the failures with the following general steps:

1. Geo automatically retries failures. If the failures are new and few in number, or if you suspect the root cause is already resolved, then you can wait to see if the failures go away.
1. If failures were present for a long time, then many retries have already occurred, and the interval between automatic retries has increased to up to 4 hours depending on the type of failure. If you suspect the root cause is already resolved, you can [manually retry replication or verification](#manually-retry-replication-or-verification) to avoid the wait.
1. If the failures persist, use the following sections to try to resolve them.

## Manually retry replication or verification

A Geo data type is a specific class of data that is required by one or more GitLab features to store relevant information and is replicated by Geo to secondary sites.

### Geo data type classes

- **Blob types:**
  - `Ci::JobArtifact`
  - `Ci::PipelineArtifact`
  - `Ci::SecureFile`
  - `LfsObject`
  - `MergeRequestDiff`
  - `Packages::PackageFile`
  - `PagesDeployment`
  - `Terraform::StateVersion`
  - `Upload`
  - `DependencyProxy::Manifest`
  - `DependencyProxy::Blob`
- **Git Repository types:**
  - `DesignManagement::Repository`
  - `ProjectRepository`
  - `ProjectWikiRepository`
  - `SnippetRepository`
  - `GroupWikiRepository`
- **Other types:**
  - `ContainerRepository`

The main kinds of classes are Registry, Model, and Replicator. If you have an instance of one of these classes, you can get the others. The Registry and Model mostly manage PostgreSQL DB state. The Replicator knows how to replicate/verify (or it can call a service to do it):

```ruby
model_record = Packages::PackageFile.last
model_record.replicator.registry.replicator.model_record # just showing that these methods exist
```

With all this information, you can:

- [Manually resync and reverify individual components](#resync-and-reverify-individual-components)
- [Manually resync and reverify multiple components](#resync-and-reverify-multiple-components)

### Resync and reverify individual components

[You can force a resync and reverify individual items](https://gitlab.com/gitlab-org/gitlab/-/issues/364727)
for all component types managed by the [self-service framework](../../../../development/geo/framework.md) using the UI.
On the secondary site, visit **Admin > Geo > Replication**.

However, if this doesn't work, you can perform the same action using the Rails
console. The following sections describe how to use internal application
commands in the Rails console to cause replication or verification for
individual records synchronously or asynchronously.

### Geo registry table models

In the context of GitLab Geo, a **registry record** refers to registry tables in
the Geo tracking database. Each record tracks a single replicable in the main
GitLab database, such as an LFS file, or a project Git repository. The Rails
models that correspond to Geo registry tables that can be queried are:

- `Geo::CiSecureFileRegistry`
- `Geo::ContainerRepositoryRegistry`
- `Geo::DependencyProxyBlobRegistry`
- `Geo::DependencyProxyManifestRegistry`
- `Geo::JobArtifactRegistry`
- `Geo::LfsObjectRegistry`
- `Geo::MergeRequestDiffRegistry`
- `Geo::PackageFileRegistry`
- `Geo::PagesDeploymentRegistry`
- `Geo::PipelineArtifactRegistry`
- `Geo::ProjectWikiRepositoryRegistry`
- `Geo::SnippetRepositoryRegistry`
- `Geo::TerraformStateVersionRegistry`
- `Geo::UploadRegistry`

You can use Rails to perform basic troubleshooting. Troubleshooting steps vary
depending on the object type.

#### For blob types

WARNING:
Commands that change data can cause damage if not run correctly or under the right conditions. Always run commands in a test environment first and have a backup instance ready to restore.

[Start a Rails console session](../../../operations/rails_console.md#starting-a-rails-console-session)
on a **secondary site**.

Using the `Packages::PackageFile` component as an example:

- Find registry records that failed to sync:

  ```ruby
  Geo::PackageFileRegistry.failed
  ```

- Find registry records that are missing on the primary site:

  ```ruby
  Geo::PackageFileRegistry.where(last_sync_failure: 'The file is missing on the Geo primary site')
  ```

- Resync a package file, synchronously, given an ID:

  ```ruby
  model_record = Packages::PackageFile.find(<id>)
  model_record.replicator.sync
  ```

- Resync a package file, synchronously, given a registry ID:

  ```ruby
  registry = Geo::PackageFileRegistry.find(<registry_id>)
  registry.replicator.sync
  ```

- Resync a package file, asynchronously, given a registry ID.
  Since GitLab 16.2, a component can be asynchronously replicated as follows:

  ```ruby
  registry = Geo::PackageFileRegistry.find(<registry_id>)
  registry.replicator.enqueue_sync
  ```

- Reverify a package file, asynchronously, given a registry ID.
  Since GitLab 16.2, a component can be asynchronously reverified as follows:

  ```ruby
  registry = Geo::PackageFileRegistry.find(<registry_id>)
  registry.replicator.verify_async
  ```

#### For repository types

WARNING:
Commands that change data can cause damage if not run correctly or under the right conditions. Always run commands in a test environment first and have a backup instance ready to restore.

[Start a Rails console session](../../../operations/rails_console.md#starting-a-rails-console-session)
on a **secondary site**.

Using the `SnippetRepository` component as an example:

- Resync a snippet repository, synchronously, given an ID:

  ```ruby
  model_record = Geo::SnippetRepositoryRegistry.find(<id>)
  model_record.replicator.sync
  ```

- Resync a snippet repository, synchronously, given a registry ID:

  ```ruby
  registry = Geo::SnippetRepositoryRegistry.find(<registry_id>)
  registry.replicator.sync
  ```

- Since GitLab 16.2, a component can be asynchronously replicated. Resync a
  snippet repository, asynchronously, given a registry ID:

  ```ruby
  registry = Geo::SnippetRepositoryRegistry.find(<registry_id>)
  registry.replicator.enqueue_sync
  ```

- Since GitLab 16.2, a component can be asynchronously reverified. Reverify a
  snippet repository, asynchronously, given a registry ID:

  ```ruby
  registry = Geo::SnippetRepositoryRegistry.find(<registry_id>)
  registry.replicator.verify_async
  ```

### Resync and reverify multiple components

> - Bulk resync and reverify [added](https://gitlab.com/gitlab-org/gitlab/-/issues/364729) in GitLab 16.5.

WARNING:
Commands that change data can cause damage if not run correctly or under the right conditions. Always run commands in a test environment first and have a backup instance ready to restore.

The following sections describe how to use internal application commands in the [Rails console](../../../operations/rails_console.md#starting-a-rails-console-session)
to cause bulk replication or verification.

#### Reverify all components (or any SSF data type which supports verification)

You can reverify any [data type](#geo-data-type-classes) that supports verification from the Rails console.

For example, to reverify the `Upload` class:

1. SSH into a GitLab Rails node in the primary Geo site.
1. Open the [Rails console](../../../operations/rails_console.md#starting-a-rails-console-session).
1. Mark all uploads as `pending verification`:

   ```ruby
   Upload.verification_state_table_class.each_batch do |relation|
     relation.update_all(verification_state: 0)
   end
   ```

1. This causes the primary to start checksumming all Uploads.
1. When a primary successfully checksums a record, then all secondaries recalculate the checksum as well, and they compare the values.

For other SSF data types replace `Upload` in the command above with the desired model class.

#### Verify blob files on the secondary manually

This iterates over all package files on the secondary, looking at the
`verification_checksum` stored in the database (which came from the primary)
and then calculate this value on the secondary to check if they match. This
does not change anything in the UI.

```ruby
# Run on secondary
status = {}

Packages::PackageFile.find_each do |package_file|
  primary_checksum = package_file.verification_checksum
  secondary_checksum = Packages::PackageFile.sha256_hexdigest(package_file.file.path)
  verification_status = (primary_checksum == secondary_checksum)

  status[verification_status.to_s] ||= []
  status[verification_status.to_s] << package_file.id
end

# Count how many of each value we get
status.keys.each {|key| puts "#{key} count: #{status[key].count}"}

# See the output in its entirety
status
```

### Failed verification of Uploads on the primary Geo site

If verification of some uploads is failing on the primary Geo site with `verification_checksum = nil` and with `verification_failure` containing ``Error during verification: undefined method `underscore' for NilClass:Class`` or ``The model which owns this Upload is missing.``, this is due to orphaned Uploads. The parent record owning the Upload (the upload's "model") has somehow been deleted, but the Upload record still exists. This is usually due to a bug in the application, introduced by implementing bulk delete of the "model" while forgetting to bulk delete its associated Upload records. These verification failures are therefore not failures to verify, rather, the errors are a result of bad data in Postgres.

You can find these errors in the `geo.log` file on the primary Geo site.

To confirm that model records are missing, you can run a Rake task on the primary Geo site:

```shell
sudo gitlab-rake gitlab:uploads:check
```

You can delete these Upload records on the primary Geo site to get rid of these failures by running the following script from the [Rails console](../../../operations/rails_console.md):

```ruby
def delete_orphaned_uploads(dry_run: true)
  if dry_run
    p "This is a dry run. Upload rows will only be printed."
  else
    p "This is NOT A DRY RUN! Upload rows will be deleted from the DB!"
  end

  subquery = Geo::UploadState.where("(verification_failure LIKE 'Error during verification: The model which owns this Upload is missing.%' OR verification_failure = 'Error during verification: undefined method `underscore'' for NilClass:Class') AND verification_checksum IS NULL")
  uploads = Upload.where(upload_state: subquery)
  p "Found #{uploads.count} uploads with a model that does not exist"

  uploads_deleted = 0
  begin
    uploads.each do |upload|

      if dry_run
        p upload
      else
        uploads_deleted=uploads_deleted + 1
        p upload.destroy!
      end
    rescue => e
      puts "checking upload #{upload.id} failed with #{e.message}"
    end
  end

  p "#{uploads_deleted} remote objects were destroyed." unless dry_run
end
```

The above script defines a method named `delete_orphaned_uploads` which you can call like this to do a dry run:

```ruby
delete_orphaned_uploads(dry_run: true)
```

And to actually delete the orphaned upload rows:

```ruby
delete_orphaned_uploads(dry_run: false)
```

### Message: `"Error during verification","error":"File is not checksummable"`

If you encounter these errors in your primary site `geo.log`, they're also reflected in the UI under **Admin > Geo > Sites**. To remove those errors, you can identify the particular blob that generates the message so that you can inspect it.

1. In a Puma or Sidekiq node in the primary site, [open a Rails console](../../../operations/rails_console.md#starting-a-rails-console-session).
1. Run the following snippet to find the affected artifacts containing the `File is not checksummable` message:

NOTE:
The example provided below uses `JobArtifact` blob type; however, the same solution applies to any blob type that Geo uses.

```ruby

artifacts = Ci::JobArtifact.verification_failed.where("verification_failure like '%File is not checksummable%'");1
puts "Found #{artifacts.count} artifacts that failed verification with 'File is not checksummable'. The first one:"
pp artifacts.first
```

If you determine that the affected files need to be recovered then you can explore these options (non-exhaustive) to recover the missing files:

- Check if the secondary site has the object and manually copy them to the primary.
- Look through old backups and manually copy the object back into the primary site.
- Spot check some to try to determine that it's probably fine to destroy the records, for example, if they are all very old artifacts, then maybe they are not critical data.

Often, these kinds of errors happen when a file is checksummed by Geo, and then goes missing from the primary site. After you identify the affected files, you should check the projects that the files belong to from the UI to decide if it's acceptable to delete the file reference. If so, you can destroy the references with the following irreversible snippet:

```ruby
def destroy_artifacts_not_checksummable
  artifacts = Ci::JobArtifact.verification_failed.where("verification_failure like '%File is not checksummable%'");1
  puts "Found #{artifacts.count} artifacts that failed verification with 'File is not checksummable'."
  puts "Enter 'y' to continue: "
  prompt = STDIN.gets.chomp
  if prompt != 'y'
    puts "Exiting without action..."
    return
  end

  puts "Destroying all..."
  artifacts.destroy_all
end

destroy_artifacts_not_checksummable
```

### Error: `Error syncing repository: 13:fatal: could not read Username`

The `last_sync_failure` error
`Error syncing repository: 13:fatal: could not read Username for 'https://gitlab.example.com': terminal prompts disabled`
indicates that JWT authentication is failing during a Geo clone or fetch request.
See [Geo (development) > Authentication](../../../../development/geo.md#authentication) for more context.

First, check that system clocks are synced. Run the [Health check Rake task](common.md#health-check-rake-task), or
manually check that `date`, on all Sidekiq nodes on the secondary site and all Puma nodes on the primary site, are the
same.

If system clocks are synced, then the JWT token may be expiring while Git fetch is performing calculations between its
two separate HTTP requests. See [issue 464101](https://gitlab.com/gitlab-org/gitlab/-/issues/464101), which existed in
all GitLab versions until it was fixed in GitLab 17.1.0, 17.0.5, and 16.11.7.

To validate if you are experiencing this issue:

1. Monkey patch the code in a [Rails console](../../../operations/rails_console.md#starting-a-rails-console-session) to increase the validity period of the token from 1 minute to 10 minutes. Run
   this in Rails console on the secondary site:

   ```ruby
   module Gitlab; module Geo; class BaseRequest
     private
     def geo_auth_token(message)
       signed_data = Gitlab::Geo::SignedData.new(geo_node: requesting_node, validity_period: 10.minutes).sign_and_encode_data(message)

       "#{GITLAB_GEO_AUTH_TOKEN_TYPE} #{signed_data}"
     end
   end;end;end
   ```

1. In the same Rails console, resync an affected project:

   ```ruby
   Project.find_by_full_path('<mygroup/mysubgroup/myproject>').replicator.resync
   ```

1. Look at the sync state:

   ```ruby
   Project.find_by_full_path('<mygroup/mysubgroup/myproject>').replicator.registry
   ```

1. If `last_sync_failure` no longer includes the error `fatal: could not read Username`, then you are
   affected by this issue. The state should now be `2`, meaning "synced". If so, then you should upgrade to
   a GitLab version with the fix. You may also wish to upvote or comment on
   [issue 466681](https://gitlab.com/gitlab-org/gitlab/-/issues/466681) which would have reduced the severity of this
   issue.

To workaround the issue, you must hot-patch all Sidekiq nodes in the secondary site to extend the JWT expiration time:

1. Edit `/opt/gitlab/embedded/service/gitlab-rails/ee/lib/gitlab/geo/signed_data.rb`.
1. Find `Gitlab::Geo::SignedData.new(geo_node: requesting_node)` and add `, validity_period: 10.minutes` to it:

   ```diff
   - Gitlab::Geo::SignedData.new(geo_node: requesting_node)
   + Gitlab::Geo::SignedData.new(geo_node: requesting_node, validity_period: 10.minutes)
   ```

1. Restart Sidekiq:

   ```shell
   sudo gitlab-ctl restart sidekiq
   ```

1. Unless you upgrade to a version containing the fix, you would have to repeat this workaround after every GitLab upgrade.

### Error: `fetch remote: signal: terminated: context deadline exceeded` at exactly 3 hours

If Git fetch fails at exactly three hours while syncing a Git repository:

1. Edit `/etc/gitlab/gitlab.rb` to increase the Git timeout from the default of 10800 seconds:

   ```ruby
   # Git timeout in seconds
   gitlab_rails['gitlab_shell_git_timeout'] = 21600
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### Error `Failed to open TCP connection to localhost:5000` on secondary when configuring registry replication

You may face the following error when configuring container registry replication on the secondary site:

```plaintext
Failed to open TCP connection to localhost:5000 (Connection refused - connect(2) for \"localhost\" port 5000)"
```

It happens if the container registry is not enabled on the secondary site. To fix it, check that the container registry
is [enabled on the secondary site](../../../packages/container_registry.md#enable-the-container-registry). Note that if [Let’s Encrypt integration is disabled](https://docs.gitlab.com/omnibus/settings/ssl/#configure-https-manually), container registry is disabled as well, and you must [configure it manually](../../../packages/container_registry.md#configure-container-registry-under-its-own-domain).

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
There is an [issue to implement this functionality in the **Admin** area UI](https://gitlab.com/gitlab-org/gitlab/-/issues/364729).

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

During a [backfill](../../_index.md#backfill), failures are scheduled to be retried at the end
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

### Resync all Geo-replicable objects

You can schedule a full resync or reverification of all Geo-replicable objects
from the UI:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Geo > Sites**.
1. Under **Replication details**, select the desired object.
1. Select **Resync all** or **Reverify all**.

Alternatively, [start a Rails console session](../../../operations/rails_console.md#starting-a-rails-console-session)
**on the secondary Geo site** to gather more information, or execute these operations manually using the snippets below.

WARNING:
Commands that change data can cause damage if not run correctly or under the right conditions. Always run commands in a test environment first and have a backup instance ready to restore.

### Find repository verification failures

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

#### Mark all repositories for reverification

The following snippet marks all project repositories for reverification. After a minute or two, the system should begin to schedule Sidekiq jobs according to your concurrency limits:

```ruby
Geo::ProjectRepositoryRegistry.update_all(verification_state: 0)
```

If there's a very large number of repositories to reverify, the single update query can time out. If this happens, you should run update queries in batches of rows using the same code as the **Reverify all** feature in the admin area:

```ruby
::Geo::RegistryBulkUpdateService.new(:reverify_all, Geo::ProjectRepositoryRegistry).execute
```

### Resync project and project wiki repositories

#### Queue up all repositories for resync

The following snippet marks all project repositories for reverification. After a minute or two, the system should begin to schedule Sidekiq jobs according to your concurrency limits:

```ruby
Geo::ProjectRepositoryRegistry.update_all(state: 0, last_synced_at: nil)
```

If there's a very large number of repositories to reverify, the single update query can time out. If this happens, you should run update queries in batches of rows using the same code as the **Reverify all** feature in the admin area:

```ruby
::Geo::RegistryBulkUpdateService.new(:resync_all, Geo::ProjectRepositoryRegistry).execute
```

#### Sync all failed repositories now

The following script:

- Loops over all failed repositories.
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
     puts "Sync initiated for registry ID: #{registry.id}"
   rescue => e
     puts "ID: #{registry.id}, Project ID: #{registry.project_id}, Failed: '#{e}'", e.backtrace.join("\n")
   end
end ; nil
```

## Find repository check failures in a Geo secondary site

NOTE:
All repositories data types have been migrated to the Geo Self-Service Framework in GitLab 16.3. There is an [issue to implement this functionality back in the Geo Self-Service Framework](https://gitlab.com/gitlab-org/gitlab/-/issues/426659).

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

## Resetting Geo **secondary** site replication

If you get a **secondary** site in a broken state and want to reset the replication state,
to start again from scratch, there are a few steps that can help you:

1. Stop Sidekiq and the Geo Log Cursor.

   It's possible to make Sidekiq stop gracefully, but making it stop getting new jobs and
   wait until the current jobs to finish processing.

   You need to send a **SIGTSTP** kill signal for the first phase and them a **SIGTERM**
   when all jobs have finished. Otherwise just use the `gitlab-ctl stop` commands.

   ```shell
   gitlab-ctl status sidekiq
   # run: sidekiq: (pid 10180) <- this is the PID you will use
   kill -TSTP 10180 # change to the correct PID

   gitlab-ctl stop sidekiq
   gitlab-ctl stop geo-logcursor
   ```

   You can watch the [Sidekiq logs](../../../logs/_index.md#sidekiq-logs) to know when Sidekiq jobs processing has finished:

   ```shell
   gitlab-ctl tail sidekiq
   ```

1. Clear Gitaly/Gitaly Cluster data.

   ::Tabs

   :::TabTitle Gitaly

   ```shell
   mv /var/opt/gitlab/git-data/repositories /var/opt/gitlab/git-data/repositories.old
   sudo gitlab-ctl reconfigure
   ```

   :::TabTitle Gitaly Cluster

   1. Optional. Disable the Praefect internal load balancer.
   1. Stop Praefect on each Praefect server:

      ```shell
      sudo gitlab-ctl stop praefect
      ```

   1. Reset the Praefect database:

      ```shell
      sudo /opt/gitlab/embedded/bin/psql -U praefect -d template1 -h localhost -c "DROP DATABASE praefect_production WITH (FORCE);"
      sudo /opt/gitlab/embedded/bin/psql -U praefect -d template1 -h localhost -c "CREATE DATABASE praefect_production WITH OWNER=praefect ENCODING=UTF8;"
      ```

   1. Rename/delete repository data from each Gitaly node:

      ```shell
      sudo mv /var/opt/gitlab/git-data/repositories /var/opt/gitlab/git-data/repositories.old
      sudo gitlab-ctl reconfigure
      ```

   1. On your Praefect deploy node run reconfigure to set up the database:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

   1. Start Praefect on each Praefect server:

      ```shell
      sudo gitlab-ctl start praefect
      ```

   1. Optional. If you disabled it, reactivate the Praefect internal load balancer.

   ::EndTabs

   NOTE:
   You may want to remove the `/var/opt/gitlab/git-data/repositories.old` in the future
   as soon as you confirmed that you don't need it anymore, to save disk space.

1. Optional. Rename other data folders and create new ones.

   WARNING:
   You may still have files on the **secondary** site that have been removed from the **primary** site, but this
   removal has not been reflected. If you skip this step, these files are not removed from the Geo **secondary** site.

   Any uploaded content (like file attachments, avatars, or LFS objects) is stored in a
   subfolder in one of these paths:

   - `/var/opt/gitlab/gitlab-rails/shared`
   - `/var/opt/gitlab/gitlab-rails/uploads`

   To rename all of them:

   ```shell
   gitlab-ctl stop

   mv /var/opt/gitlab/gitlab-rails/shared /var/opt/gitlab/gitlab-rails/shared.old
   mkdir -p /var/opt/gitlab/gitlab-rails/shared

   mv /var/opt/gitlab/gitlab-rails/uploads /var/opt/gitlab/gitlab-rails/uploads.old
   mkdir -p /var/opt/gitlab/gitlab-rails/uploads

   gitlab-ctl start postgresql
   gitlab-ctl start geo-postgresql
   ```

   Reconfigure to recreate the folders and make sure permissions and ownership
   are correct:

   ```shell
   gitlab-ctl reconfigure
   ```

1. Reset the Tracking Database.

   WARNING:
   If you skipped the optional step 3, be sure both `geo-postgresql` and `postgresql` services are running.

   ```shell
   gitlab-rake db:drop:geo DISABLE_DATABASE_ENVIRONMENT_CHECK=1   # on a secondary app node
   gitlab-ctl reconfigure     # on the tracking database node
   gitlab-rake db:migrate:geo # on a secondary app node
   ```

1. Restart previously stopped services.

   ```shell
   gitlab-ctl start
   ```
