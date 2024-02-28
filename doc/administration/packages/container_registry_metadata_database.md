---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Container registry metadata database

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed
**Status:** Beta

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/423459) in GitLab 16.4 as a [Beta feature](../../policy/experiment-beta-support.md) for self-managed GitLab instances.

WARNING:
The metadata database is a [beta feature](../../policy/experiment-beta-support.md#beta).
Carefully review the documentation before enabling the registry database in production!
If you encounter a problem with either the import or operation of the
registry, please add a comment in the [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/423459).

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

## Known Limitations

- No support for online migrations.
- Geo Support is not confirmed.
- Registry database migrations must be ran manually when upgrading versions.

## Metadata database feature support

You can migrate existing registries to the metadata database, and use online garbage collection.

Some database-enabled features are only enabled for GitLab.com and automatic database provisioning for
the registry database is not available. Review the feature support table in the [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/423459#supported-feature-status)
for the status of features related to the container registry database.

## Enable the metadata database for Linux package installations

Prerequisites:

- GitLab 16.7 or later.
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

Choose the one or three step method according to your registry installation.

#### One-step migration

WARNING:
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
   bucket , the configuration could be:

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

## Troubleshooting

### `there are pending database migrations` error

If the registry has been updated and there are pending schema migrations,
the registry fails to start with the following error message:

```shell
FATA[0000] configuring application: there are pending database migrations, use the 'registry database migrate' CLI command to check and apply them
```

To fix this issue, follow the steps to [apply schema migrations](#apply-schema-migrations).

### `offline garbage collection is no longer possible` error

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
