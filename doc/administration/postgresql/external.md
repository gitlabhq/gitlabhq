---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Configure GitLab using an external PostgreSQL service
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

If you're hosting GitLab on a cloud provider, you can optionally use a
managed service for PostgreSQL. For example, AWS offers a managed Relational
Database Service (RDS) that runs PostgreSQL.

Alternatively, you may opt to manage your own PostgreSQL instance or cluster
separate from the Linux package.

If you use a cloud-managed service, or provide your own PostgreSQL instance,
set up PostgreSQL according to the
[database requirements document](../../install/requirements.md#postgresql).

## GitLab Rails database

After you set up the external PostgreSQL server:

1. Log in to your database server.
1. Set up a `gitlab` user with a password of your choice, create the `gitlabhq_production` database, and make the user an
   owner of the database. You can see an example of this setup in the
   [self-compiled installation documentation](../../install/self_compiled/_index.md#7-database).
1. If you are using a cloud-managed service, you may need to grant additional
   roles to your `gitlab` user:
   - Amazon RDS requires the [`rds_superuser`](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.html#Appendix.PostgreSQL.CommonDBATasks.Roles) role.
   - Azure Database for PostgreSQL requires the [`azure_pg_admin`](https://learn.microsoft.com/en-us/azure/postgresql/single-server/how-to-create-users#how-to-create-additional-admin-users-in-azure-database-for-postgresql) role. Azure Database for PostgreSQL - Flexible Server requires [allow-listing extensions before they can be installed](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-extensions#how-to-use-postgresql-extensions).
   - Google Cloud SQL requires the [`cloudsqlsuperuser`](https://cloud.google.com/sql/docs/postgres/users#default-users) role.

   This is for the installation of extensions during installation and upgrades. As an alternative,
   [ensure the extensions are installed manually, and read about the problems that may arise during future GitLab upgrades](../../install/postgresql_extensions.md).
1. Configure the GitLab application servers with the appropriate connection details
   for your external PostgreSQL service in your `/etc/gitlab/gitlab.rb` file:

   ```ruby
   # Disable the bundled Omnibus provided PostgreSQL
   postgresql['enable'] = false

   # PostgreSQL connection details
   gitlab_rails['db_adapter'] = 'postgresql'
   gitlab_rails['db_encoding'] = 'unicode'
   gitlab_rails['db_host'] = '10.1.0.5' # IP/hostname of database server
   gitlab_rails['db_port'] = 5432
   gitlab_rails['db_password'] = 'DB password'
   ```

   For more information on GitLab multi-node setups, refer to the [reference architectures](../reference_architectures/_index.md).

1. Reconfigure for the changes to take effect:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Restart PostgreSQL to enable the TCP port:

   ```shell
   sudo gitlab-ctl restart
   ```

## Container registry metadata database

If you plan to use the [container registry metadata database](../packages/container_registry_metadata_database.md),
you should also create the registry database and user.

After you set up the external PostgreSQL server:

1. Log in to your database server.
1. Use the following SQL commands to create the user and the database:

   ```sql
   -- Create the registry user
   CREATE USER registry WITH PASSWORD '<your_registry_password>';

   -- Create the registry database
   CREATE DATABASE registry OWNER registry;
   ```

1. For cloud-managed services, grant additional roles as needed:

   {{< tabs >}}

   {{< tab title="Amazon RDS" >}}

   ```sql
   GRANT rds_superuser TO registry;
   ```

   {{< /tab >}}

   {{< tab title="Azure database" >}}

   ```sql
   GRANT azure_pg_admin TO registry;
   ```

   {{< /tab >}}

   {{< tab title="Google Cloud SQL" >}}

   ```sql
   GRANT cloudsqlsuperuser TO registry;
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. You can now enable and start using the container registry metadata database.

## Troubleshooting

### Resolve `SSL SYSCALL error: EOF detected` error

When using an external PostgreSQL instance, you may see an error like:

```shell
pg_dump: error: Error message from server: SSL SYSCALL error: EOF detected
```

To resolve this error, ensure that you are meeting the
[minimum PostgreSQL requirements](../../install/requirements.md#postgresql). After
upgrading your RDS instance to a [supported version](../../install/requirements.md#postgresql),
you should be able to perform a backup without this error.
See [issue 64763](https://gitlab.com/gitlab-org/gitlab/-/issues/364763) for more information.
