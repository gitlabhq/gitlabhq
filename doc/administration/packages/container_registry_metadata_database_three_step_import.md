---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
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

### Pre-import repositories (step one)

Users have reported step one import completed at [rates of 2 to 4 TB per hour](https://gitlab.com/gitlab-org/gitlab/-/issues/423459).
At the slower speed, registries with over 100TB of data could take longer than 48 hours.

You may continue to use the registry as normal while step one is being completed.

{{< tabs >}}

{{< tab title="GitLab 18.3 and later" >}}

1. Ensure the database is disabled in the `database` section to your `/etc/gitlab/gitlab.rb` file:

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

{{< alert type="note" >}}

You should try to schedule the following step as soon as possible
to reduce the amount of downtime required. Ideally, less than one week
after step one completes. Any new data written to the registry between steps one and two,
causes step two to take more time.

{{< /alert >}}

### Import all repository data (step two)

This step requires the registry to be shut down or set in `read-only` mode;
however, you can expect this step to complete around 90% faster than step one.
Allow enough time for downtime while step two is being executed.

{{< tabs >}}

{{< tab title="GitLab 18.3 and later" >}}

1. Ensure the registry is set to `read-only` mode.

   Edit your `/etc/gitlab/gitlab.rb` and add the `maintenance` section to the `registry['storage']`
   configuration. For example, for a `gcs` backend registry using a `gs://my-company-container-registry`
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
   configuration. For example, for a `gcs` backed registry using a `gs://my-company-container-registry`
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

### Import remaining data (step three)

Even though the registry is now fully using the database for its metadata, it
does not yet have access to any potentially unused layer blobs, preventing these
blobs from being removed by the online garbage collector.

You may continue to use the registry as normal while step three is being completed.

To complete the process, run the final step of the migration:

{{< tabs >}}

{{< tab title="GitLab 18.3 and later" >}}

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

After that command exists successfully, registry metadata is now fully imported to the database.
