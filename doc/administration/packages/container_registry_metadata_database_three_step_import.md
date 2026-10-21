---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Three-step import
description: Enable the container registry metadata database with minimal downtime.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

Import your existing container registry metadata.
The following procedure is recommended for larger registries (200 GiB or more), or if you want to
minimize downtime while completing the import.

## Pre-import repositories (step one)

The duration of step one depends mostly on the number of tagged images in your registry,
not on the total size of the registry data. In [user reports](https://gitlab.com/gitlab-org/gitlab/-/work_items/423459#completed-tests-and-user-reports),
step one ran at rates from under 1 TB per hour to over 4 TB per hour.
Plan with the lower end of this range, and treat any estimate as a lower bound.
For example durations, see
[Plan an import for a large registry](container_registry_metadata_database.md#plan-an-import-for-a-large-registry).

You may continue to use the registry as normal while step one is being completed.

In GitLab 18.5 and later, if step one is interrupted, you can run it again and skip
repositories that were already pre-imported. By default, the import skips repositories
pre-imported in the last 72 hours. For more information, see
[restore interrupted imports](container_registry_metadata_database.md#restore-interrupted-imports).

{{< tabs >}}

{{< tab title="GitLab 18.7 and later" >}}

1. Ensure the database is disabled in the `database` section of your `/etc/gitlab/gitlab.rb` file:

   ```ruby
   registry['database'] = {
     'enabled' => false, # Must be false!
   }
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).
1. [Apply database migrations](container_registry_metadata_database.md#apply-database-migrations).
1. Run the first step to begin the import:

   ```shell
   sudo gitlab-ctl registry-database import --step-one --log-to-stdout
   ```

{{< /tab >}}

{{< tab title="GitLab 18.3 to 18.6" >}}

1. Ensure the database is disabled in the `database` section of your `/etc/gitlab/gitlab.rb` file:

   ```ruby
   registry['database'] = {
     'enabled' => false, # Must be false!
   }
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).
1. [Apply database migrations](container_registry_metadata_database.md#apply-database-migrations).
1. Run the first step to begin the import:

   ```shell
   sudo -u registry gitlab-ctl registry-database import --step-one --log-to-stdout
   ```

{{< /tab >}}

{{< tab title="GitLab 17.5 to 18.2" >}}

Prerequisites:

- Create an [external database](../postgresql/external.md#container-registry-metadata-database).

1. Add the `database` section to your `/etc/gitlab/gitlab.rb` file, but start with the metadata database disabled:

   ```ruby
   registry['database'] = {
     'enabled' => false, # Must be false!
     'host' => '<registry_database_host_placeholder_change_me>',
     'port' => 5432, # Default, but set to the port of your database instance if it differs.
     'user' => '<registry_database_username_placeholder_change_me>',
     'password' => '<registry_database_placeholder_change_me>',
     'dbname' => '<registry_database_name_placeholder_change_me>',
     'sslmode' => 'require', # See the PostgreSQL documentation for additional information https://www.postgresql.org/docs/16/libpq-ssl.html.
     'sslcert' => '</path/to/cert.pem>',
     'sslkey' => '</path/to/private.key>',
     'sslrootcert' => '</path/to/ca.pem>'
   }
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).
1. [Apply database migrations](container_registry_metadata_database.md#apply-database-migrations) if you have not done so.
1. Run the first step to begin the import:

   ```shell
   sudo gitlab-ctl registry-database import --step-one
   ```

{{< /tab >}}

{{< /tabs >}}

> [!note]
> You should try to schedule the following step as soon as possible
> to reduce the amount of downtime required. Ideally, less than one week
> after step one completes. Any new data written to the registry between steps one and two
> causes step two to take more time.

## Import all repository data (step two)

This step requires the registry to be set in `read-only` mode.
Step two is usually much shorter than step one. For example, in one of the user reports,
step two took 12.5 hours after a step one of 344 hours.
Allow enough time for downtime while step two is being executed.

{{< tabs >}}

{{< tab title="GitLab 18.7 and later" >}}

1. Ensure the registry is set to `read-only` mode.

   Edit your `/etc/gitlab/gitlab.rb` and add the `maintenance` section to the `registry['storage']`
   configuration. For example, for a `gcs`-backed registry using a `gs://my-company-container-registry`
   bucket, the configuration could be:

   ```ruby
   ## Object Storage - Container Registry
   registry['storage'] = {
     'gcs' => {
       'bucket' => '<my-company-container-registry>',
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
1. Run step two of the import:

   ```shell
   sudo gitlab-ctl registry-database import --step-two --log-to-stdout
   ```

1. If the command completed successfully, all images are now fully imported. You
   can now enable the database, turn off read-only mode in the configuration, and
   start the registry service:

   ```ruby
   registry['database'] = {
     'enabled' => true, # Must be set to true!
   }

   ## Object Storage - Container Registry
   registry['storage'] = {
     'gcs' => {
       'bucket' => '<my-company-container-registry>',
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

{{< /tab >}}

{{< tab title="GitLab 18.3 to 18.6" >}}

1. Ensure the registry is set to `read-only` mode.

   Edit your `/etc/gitlab/gitlab.rb` and add the `maintenance` section to the `registry['storage']`
   configuration. For example, for a `gcs`-backed registry using a `gs://my-company-container-registry`
   bucket, the configuration could be:

   ```ruby
   ## Object Storage - Container Registry
   registry['storage'] = {
     'gcs' => {
       'bucket' => '<my-company-container-registry>',
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
1. Run step two of the import:

   ```shell
   sudo -u registry gitlab-ctl registry-database import --step-two --log-to-stdout
   ```

1. If the command completed successfully, all images are now fully imported. You
   can now enable the database, turn off read-only mode in the configuration, and
   start the registry service:

   ```ruby
   registry['database'] = {
     'enabled' => true, # Must be set to true!
   }

   ## Object Storage - Container Registry
   registry['storage'] = {
     'gcs' => {
       'bucket' => '<my-company-container-registry>',
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

{{< /tab >}}

{{< tab title="GitLab 17.5 to 18.2" >}}

1. Ensure the registry is set to `read-only` mode.

   Edit your `/etc/gitlab/gitlab.rb` and add the `maintenance` section to the `registry['storage']`
   configuration. For example, for a `gcs`-backed registry using a `gs://my-company-container-registry`
   bucket, the configuration could be:

   ```ruby
   ## Object Storage - Container Registry
   registry['storage'] = {
     'gcs' => {
       'bucket' => '<my-company-container-registry>',
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
1. Run step two of the import:

   ```shell
   sudo gitlab-ctl registry-database import --step-two
   ```

1. If the command completed successfully, all images are now fully imported. You
   can now enable the database, turn off read-only mode in the configuration, and
   start the registry service:

   ```ruby
   registry['database'] = {
     'enabled' => true, # Must be set to true!
     'host' => '<registry_database_host_placeholder_change_me>',
     'port' => 5432, # Default, but set to the port of your database instance if it differs.
     'user' => '<registry_database_username_placeholder_change_me>',
     'password' => '<registry_database_placeholder_change_me>',
     'dbname' => '<registry_database_name_placeholder_change_me>',
     'sslmode' => 'require', # See the PostgreSQL documentation for additional information https://www.postgresql.org/docs/16/libpq-ssl.html.
     'sslcert' => '</path/to/cert.pem>',
     'sslkey' => '</path/to/private.key>',
     'sslrootcert' => '</path/to/ca.pem>'
   }

   ## Object Storage - Container Registry
   registry['storage'] = {
     'gcs' => {
       'bucket' => '<my-company-container-registry>',
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

{{< /tab >}}

{{< /tabs >}}

You can now use the metadata database for all operations!

## Import remaining data (step three)

Even though the registry is now fully using the database for its metadata, it
does not yet have access to any potentially unused layer blobs, preventing these
blobs from being removed by the online garbage collector.

You may continue to use the registry as normal while step three is being completed.
Step three can take longer than step one, but it does not require downtime.
If step three is interrupted, you can run it again. Step three
[imports only the blobs that are not already in the database](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/database-import-tool.md#common-blobs).

To complete the process, run the final step of the migration:

{{< tabs >}}

{{< tab title="GitLab 18.7 and later" >}}

```shell
sudo gitlab-ctl registry-database import --step-three --log-to-stdout
```

{{< /tab >}}

{{< tab title="GitLab 18.3 to 18.6" >}}

```shell
sudo -u registry gitlab-ctl registry-database import --step-three --log-to-stdout
```

{{< /tab >}}

{{< tab title="GitLab 17.5 to 18.2" >}}

```shell
sudo gitlab-ctl registry-database import --step-three
```

{{< /tab >}}

{{< /tabs >}}

After that command exits successfully, registry metadata is now fully imported to the database.

## After import

Large registries can have hundreds of thousands or even millions of blobs queued
for garbage collection review after an import. This is expected, and at default
worker intervals it takes time to process.

For guidance on what to expect and how to speed up processing, see:

- [Post import](container_registry_metadata_database.md#post-import) for an overview of
  expected behavior after completing an import.
- [Check the health of online garbage collection](container_registry_metadata_database.md#check-the-health-of-online-garbage-collection)
  to monitor the garbage collection review queues.
- [Adjust the garbage collector worker interval](container_registry_metadata_database.md#adjust-the-garbage-collector-worker-interval)
  to temporarily speed up processing for large backlogs.
