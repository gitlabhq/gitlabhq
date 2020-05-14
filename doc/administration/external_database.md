# Configure GitLab using an external PostgreSQL service

If you're hosting GitLab on a cloud provider, you can optionally use a
managed service for PostgreSQL. For example, AWS offers a managed Relational
Database Service (RDS) that runs PostgreSQL.

Alternatively, you may opt to manage your own PostgreSQL instance or cluster
separate from the Omnibus GitLab package.

If you use a cloud-managed service, or provide your own PostgreSQL instance:

1. Set up PostgreSQL according to the
   [database requirements document](../install/requirements.md#database).
1. Set up a `gitlab` username with a password of your choice. The `gitlab` user
   needs privileges to create the `gitlabhq_production` database.
1. If you are using a cloud-managed service, you may need to grant additional
   roles to your `gitlab` user:
   - Amazon RDS requires the [`rds_superuser`](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.html#Appendix.PostgreSQL.CommonDBATasks.Roles) role.
   - Azure Database for PostgreSQL requires the [`azure_pg_admin`](https://docs.microsoft.com/en-us/azure/postgresql/howto-create-users#how-to-create-additional-admin-users-in-azure-database-for-postgresql) role.

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

    For more information on GitLab HA setups, refer to [configuring GitLab for HA](high_availability/gitlab.md).

1. Reconfigure for the changes to take effect:

   ```shell
   sudo gitlab-ctl reconfigure
   ```
