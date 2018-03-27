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

1. Download/install GitLab Omnibus using **steps 1 and 2** from
   [GitLab downloads](https://about.gitlab.com/downloads). Do not complete other
   steps on the download page.
1. Create/edit `/etc/gitlab/gitlab.rb` and use the following configuration.
   Be sure to change the `external_url` to match your eventual GitLab front-end
   URL. If there is a directive listed below that you do not see in the configuration, be sure to add it.

    ```ruby
    external_url 'https://gitlab.example.com'

    # Disable all components except PostgreSQL
    postgresql['enable'] = true
    bootstrap['enable'] = false
    nginx['enable'] = false
    unicorn['enable'] = false
    sidekiq['enable'] = false
    redis['enable'] = false
    prometheus['enable'] = false
    gitaly['enable'] = false
    gitlab_workhorse['enable'] = false
    mailroom['enable'] = false

    # PostgreSQL configuration
    gitlab_rails['db_password'] = 'DB password'
    postgresql['md5_auth_cidr_addresses'] = ['0.0.0.0/0']
    postgresql['listen_address'] = '0.0.0.0'

    # Disable automatic database migrations
    gitlab_rails['auto_migrate'] = false
    ```

1. Run `sudo gitlab-ctl reconfigure` to install and configure PostgreSQL.

    > **Note**: This `reconfigure` step will result in some errors.
      That's OK - don't be alarmed.

1. Open a database prompt:

    ```
    su - gitlab-psql
    /bin/bash
    psql -h /var/opt/gitlab/postgresql -d template1

    # Output:

    psql (9.2.15)
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
1. Exit from editing `template1` prompt by typing `\q` and Enter.
1. Enable the `pg_trgm` extension within the `gitlabhq_production` database:
    
    ```
    gitlab-psql -d gitlabhq_production
    
    CREATE EXTENSION pg_trgm;

    # Output:

    CREATE EXTENSION
    ```
1. Exit the database prompt by typing `\q` and Enter.
1. Exit the `gitlab-psql` user by running `exit` twice.
1. Run `sudo gitlab-ctl reconfigure` a final time.
1. Configure the GitLab application servers with the appropriate details.
   This step is covered in [Configuring GitLab for HA](gitlab.md).

---

Read more on high-availability configuration:

1. [Configure Redis](redis.md)
1. [Configure NFS](nfs.md)
1. [Configure the GitLab application servers](gitlab.md)
1. [Configure the load balancers](load_balancer.md)
