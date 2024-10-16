---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Troubleshooting Geo replication

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** Self-managed

If you notice replication failures in `Admin > Geo > Sites` or the [Sync status Rake task](common.md#sync-status-rake-task), you can try to resolve the failures with the following general steps:

1. Geo automatically retries failures. If the failures are new and few in number, or if you suspect the root cause is already resolved, then you can wait to see if the failures go away.
1. If failures were present for a long time, then many retries have already occurred, and the interval between automatic retries has increased to up to 4 hours depending on the type of failure. If you suspect the root cause is already resolved, you can [manually retry replication or verification](#manually-retry-replication-or-verification).
1. If the failures persist, use the following sections to try to resolve them.

## Manually retry replication or verification

A Geo data type is a specific class of data that is required by one or more GitLab features to store relevant information and is replicated by Geo to secondary sites.

The following Geo data types exist:

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

WARNING:
Commands that change data can cause damage if not run correctly or under the right conditions. Always run commands in a test environment first and have a backup instance ready to restore.

[Start a Rails console session](../../../../administration/operations/rails_console.md#starting-a-rails-console-session)
to enact the following, basic troubleshooting steps:

#### For blob types

Using the `Packages::PackageFile` component as an example:

- Find registry records that failed to sync:

  ```ruby
  Geo::PackageFileRegistry.failed
  ```

  The term registry records, in this case, refers to registry tables in the
  Geo tracking database. Each record, or row, tracks a single replicable in the
  main GitLab database, such as an LFS file, or a project Git repository. Here
  are some other Rails models that correspond to Geo registry tables that can
  be queried like the above:

  ```plaintext
  CiSecureFileRegistry
  ContainerRepositoryRegistry
  DependencyProxyBlobRegistry
  DependencyProxyManifestRegistry
  JobArtifactRegistry
  LfsObjectRegistry
  MergeRequestDiffRegistry
  PackageFileRegistry
  PagesDeploymentRegistry
  PipelineArtifactRegistry
  ProjectWikiRepositoryRegistry
  SnippetRepositoryRegistry
  TerraformStateVersionRegistry
  UploadRegistry
  ```

- Find registry records that are missing on the primary site:

  ```ruby
  Geo::PackageFileRegistry.where(last_sync_failure: 'The file is missing on the Geo primary site')
  ```

- Resync a package file, synchronously, given an ID:

  ```ruby
  model_record = Packages::PackageFile.find(id)
  model_record.replicator.sync
  ```

- Resync a package file, synchronously, given a registry ID:

  ```ruby
  registry = Geo::PackageFileRegistry.find(registry_id)
  registry.replicator.sync
  ```

- Resync a package file, asynchronously, given a registry ID.
  Since GitLab 16.2, a component can be asynchronously replicated as follows:

  ```ruby
  registry = Geo::PackageFileRegistry.find(registry_id)
  registry.replicator.enqueue_sync
  ```

- Reverify a package file, asynchronously, given a registry ID.
  Since GitLab 16.2, a component can be asynchronously reverified as follows:

  ```ruby
  registry = Geo::PackageFileRegistry.find(registry_id)
  registry.replicator.verify_async
  ```

#### For repository types

Using the `SnippetRepository` component as an example:

- Resync a snippet repository, synchronously, given an ID:

  ```ruby
  model_record = Geo::SnippetRepositoryRegistry.find(id)
  model_record.replicator.sync
  ```

- Resync a snippet repository, synchronously, given a registry ID

  ```ruby
  registry = Geo::SnippetRepositoryRegistry.find(registry_id)
  registry.replicator.sync
  ```

- Resync a snippet repository, asynchronously, given a registry ID.
  Since GitLab 16.2, a component can be asynchronously replicated as follows:

  ```ruby
  registry = Geo::SnippetRepositoryRegistry.find(registry_id)
  registry.replicator.enqueue_sync
  ```

- Reverify a snippet repository, asynchronously, given a registry ID.
  Since GitLab 16.2, a component can be asynchronously reverified as follows:

  ```ruby
  registry = Geo::SnippetRepositoryRegistry.find(registry_id)
  registry.replicator.verify_async
  ```

### Resync and reverify multiple components

NOTE:
There is an [issue to implement this functionality in the **Admin** area UI](https://gitlab.com/gitlab-org/gitlab/-/issues/364729).

WARNING:
Commands that change data can cause damage if not run correctly or under the right conditions. Always run commands in a test environment first and have a backup instance ready to restore.

The following sections describe how to use internal application commands in the [Rails console](../../../../administration/operations/rails_console.md#starting-a-rails-console-session)
to cause bulk replication or verification.

#### Reverify all components (or any SSF data type which supports verification)

For GitLab 16.4 and earlier:

1. SSH into a GitLab Rails node in the primary Geo site.
1. Open the [Rails console](../../../../administration/operations/rails_console.md#starting-a-rails-console-session).
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

If verification of some uploads is failing on the primary Geo site with `verification_checksum = nil` and with the ``verification_failure = Error during verification: undefined method `underscore' for NilClass:Class``, this can be due to orphaned Uploads. The parent record owning the Upload (the upload's model) has somehow been deleted, but the Upload record still exists. These verification failures are false.

You can find these errors in the `geo.log` file on the primary Geo site.

To confirm that model records are missing, you can run a Rake task on the primary Geo site:

```shell
sudo gitlab-rake gitlab:uploads:check
```

You can delete these Upload records on the primary Geo site to get rid of these failures by running the following script from the [Rails console](../../../operations/rails_console.md):

```ruby
# Look for uploads with the verification error
# or edit with your own affected IDs
uploads = Geo::UploadState.where(
  verification_checksum: nil,
  verification_state: 3,
  verification_failure: "Error during verification: undefined method  `underscore' for NilClass:Class"
).pluck(:upload_id)

uploads_deleted = 0
begin
    uploads.each do |upload|
    u = Upload.find upload
    rescue => e
        puts "checking upload #{u.id} failed with #{e.message}"
      else
        uploads_deleted=uploads_deleted + 1
        p u                            ### allow verification before destroy
        # p u.destroy!                 ### uncomment to actually destroy
  end
end
p "#{uploads_deleted} remote objects were destroyed."
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
   Project.find_by_full_path('mygroup/mysubgroup/myproject').replicator.resync
   ```

1. Look at the sync state:

   ```ruby
   Project.find_by_full_path('mygroup/mysubgroup/myproject').replicator.registry
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

   You can watch the [Sidekiq logs](../../../logs/index.md#sidekiq-logs) to know when Sidekiq jobs processing has finished:

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
