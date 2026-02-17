---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting the container registry metadata database
description: Troubleshoot problems with the container registry metadata database.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

## Error: `there are pending database migrations`

If the registry has been updated and there are pending schema migrations,
the registry fails to start with the following error message:

```shell
FATA[0000] configuring application: there are pending database migrations, use the 'registry database migrate' CLI command to check and apply them
```

To fix this issue, follow the steps to [apply database migrations](container_registry_metadata_database.md#apply-database-migrations).

Prior to version 18.3, you must manually apply database migrations on each version upgrade.

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

The registry could fail to [apply database migrations](container_registry_metadata_database.md#apply-database-migrations)
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
1. Try to [apply database migrations](container_registry_metadata_database.md#apply-database-migrations) again, if applicable.
1. Restart the registry `sudo gitlab-ctl restart registry`.

### Error: `cannot import all repositories while the tags table has entries`

If you try to [import existing registry metadata](container_registry_metadata_database.md#enable-the-database-for-existing-registries) and encounter the following error:

```shell
ERRO[0000] cannot import all repositories while the tags table has entries, you must truncate the table manually before retrying,
see https://docs.gitlab.com/administration/packages/container_registry_metadata_database/#troubleshooting
common_blobs=true dry_run=false error="tags table is not empty"
```

This error happens when there are existing entries in the `tags` table of the registry database,
which can happen if you:

- Attempted the [one step import](container_registry_metadata_database_one_step_import.md) and encountered errors.
- Attempted the [three-step import](container_registry_metadata_database_three_step_import.md) process and encountered errors.
- Stopped the import process on purpose.
- Tried to run the import again after any of the previous actions.
- Ran the import against the wrong configuration file.

To resolve this issue, you must delete the existing entries in the tags table.
You must truncate the table manually on your PostgreSQL instance:

1. Edit `/etc/gitlab/gitlab.rb` and ensure the metadata database is disabled:

   ```ruby
   registry['database'] = {
     'enabled' => false,
   }
   ```

1. Connect to your registry database using a PostgreSQL client.
1. Truncate the `tags` table to remove all existing entries:

   ```sql
   TRUNCATE TABLE tags RESTART IDENTITY CASCADE;
   ```

1. After truncating the `tags` table, try running the import process again.

### Error: `database-in-use lockfile exists`

If you try to [import existing registry metadata](container_registry_metadata_database.md#enable-the-database-for-existing-registries) and encounter the following error:

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

You might receive an `AccessDenied` error when [importing existing registries](container_registry_metadata_database.md#enable-the-database-for-existing-registries)
and using AWS S3 as your storage backend:

```shell
/opt/gitlab/embedded/bin/registry database import --step-one /var/opt/gitlab/registry/config.yml
  [0s] step one: import manifests
  [0s] step one: import manifests failed to import metadata: pre importing all repositories: AccessDenied: Access Denied
```

Ensure that the user executing the command has the
correct [permission scopes](https://docker-docs.uclv.cu/registry/storage-drivers/s3/#s3-permission-scopes).

### Registry fails to start due to metadata management issues

The registry could fail to start with one of the following errors:

#### Error: `registry filesystem metadata in use, please import data before enabling the database`

This error happens when the database is enabled in your configuration `registry['database'] = { 'enabled' => true}`
but you have not [imported existing registry metadata](container_registry_metadata_database.md#enable-the-database-for-existing-registries) to the metadata database yet.

#### Error: `registry metadata database in use, please enable the database`

This error happens when you have completed the [import of existing registry metadata](container_registry_metadata_database.md#enable-the-database-for-existing-registries) to the metadata database,
but you have not enabled the database in your configuration.

#### Problems checking or creating the lock files

If you encounter any of the following errors:

- `could not check if filesystem metadata is locked`
- `could not check if database metadata is locked`
- `failed to mark filesystem for database only usage`
- `failed to mark filesystem only usage`

The registry cannot access the configured `rootdirectory`. This error is unlikely to happen if you
had a working registry previously. Review the error logs for any misconfiguration issues.

### Storage usage not decreasing after deleting tags

By default, the online garbage collector will only start deleting unreferenced layers 48 hours from the time
that all tags they were associated with were deleted. This delay ensures that the garbage collector does
not interfere with long-running or interrupted image pushes, as layers are pushed to the registry before
they are associated with an image and tag.

### Error: `permission denied for schema public (SQLSTATE 42501)`

During a registry migration or GitLab upgrade, you might get one of the following errors:

- `ERROR: permission denied for schema public (SQLSTATE 42501)`
- `ERROR: relation "public.blobs" does not exist (SQLSTATE 42P01)`

These types of errors are due to a change in PostgreSQL 15+, which removes the default CREATE privileges on the public schema for security reasons.
By default, only database owners can create objects in the public schema in PostgreSQL 15+.

To resolve the error, run the following command to give a registry user owner privileges of the registry database:

```sql
ALTER DATABASE <registry_database_name> OWNER TO <registry_user>;
```

This gives the registry user the necessary permissions to create tables and run migrations successfully.

### Error: `database-in-use and filesystem-in-use lockfiles present`

This error occurs when both the `filesystem-in-use` and `database-in-use`
lockfiles are present on the configured registry storage and indicates
an ambiguous registry state.

To resolve this error, you must determine if your registry is meant to use the
metadata database or legacy metadata storage.

Your registry is likely meant to use the metadata database if:

- You have previously performed one of the [import processes](container_registry_metadata_database.md#how-to-choose-the-right-import-method).
- Your registry configuration indicates the registry is enabled.

Check the file at `/etc/gitlab/gitlab.rb` to see if the registry is enabled:

```ruby
registry['database'] = {
  'enabled' => true,
}
```

After you have confirmed that registry is meant to use the database, delete the
`filesystem-in-use` lockfile present in the configured registry storage
located at `/docker/registry/lockfiles/filesystem-in-use`.

Alternatively, if the above scenarios are not true, and your registry is meant
to use legacy metadata storage, delete the `database-in-use` lockfile at
`/docker/registry/lockfiles/database-in-use`.

Finally, you can disable the lockfile checks by setting the
`REGISTRY_FF_ENFORCE_LOCKFILES` container registry feature flag to `false`.
While this disables the checks, this
error is meant to ensure the integrity of your registry data and it is preferable
to confirm which metadata storage you are using. `REGISTRY_FF_ENFORCE_LOCKFILES`
is [deprecated](https://gitlab.com/gitlab-org/container-registry/-/issues/1439)
and scheduled for removal in GitLab 18.10. For more information, see
[Container registry feature flags](container_registry.md#container-registry-feature-flags).
