---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Configure GitLab using an external PostgreSQL service
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

If you're hosting GitLab on a cloud provider, you can optionally use a
managed service for PostgreSQL. For example, AWS offers a managed Relational
Database Service (RDS) that runs PostgreSQL.

Alternatively, you may opt to manage your own PostgreSQL instance or cluster
separate from the Linux package.

If you use a cloud-managed service, or provide your own PostgreSQL instance:

1. Set up PostgreSQL according to the
   [database requirements document](../../install/requirements.md#postgresql).
1. Set up a `gitlab` user with a password of your choice, create the `gitlabhq_production` database, and make the user an
   owner of the database. You can see an example of this setup in the
   [self-compiled installation documentation](../../install/installation.md#7-database).
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
