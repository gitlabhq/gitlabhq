---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Container registry metadata database for new installations
description: Enable the container registry metadata database for new installations.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

Enable the container registry metadata database for your instance.

## Enable the metadata database

Enable the metadata database for a new container registry.

{{< tabs >}}

{{< tab title="GitLab 18.3 and later" >}}

Prerequisites:

- You must have a new container registry with no images pushed to the registry.

To enable the database:

1. Enable the database by editing `/etc/gitlab/gitlab.rb` and setting `enabled` to `true`:

   ```ruby
   registry['database'] = {
     'enabled' => true,
   }
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).

{{< /tab >}}

{{< tab title="GitLab 17.5 to 18.2" >}}

Prerequisites:

- You must have a new container registry with no images pushed to the registry.
- Create an [external database](../postgresql/external.md#container-registry-metadata-database).

To enable the database:

1. Edit `/etc/gitlab/gitlab.rb` by adding your database connection details, but start with the metadata database disabled:

   ```ruby
   registry['database'] = {
     'enabled' => false,
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
1. [Apply database migrations](container_registry_metadata_database.md#apply-database-migrations).
1. Enable the database by editing `/etc/gitlab/gitlab.rb` and setting `enabled` to `true`:

   ```ruby
   registry['database'] = {
     'enabled' => true,
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

{{< /tab >}}

{{< /tabs >}}

You can now use the metadata database for all operations!
