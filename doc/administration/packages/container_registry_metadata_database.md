---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Container registry metadata database
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/423459) in GitLab 16.4 as a [beta feature](../../policy/development_stages_support.md) for GitLab Self-Managed.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/423459) in GitLab 17.3.

The metadata database enables many new registry features, including
online garbage collection, and increases the efficiency of many registry operations.
The work on the self-managed release of the registry metadata database feature
is tracked in [epic 5521](https://gitlab.com/groups/gitlab-org/-/epics/5521).

By default, the container registry uses object storage to persist metadata
related to container images. This method to store metadata limits how efficiently
the data can be accessed, especially data spanning multiple images, such as when listing tags.
By using a database to store this data, many new features are possible, including
[online garbage collection](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/spec/gitlab/online-garbage-collection.md)
which removes old data automatically with zero downtime.

This database works in conjunction with the object storage already used by the registry, but does not replace object storage.
You must continue to maintain an object storage solution even after migrating to a metadata database.

For Helm Charts installations, see [Manage the container registry metadata database](https://docs.gitlab.com/charts/charts/registry/metadata_database.html#create-the-database)
in the Helm Charts documentation.

## Known Limitations

- No support for online migrations.
- Geo Support is not confirmed.
- Registry database migrations must be run manually when upgrading versions.
- No guarantee for registry [zero downtime during upgrades](../../update/zero_downtime.md) on multi-node Omnibus GitLab environments.

## Metadata database feature support

You can migrate existing registries to the metadata database, and use online garbage collection.

Some database-enabled features are only enabled for GitLab.com and automatic database provisioning for
the registry database is not available. Review the feature support table in the [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/423459#supported-feature-status)
for the status of features related to the container registry database.

## Enable the metadata database for Linux package installations

Prerequisites:

- GitLab 17.3 or later.
- PostgreSQL database version 12 or later. It must be accessible from the registry node.

Follow the instructions that match your situation:

- [New installation](#new-installations) or enabling the container registry for the first time.
- Migrate existing container images to the metadata database:
  - [One-step migration](#one-step-migration). Only recommended for relatively small registries or no requirement to avoid downtime.
  - [Three-step migration](#three-step-migration). Recommended for larger container registries.

### Before you start

- After you enable the database, you must continue to use it. The database is
  now the source of the registry metadata, disabling it after this point
  causes the registry to lose visibility on all images written to it while
  the database was active.
- Never run [offline garbage collection](container_registry.md#container-registry-garbage-collection) at any point
  after the import step has been completed. That command is not compatible with registries using
  the metadata database, and it deletes data.
- Verify you have not automated offline garbage collection.
- You can first [reduce the storage of your registry](../../user/packages/container_registry/reduce_container_registry_storage.md)
  to speed up the process.
- Back up [your container registry data](../backup_restore/backup_gitlab.md#container-registry)
  if possible.

### New installations

To enable the database:

1. Edit `/etc/gitlab/gitlab.rb` by adding your database connection details, but start with the metadata database **disabled**:

   ```ruby
   registry['database'] = {
     'enabled' => false,
     'host' => 'localhost',
     'port' => 5432,
     'user' => 'registry-database-user',
     'password' => 'registry-database-password',
     'dbname' => 'registry-database-name',
     'sslmode' => 'require', # See the PostgreSQL documentation for additional information https://www.postgresql.org/docs/current/libpq-ssl.html.
     'sslcert' => '/path/to/cert.pem',
     'sslkey' => '/path/to/private.key',
     'sslrootcert' => '/path/to/ca.pem'
   }
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).
1. [Apply schema migrations](#apply-schema-migrations).
1. Enable the database by editing `/etc/gitlab/gitlab.rb` and setting `enabled` to `true`:

   ```ruby
   registry['database'] = {
     'enabled' => true,
     'host' => 'localhost',
     'port' => 5432,
     'user' => 'registry-database-user',
     'password' => 'registry-database-password',
     'dbname' => 'registry-database-name',
     'sslmode' => 'require', # See the PostgreSQL documentation for additional information https://www.postgresql.org/docs/current/libpq-ssl.html.
     'sslcert' => '/path/to/cert.pem',
     'sslkey' => '/path/to/private.key',
     'sslrootcert' => '/path/to/ca.pem'
   }
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).

### Existing registries

You can migrate your existing container registry data in one step or three steps.
A few factors affect the duration of the migration:

- The size of your existing registry data.
- The specifications of your PostgresSQL instance.
- The number of registry instances running.
- Network latency between the registry, PostgresSQL and your configured Object Storage.

NOTE:
The migration only targets tagged images. Untagged and unreferenced manifests, and the layers
exclusively referenced by them, are left behind and become inaccessible. Untagged images
were never visible through the GitLab UI or API, but they can become "dangling" and
left behind in the backend. After migration to the new registry, all images are subject
to continuous online garbage collection, by default deleting any untagged and unreferenced manifests
and layers that remain for longer than 24 hours.

Choose the one or three step method according to your registry installation.

#### One-step migration

WARNING:
The registry must be shut down or remain in `read-only` mode during the migration.
Only choose this method if you do not need to write to the registry during the migration
and your registry contains a relatively small amount of data.

1. Add the `database` section to your `/etc/gitlab/gitlab.rb` file, but start with the metadata database **disabled**:

   ```ruby
   registry['database'] = {
     'enabled' => false, # Must be false!
     'host' => 'localhost',
     'port' => 5432,
     'user' => 'registry-database-user',
     'password' => 'registry-database-password',
     'dbname' => 'registry-database-name'
     'sslmode' => 'require', # See the PostgreSQL documentation for additional information https://www.postgresql.org/docs/current/libpq-ssl.html.
     'sslcert' => '/path/to/cert.pem',
     'sslkey' => '/path/to/private.key',
     'sslrootcert' => '/path/to/ca.pem'
   }
   ```

1. Ensure the registry is set to `read-only` mode.

   Edit your `/etc/gitlab/gitlab.rb` and add the `maintenance` section to the `registry['storage']` configuration.
   For example, for a `gcs` backed registry using a `gs://my-company-container-registry` bucket,
   the configuration could be:

   ```ruby
   ## Object Storage - Container Registry
   registry['storage'] = {
     'gcs' => {
       'bucket' => "my-company-container-registry",
       'chunksize' => 5242880
     },
     'maintenance' => {
       'readonly' => {
         'enabled' => true # Must be set to true.
       }
     }
   }
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).
1. [Apply schema migrations](#apply-schema-migrations) if you have not done so.
1. Run the following command:

   ```shell
   sudo gitlab-ctl registry-database import
   ```

1. If the command completed successfully, the registry is now fully imported. You
   can now enable the database, turn off read-only mode in the configuration, and
   start the registry service:

   ```ruby
   registry['database'] = {
     'enabled' => true, # Must be enabled now!
     'host' => 'localhost',
     'port' => 5432,
     'user' => 'registry-database-user',
     'password' => 'registry-database-password',
     'dbname' => 'registry-database-name',
     'sslmode' => 'require', # See the PostgreSQL documentation for additional information https://www.postgresql.org/docs/current/libpq-ssl.html.
     'sslcert' => '/path/to/cert.pem',
     'sslkey' => '/path/to/private.key',
     'sslrootcert' => '/path/to/ca.pem'
   }

   ## Object Storage - Container Registry
   registry['storage'] = {
     'gcs' => {
       'bucket' => "my-company-container-registry",
       'chunksize' => 5242880
     },
     'maintenance' => {
       'readonly' => {
         'enabled' => false
       }
     }
   }
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).

You can now use the metadata database for all operations!

#### Three-step migration

Follow this guide to migrate your existing container registry data.
This procedure is recommended for larger sets of data or if you are
trying to minimize downtime while completing the migration.

NOTE:
Users have reported step one import completed at [rates of 2 to 4 TB per hour](https://gitlab.com/gitlab-org/gitlab/-/issues/423459).
At the slower speed, registries with over 100TB of data could take longer than 48 hours.

##### Pre-import repositories (step one)

For larger instances, this command can take hours to days to complete, depending
on the size of your registry. You may continue to use the registry as normal while
step one is being completed.

WARNING:
It is [not yet possible](https://gitlab.com/gitlab-org/container-registry/-/issues/1162)
to restart the migration, so it's important to let the migration run to completion.
If you must halt the operation, you have to restart this step.

1. Add the `database` section to your `/etc/gitlab/gitlab.rb` file, but start with the metadata database **disabled**:

   ```ruby
   registry['database'] = {
     'enabled' => false, # Must be false!
     'host' => 'localhost',
     'port' => 5432,
     'user' => 'registry-database-user',
     'password' => 'registry-database-password',
     'dbname' => 'registry-database-name'
     'sslmode' => 'require', # See the PostgreSQL documentation for additional information https://www.postgresql.org/docs/current/libpq-ssl.html.
     'sslcert' => '/path/to/cert.pem',
     'sslkey' => '/path/to/private.key',
     'sslrootcert' => '/path/to/ca.pem'
   }
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).
1. [Apply schema migrations](#apply-schema-migrations) if you have not done so.
1. Run the first step to begin the migration:

   ```shell
   sudo gitlab-ctl registry-database import --step-one
   ```

NOTE:
You should try to schedule the following step as soon as possible
to reduce the amount of downtime required. Ideally, less than one week
after step one completes. Any new data written to the registry between steps one and two,
causes step two to take more time.

##### Import all repository data (step two)

This step requires the registry to be shut down or set in `read-only` mode.
Allow enough time for downtime while step two is being executed.

1. Ensure the registry is set to `read-only` mode.

   Edit your `/etc/gitlab/gitlab.rb` and add the `maintenance` section to the `registry['storage']`
   configuration. For example, for a `gcs` backed registry using a `gs://my-company-container-registry`
   bucket, the configuration could be:

   ```ruby
   ## Object Storage - Container Registry
   registry['storage'] = {
     'gcs' => {
       'bucket' => "my-company-container-registry",
       'chunksize' => 5242880
     },
     'maintenance' => {
       'readonly' => {
         'enabled' => true # Must be set to true.
       }
     }
   }
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).
1. Run step two of the migration

   ```shell
   sudo gitlab-ctl registry-database import --step-two
   ```

1. If the command completed successfully, all images are now fully imported. You
   can now enable the database, turn off read-only mode in the configuration, and
   start the registry service:

   ```ruby
   registry['database'] = {
     'enabled' => true, # Must be set to true!
     'host' => 'localhost',
     'port' => 5432,
     'user' => 'registry-database-user',
     'password' => 'registry-database-password',
     'dbname' => 'registry-database-name',
     'sslmode' => 'require', # See the PostgreSQL documentation for additional information https://www.postgresql.org/docs/current/libpq-ssl.html.
     'sslcert' => '/path/to/cert.pem',
     'sslkey' => '/path/to/private.key',
     'sslrootcert' => '/path/to/ca.pem'
   }

   ## Object Storage - Container Registry
   registry['storage'] = {
     'gcs' => {
       'bucket' => "my-company-container-registry",
       'chunksize' => 5242880
     },
     'maintenance' => { # This section can be removed.
       'readonly' => {
         'enabled' => false
       }
     }
   }
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).

You can now use the metadata database for all operations!

##### Import the rest of the data (step three)

Even though the registry is now fully using the database for its metadata, it
does not yet have access to any potentially unused layer blobs.

To complete the process, run the final step of the migration:

```shell
sudo gitlab-ctl registry-database import --step-three
```

After that command exists successfully, the registry is now fully migrated to the database!

#### Post Migration

It may take approximately 48 hours post migration to see your registry storage
decrease. This is a normal and expected part of online garbage collection, as this
delay ensures that online garbage collection does not interfere with image pushes.
Check out the [monitor online garbage collection](#online-garbage-collection-monitoring) section
to see how to monitor the progress and health of the online garbage collector.

## Manage schema migrations

Use the following commands to run the schema migrations for the Container registry metadata database.
The registry must be enabled and the configuration section must have the database section filled.

### Apply schema migrations

1. Run the registry database schema migrations

   ```shell
   sudo gitlab-ctl registry-database migrate up
   ```

1. The registry must stop if it's running. Type `y` to confirm and wait for the process to finish.

NOTE:
The `migrate up` command offers some extra flags that can be used to control how the migrations are applied.
Run `sudo gitlab-ctl registry-database migrate up --help` for details.

### Undo schema migrations

You can undo schema migrations in case anything goes wrong, but this is a non-recoverable action.
If you pushed new images while the database was in use, they will no longer be accessible
after this.

1. Undo the registry database schema migrations:

   ```shell
   sudo gitlab-ctl registry-database migrate down
   ```

NOTE:
The `migrate down` command offers some extra flags. Run `sudo gitlab-ctl registry-database migrate down --help` for details.

## Online garbage collection monitoring

The initial runs of online garbage collection following the import process varies
in duration based on the number of imported images. You should monitor the efficiency and
health of your online garbage collection during this period.

### Monitor database performance

After completing an import, expect the database to experience a period of high load as
the garbage collection queues drain. This high load is caused by a high number of individual database calls
from the online garbage collector processing the queued tasks.

Regularly check PostgreSQL and registry logs for any errors or warnings. In the registry logs,
pay special attention to logs filtered by `component=registry.gc.*`.

### Track metrics

Use monitoring tools like Prometheus and Grafana to visualize and track garbage collection metrics,
focusing on metrics with a prefix of `registry_gc_*`. These include the number of objects
marked for deletion, objects successfully deleted, run intervals, and durations.
See [enable the registry debug server](container_registry_troubleshooting.md#enable-the-registry-debug-server)
for how to enable Prometheus.

### Queue monitoring

Check the size of the queues by counting the rows in the `gc_blob_review_queue` and
`gc_manifest_review_queue` tables. Large queues are expected initially, with the number of rows
proportional to the number of imported blobs and manifests. The queues should reduce over time,
indicating that garbage collection is successfully reviewing jobs.

```sql
SELECT COUNT(*) FROM gc_blob_review_queue;
SELECT COUNT(*) FROM gc_manifest_review_queue;
```

Interpreting Queue Sizes:

- Shrinking queues: Indicate garbage collection is successfully processing tasks.
- Near-Zero `gc_manifest_review_queue`: Most images flagged for potential deletion
  have been reviewed and classified either as still in use or removed.
- Overdue Tasks: Check for overdue GC tasks by running the following queries:

  ```sql
  SELECT COUNT(*) FROM gc_blob_review_queue WHERE review_after < NOW();
  SELECT COUNT(*) FROM gc_manifest_review_queue WHERE review_after < NOW();
  ```

  A high number of overdue tasks indicates a problem. Large queue sizes are not concerning
  as long as they are decreasing over time and the number of overdue tasks
  is close to zero. A high number of overdue tasks should prompt an urgent inspection of logs.

Check GC logs for messages indicating that blobs are still in use, for example `msg=the blob is not dangling`,
which implies they will not be deleted.

### Adjust blobs interval

If the size of your `gc_blob_review_queue` is high, and you want to increase the frequency between
the garbage collection blob or manifest worker runs, update your interval configuration
from the default (`5s`) to `1s`:

```ruby
registry['gc'] = {
  'blobs' => {
    'interval' => '1s'
  },
  'manifests' => {
    'interval' => '1s'
  }
}
```

After the migration load has been cleared, you should fine-tune these settings for the long term
to avoid unnecessary CPU load on the database and registry instances. You can gradually increase
the interval to a value that balances performance and resource usage.

### Validate data consistency

To ensure data consistency after the import, use the [`crane validate`](https://github.com/google/go-containerregistry/blob/main/cmd/crane/doc/crane_validate.md)
tool. This tool checks that all image layers and manifests in your container registry
are accessible and correctly linked. By running `crane validate`, you confirm that
the images in your registry are complete and accessible, ensuring a successful import.

### Review cleanup policies

If most of your images are tagged, garbage collection won't significantly reduce storage space
because it only deletes untagged images.

Implement cleanup policies to remove unneeded tags, which eventually causes images
to be removed through garbage collection and storage space being recovered.

## Backup with metadata database

When the metadata database is enabled, backups must capture both the object storage
used by the registry, as before, but also the database. Backups of object storage
and the database should be coordinated to capture the state of the registry as close as possible
to each other. To restore the registry, you must apply both backups together.

## Downgrade a registry

To downgrade the registry to a previous version after the migration is complete,
you must restore to a backup of the desired version in order to downgrade.

## Troubleshooting

### Error: `there are pending database migrations`

If the registry has been updated and there are pending schema migrations,
the registry fails to start with the following error message:

```shell
FATA[0000] configuring application: there are pending database migrations, use the 'registry database migrate' CLI command to check and apply them
```

To fix this issue, follow the steps to [apply schema migrations](#apply-schema-migrations).

### Error: `offline garbage collection is no longer possible`

If the registry uses the metadata database and you try to run
[offline garbage collection](container_registry.md#container-registry-garbage-collection),
the registry fails with the following error message:

```shell
ERRO[0000] this filesystem is managed by the metadata database, and offline garbage collection is no longer possible, if you are not using the database anymore, remove the file at the lock_path in this log message lock_path=/docker/registry/lockfiles/database-in-use
```

You must either:

- Stop using offline garbage collection.
- If you no longer use the metadata database, delete the indicated lock file at the `lock_path` shown in the error message.
  For example, remove the `/docker/registry/lockfiles/database-in-use` file.

### Error: `cannot execute <STATEMENT> in a read-only transaction`

The registry could fail to [apply schema migrations](#apply-schema-migrations)
with the following error message:

```shell
err="ERROR: cannot execute CREATE TABLE in a read-only transaction (SQLSTATE 25006)"
```

Also, the registry could fail with the following error message if you try to run
[online garbage collection](container_registry.md#performing-garbage-collection-without-downtime):

```shell
error="processing task: fetching next GC blob task: scanning GC blob task: ERROR: cannot execute SELECT FOR UPDATE in a read-only transaction (SQLSTATE 25006)"
```

You must verify that read-only transactions are disabled by checking the values of
`default_transaction_read_only` and `transaction_read_only` in the PostgreSQL console.
For example:

```sql
# SHOW default_transaction_read_only;
 default_transaction_read_only
 -------------------------------
 on
(1 row)

# SHOW transaction_read_only;
 transaction_read_only
 -----------------------
 on
(1 row)
```

If either of these values is set to `on`, you must disable it:

1. Edit your `postgresql.conf` and set the following value:

   ```shell
   default_transaction_read_only=off
   ```

1. Restart your Postgres server to apply these settings.
1. Try to [apply schema migrations](#apply-schema-migrations) again, if applicable.
1. Restart the registry `sudo gitlab-ctl restart registry`.

### Error: `cannot import all repositories while the tags table has entries`

If you try to [migrate existing registries](#existing-registries) and encounter the following error:

```shell
ERRO[0000] cannot import all repositories while the tags table has entries, you must truncate the table manually before retrying,
see https://docs.gitlab.com/ee/administration/packages/container_registry_metadata_database.html#troubleshooting
common_blobs=true dry_run=false error="tags table is not empty"
```

This error happens when there are existing entries in the `tags` table of the registry database,
which can happen if you:

- Attempted the [one step migration](#one-step-migration) and encountered errors.
- Attempted the [three-step migration](#three-step-migration) process and encountered errors.
- Stopped the migration process on purpose.
- Tried to run the migration again after any of the above.
- Ran the migration against the wrong configuration file.

To resolve this issue, you must delete the existing entries in the tags table.
You must truncate the table manually on your PostgreSQL instance:

1. Edit `/etc/gitlab/gitlab.rb` and ensure the metadata database is **disabled**:

   ```ruby
   registry['database'] = {
     'enabled' => false,
     'host' => 'localhost',
     'port' => 5432,
     'user' => 'registry-database-user',
     'password' => 'registry-database-password',
     'dbname' => 'registry-database-name',
     'sslmode' => 'require', # See the PostgreSQL documentation for additional information https://www.postgresql.org/docs/current/libpq-ssl.html.
     'sslcert' => '/path/to/cert.pem',
     'sslkey' => '/path/to/private.key',
     'sslrootcert' => '/path/to/ca.pem'
   }
   ```

1. Connect to your registry database using a PostgreSQL client.
1. Truncate the `tags` table to remove all existing entries:

   ```sql
   TRUNCATE TABLE tags RESTART IDENTITY CASCADE;
   ```

1. After truncating the `tags` table, try running the migration process again.

### Error: `database-in-use lockfile exists`

If you try to [migrate existing registries](#existing-registries) and encounter the following error:

```shell
|  [0s] step two: import tags failed to import metadata: importing all repositories: 1 error occurred:
    * could not restore lockfiles: database-in-use lockfile exists
```

This error means that you have previously imported the registry and completed importing all
repository data (step two) and the `database-in-use` exists in the registry file system.
You should not run the importer again if you encounter this issue.

If you must proceed, you must delete the `database-in-use` lock file manually from the file system.
The file is located at `/path/to/rootdirectory/docker/registry/lockfiles/database-in-use`.

### Error: `pre importing all repositories: AccessDenied:`

You might receive an `AccessDenied` error when [importing existing registries](#existing-registries)
and using AWS S3 as your storage backend:

```shell
/opt/gitlab/embedded/bin/registry database import --step-one /var/opt/gitlab/registry/config.yml
  [0s] step one: import manifests
  [0s] step one: import manifests failed to import metadata: pre importing all repositories: AccessDenied: Access Denied
```

Ensure that the user executing the command has the
correct [permission scopes](https://docker-docs.uclv.cu/registry/storage-drivers/s3/#s3-permission-scopes).

### Registry fails to start due to metadata management issues

The registry could fail to start with of the following errors:

#### Error: `registry filesystem metadata in use, please import data before enabling the database`

This error happens when the database is enabled in your configuration `registry['database'] = { 'enabled' => true}`
but you have not [migrated existing data](#existing-registries) to the metadata database yet.

#### Error: `registry metadata database in use, please enable the database`

This error happens when you have completed [migrating existing data](#existing-registries) to the metadata database,
but you have not enabled the database in your configuration.

#### Problems checking or creating the lock files

If you encounter any of the following errors:

- `could not check if filesystem metadata is locked`
- `could not check if database metadata is locked`
- `failed to mark filesystem for database only usage`
- `failed to mark filesystem only usage`

The registry cannot access the configured `rootdirectory`. This error is unlikely to happen if you
had a working registry previously. Review the error logs for any misconfiguration issues.
