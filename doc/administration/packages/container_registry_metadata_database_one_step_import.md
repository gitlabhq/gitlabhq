---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: One-step import
description: Enable the container registry metadata database in one step.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

Use the one-step import method if you regularly run [offline garbage collection](container_registry.md#container-registry-garbage-collection). This method is a
simpler operation compared to the three-step import method.

## One-step import

{{< alert type="warning" >}}

The registry must be shut down or remain in `read-only` mode during the import.
Otherwise, data written during the import becomes inaccessible or leads to inconsistencies.

{{< /alert >}}

{{< tabs >}}

{{< tab title="GitLab 18.3 and later" >}}

1. Ensure the database is disabled in the `registry['database']` section of your `/etc/gitlab/gitlab.rb` file:

   ```ruby
   registry['database'] = {
     'enabled' => false, # Must be false!
   }
   ```

1. Ensure the registry is set to `read-only` mode.

   Edit your `/etc/gitlab/gitlab.rb` and add the `maintenance` section to the `registry['storage']` configuration.
   For example, for a `gcs` backend registry using a `gs://my-company-container-registry` bucket,
   the configuration could be:

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
1. [Apply database migrations](container_registry_metadata_database.md#apply-database-migrations).
1. Run the following command:

   ```shell
   sudo -u registry gitlab-ctl registry-database import --log-to-stdout
   ```

1. If the command completed successfully, the registry is fully imported. You
   can enable the database, turn off read-only mode in the configuration, and
   start the registry service:

   ```ruby
   registry['database'] = {
     'enabled' => true, # Must be enabled now!
   }

   ## Object Storage - Container Registry
   registry['storage'] = {
     'gcs' => {
       'bucket' => '<my-company-container-registry>',
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

1. Ensure the registry is set to `read-only` mode.

   Edit your `/etc/gitlab/gitlab.rb` and add the `maintenance` section to the `registry['storage']` configuration.
   For example, for a `gcs` backed registry using a `gs://my-company-container-registry` bucket,
   the configuration could be:

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
1. [Apply database migrations](container_registry_metadata_database.md#apply-database-migrations) if you have not done so.
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
     'maintenance' => {
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
