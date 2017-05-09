# Configuring a Database for GitLab HA

You can choose to install and manage a database server (PostgreSQL/MySQL)
yourself, or you can use GitLab Omnibus packages to help. GitLab recommends
PostgreSQL. This is the database that will be installed if you use the
Omnibus package to manage your database.

## Configure your own database server

If you're hosting GitLab on a cloud provider, you can optionally use a
managed service for PostgreSQL. For example, AWS offers a managed Relational
Database Service (RDS) that runs PostgreSQL.

If you use a cloud-managed service, or provide your own PostgreSQL:

1. Setup PostgreSQL according to the
   [database requirements document](../../install/requirements.md#database).
1. Set up a `gitlab` username with a password of your choice. The `gitlab` user
   needs privileges to create the `gitlabhq_production` database.
1. Configure the GitLab application servers with the appropriate details.
   This step is covered in [Configuring GitLab for HA](gitlab.md).

## Configure using Omnibus

The recommended configuration for an Omnibus manage is:
* A minimum of 2 database servers, a primary and a slave.
* Use the bundled [pgbouncer](https://pgbouncer.github.io) to pool database connections

### Primary database server
1. Download/install GitLab Omnibus using **steps 1 and 2** from
   [GitLab downloads](https://about.gitlab.com/downloads). Do not complete other
   steps on the download page.
1. Create/edit `/etc/gitlab/gitlab.rb` and use the following configuration.
   Be sure to change the `external_url` to match your eventual GitLab front-end
   URL.

    ```ruby
    external_url 'https://gitlab.example.com'

    # Disable all components except PostgreSQL
    postgresql['enable'] = true
    bootstrap['enable'] = false
    nginx['enable'] = false
    unicorn['enable'] = false
    sidekiq['enable'] = false
    redis['enable'] = false
    gitlab_workhorse['enable'] = false
    mailroom['enable'] = false

    # PostgreSQL configuration
    gitlab_rails['db_password'] = 'DB password'
    postgresql['md5_auth_cidr_addresses'] = ['0.0.0.0/0']
    postgresql['trust_auth_cidr_addresses'] = ['127.0.0.0/24']
    postgresql['listen_address'] = '0.0.0.0'
    postgresql['sql_replication_user'] = 'gitlab_replicator'
    postgresql['sql_user_password'] = 'PASSWORD_HASH'
    postgresql['pgbouncer_user'] = 'pgbouncer'
    postgresql['pgbouncer_user_password'] = 'PASSWORD_HASH'
    postgresql['wal_level'] = 'hot_standby'
    postgresql['max_wal_senders'] = 5
    postgresql['wal_keep_segements'] = 32

    # Pgbouncer configuration
    pgbouncer['enable'] = true
    pgbouncer['databases'] = {
      gitlabhq_production: {
        host: '127.0.0.1',
        user: 'pgbouncer',
        password: 'PASSWORD_HASH'
      }
    }

    # Disable automatic database migrations
    gitlab_rails['auto_migrate'] = false
    ```

1. Run `sudo gitlab-ctl reconfigure` to install and configure PostgreSQL.

    > **Note**: This `reconfigure` step will result in some errors.
      That's OK - don't be alarmed.

1. Open a database prompt:

    ```
    /opt/gitlab/bin/gitlab-psql -d template1
    # Output:

    psql (9.6.1)
    Type "help" for help.

    template1=#
    ```

1. Run the following command at the database prompt and you will be asked to
   enter the new password for the PostgreSQL superuser.

    ```
    \password

    # Output:

    Enter new password:
    Enter it again:
    ```

1. Similarly, set the password for the `gitlab` database user. Use the same
   password that you specified in the `/etc/gitlab/gitlab.rb` file for
   `gitlab_rails['db_password']`.

    ```
    \password gitlab

    # Output:

    Enter new password:
    Enter it again:
    ```

1. Enable the `pg_trgm` extension:
    ```
    CREATE EXTENSION pg_trgm;

    # Output:

    CREATE EXTENSION
    ```
1. Exit the database prompt by typing `\q` and Enter.
1. Exit the `gitlab-psql` user by running `exit` twice.
1. Run `sudo gitlab-ctl reconfigure` a final time.

### Slave database server
1. Download/install GitLab Omnibus using **steps 1 and 2** from
   [GitLab downloads](https://about.gitlab.com/downloads). Do not complete other
   steps on the download page.
1. Create/edit `/etc/gitlab/gitlab.rb` and use the following configuration.
   Be sure to change the `external_url` to match your eventual GitLab front-end
   URL.

    ```ruby
    external_url 'https://gitlab.example.com'

    # Disable all components except PostgreSQL
    postgresql['enable'] = true
    bootstrap['enable'] = false
    nginx['enable'] = false
    unicorn['enable'] = false
    sidekiq['enable'] = false
    redis['enable'] = false
    gitlab_workhorse['enable'] = false
    mailroom['enable'] = false

    # PostgreSQL configuration
    gitlab_rails['auto_migrate'] = false
    postgresql['hot_standby'] = 'on'
    pgbouncer['enable'] = true
    pgbouncer['databases'] = {
      gitlabhq_production: {
        host: '127.0.0.1',
        user: 'pgbouncer',
        password: 'PASSWORD_HASH'
      }
   }
   ```
1. Run `sudo gitlab-ctl reconfigure` to install and configure PostgreSQL.

   > **Note**: This `reconfigure` step will result in some errors.
         That's OK - don't be alarmed.
1. Stop the database by running `sudo gitlab-ctl stop postgresql`
1. Remove the current database by running `sudo rm -rf /var/opt/gitlab/postgresl/data/*`
   > **WARNING**: Be absolutely sure you're running this on the correct server.
   Especially if you're working with an existing GitLab install
1. Perform the initial data synchrinozation by running:
```bash
su - gitlab-psql -c '/opt/gitlab/embedded/bin/pg_basebackup -h PRIMARY_DB_HOST -D /var/opt/gitlab/postgresql/data/ -P -U gitlab_replicator --xlog-method=stream'
```
> **Note**: When prompted, enter the password for the `gitlab_replicator` user
1. Create a file `/var/opt/gitlab/postgresql/data/recovery.conf` containing:
```
standby_mode          = 'on'
primary_conninfo      = 'host=PRIMARY_DB_HOST port=5432 user=gitlab_replicator password=password'
trigger_file = '/var/opt/gitlab/postgresql/data/trigger'
```
1. Run `sudo gitlab-ctl reconfigure` a final time.
1. If you are running with multiple standby servers, repeat these steps for each server.


After the database servers are configured, move on to configuraint  the GitLab application servers with the appropriate details.
This step is covered in [Configuring GitLab for HA](gitlab.md).

---

Read more on high-availability configuration:

1. [Configure Redis](redis.md)
1. [Configure NFS](nfs.md)
1. [Configure the GitLab application servers](gitlab.md)
1. [Configure the load balancers](load_balancer.md)
