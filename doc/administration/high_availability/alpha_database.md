# Configuring a Database for GitLab HA

**Warning**
This functionality should be considered beta, use with caution.
**Warning**

You can choose to install and manage a database server (PostgreSQL/MySQL)
yourself, or you can use GitLab Omnibus packages to help. GitLab recommends
PostgreSQL. This is the database that will be installed if you use the
Omnibus package to manage your database.

## Configure your own database server

If you're hosting GitLab on a cloud provider, you can optionally use a
managed service for PostgreSQL. For example, AWS offers a managed Relational
Database Service (RDS) that runs PostgreSQL.

Alternatively, you may opt to manage your own PostgreSQL instance or cluster
separate from the GitLab Omnibus package.

If you use a cloud-managed service, or provide your own PostgreSQL instance:

1. Setup PostgreSQL according to the
   [database requirements document](../../install/requirements.md#database).
1. Set up a `gitlab` username with a password of your choice. The `gitlab` user
   needs privileges to create the `gitlabhq_production` database.
1. Configure the GitLab application servers with the appropriate details.
   This step is covered in [Configuring GitLab for HA](gitlab.md).

## Configure using Omnibus
Following these steps should leave you with a database cluster consisting of at least 2 nodes,
using [repmgr](http://www.repmgr.org/) to handle standby synchronization, and failing over.

### On each database node
1. Download/install GitLab Omnibus using **steps 1 and 2** from
   [GitLab downloads](https://about.gitlab.com/downloads). Do not complete other
   steps on the download page.

1. Create a password hash for the sql user (the default username is `gitlab`)
   ```
   $ echo -n 'PASSWORD+USERNAME' | md5sum
   ```

1. Create/edit `/etc/gitlab/gitlab.rb` and use the following configuration.
   If there is a directive listed below that you do not see in the configuration, be sure to add it.
    ```ruby
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
    postgresql['md5_auth_cidr_addresses'] = ['0.0.0.0/0']
    postgresql['listen_address'] = '0.0.0.0'
    postgresql['sql_user_password'] = 'PASSWORD_HASH' # This is the hash generated in the previous step
    postgresql['trust_auth_cidr_addresses'] = ['127.0.0.0/24']
    postgresql['hot_standby'] = 'on'
    postgresql['wal_level'] = 'replica'
    postgresql['max_wal_senders'] = X # Should be set to at least 1 more than the number of nodes in the cluster
    postgresql['shared_preload_libraries'] = 'repmgr_funcs' # If this attribute is already defined, append the new value as a comma separated list
    postgresql['custom_pg_hba_entries']['repmgr'] = [
      {
        type: 'local',
        database: 'replication',
        user: 'gitlab_replicator',
        method: 'trust',
      },
      {
        type: 'host',
        database: 'replication',
        user: 'gitlab_replicator',
        cidr: '127.0.0.1/32',
        method: 'trust'
      },
      {
        type: 'host',
        database: 'replication',
        user: 'gitlab_replicator',
        cidr: 'XXX.XXX.XXX.XXX/YY', # This should be the CIDR of the network your database nodes are on
        method: 'trust'
      },
      {
        type: 'local',
        database: 'repmgr',
        user: 'gitlab_replicator',
        method: 'trust',
      },
      {
        type: 'host',
        database: 'repmgr',
        user: 'gitlab_replicator',
        cidr: '127.0.0.1/32',
        method: 'trust'
      },
      {
        type: 'host',
        database: 'repmgr',
        user: 'gitlab_replicator',
        cidr: 'XXX.XXX.XXX.XXX/YY', # This should be the CIDR of the network your database nodes are on
        method: 'trust'
      }
    ]

    # Disable automatic database migrations
    gitlab_rails['auto_migrate'] = false
    ```

1. Reconfigure GitLab for the new settings to take effect
    ```
    # gitlab-ctl reconfigure
    ```

1. Create `/var/opt/gitlab/postgresql/repmgr.conf` with the following content. Use a unique integer for the value of node.
    ```
    cluster=gitlab_cluster
    node=X
    node_name=HOSTNAME
    conninfo='host=HOSTNAME user=gitlab_replicator dbname=repmgr'
    pg_bindir='/opt/gitlab/embedded/bin'
    service_start_command = '/opt/gitlab/bin/gitlab-ctl start postgresql'
    service_stop_command = '/opt/gitlab/bin/gitlab-ctl stop postgresql'
    service_restart_command = '/opt/gitlab/bin/gitlab-ctl restart postgresql'
    promote_command = '/opt/gitlab/embedded/bin/repmgr standby promote -f /var/opt/gitlab/postgresql/repmgr.conf'
    follow_command = '/opt/gitlab/embedded/bin/repmgr standby follow -f /var/opt/gitlab/postgresql/repmgr.conf'
    ```

### On the primary database node

1. Open a database prompt:

    ```
    $ gitlab-psql -d template1
    # Output:

    psql (DB_VERSION)
    Type "help" for help.

    template1=#
    ```

1. Run the following command at the database prompt and you will be asked to
   enter the new password for the PostgreSQL superuser.

    ```
    template1=# \password

    # Output:

    Enter new password:
    Enter it again:
    ```

1. Create the repmgr database:
    ```
    template1=# ALTER USER gitlab_replicator WITH SUPERUSER;
    template1=# CREATE DATABASE repmgr WITH OWNER gitlab_replicator;
    ```

1. Switch to the GitLab database and Enable the `pg_trgm` extension:
    ```
    template1=# \c gitlabhq_production
    gitlabhq_production=# CREATE EXTENSION pg_trgm;

    # Output:

    CREATE EXTENSION
    ```

1. Exit the database prompt by typing `\q` and Enter.

1. Register the node as the initial master node for the repmgr cluster
    ```
    # su - gitlab-psql
    $ repmgr -f /var/opt/gitlab/postgresql/repmgr.conf master register
    NOTICE: master node correctly registered for cluster 'gitlab_cluster' with id X (conninfo: host=HOSTNAME user=gitlab_replicator dbname=repmgr)
    ```

1. Verify the cluster is initialized with one node
   ```
   $ repmgr -f /var/opt/gitlab/postgresql/repmgr.conf cluster show
   Role      | Name        | Upstream | Connection String
   ----------+-------------|----------|----------------------------------------
   * master  | HOSTNAME    |          | host=HOSTNAME user=gitlab_replicator dbname=repmgr
   ```

### On each standby node
1. Stop postgresql
    ```
    # gitlab-ctl stop postgresql
    ```

1. Clear out the current data directory
    ```
    # rm -rf /var/opt/gitlab/postgresql/data/*
    ```

1. Synchronize the data from the primary node:
   ```
   # su - gitlab-psql
   $ repmgr -h PRIMARY_HOSTNAME -U gitlab_replicator -d repmgr -D /var/opt/gitlab/postgresql/data/ -f /var/opt/gitlab/postgresql/repmgr.conf standby clone
   ```

1. Start the database
    ```
    $ gitlab-ctl start postgresql
    ```

1. Register the node with the cluster
    ```
    $ repmgr -f /var/opt/gitlab/postgresql/repmgr.conf standby register
    NOTICE: standby node correctly registered for cluster gitlab_cluster with id X (conninfo: host=HOSTNAME user=gitlab_replicator dbname=repmgr)
    ```

1. Verify the node now appears in the cluster
   ```
   $ repmgr -f /var/opt/gitlab/postgresql/repmgr.conf cluster show
   Role      | Name       | Upstream   | Connection String
   ----------+------------|------------|------------------------------------------------
   * master  | MASTER     |            | host=MASTER_HOSTNAME  user=gitlab_replicator dbname=repmgr
     standby | STANDBY    | MASTER     | host=STANDBY_HOSTNAME user=gitlab_replicator  dbname=repmgr
   ```

### (Optional) Enable repmgrd
You can use repmgrd to monitor the database, and automatically failover if it detects the current master is unreachable.
Currently, there is no method of telling the application to automatically fail over to the new master, it must be done
manually. So this step is not required.

If you still want to enable this feature, do the following on each database node
1. Add the following line to `/var/opt/gitlab/postgresql/repmgr.conf`
    ```
    failover=automatic
    ```

1. Create the log directory
    ```
    install -o -d gitlab-psql /var/log/gitlab/repmgr
    ```

1. Start repmgrd
    ```
    # su - gitlab-psql -c '/opt/gitlab/embedded/bin/repmgrd -f /var/opt/gitlab/postgresql/repmgr.conf --verbose -d >> /var/log/gitlab/repmgr/repmgr.log 2>&1'
    ```

### Operations
If your master node is experiencing an issue, you can manually failover.
1. If the master database is still running, shut it down first
   ```
   # gitlab-ctl stop postgresql
   ```

1. Login to the server that should become the new master and run the following
    ```
    # su - gitlab-psql
    $ repmgr -f /var/opt/gitlab/postgresql/repmgr.conf standby promote
    ```

1. If there are any other standby servers in the cluster, have them follow the new master server
    ```
    # su - gitlab-psql
    # repmgr -f /var/opt/gitlab/postgresql/repmgr.conf -h NEW_MASTER -U gitlab_replicator -d repmgr -d /var/opt/gitlab/postgresql/data standby follow
    ```

1. On the servers that run `gitlab-rails`, set the `gitlab_rails['db_host']` attribute to the new master, and run `gitlab-ctl reconfigure`

1. At this point, you should have a functioning cluster with database writes going to the new master. Now you can recover the failed master server, or remove it from the cluster

1. If you want to remove the node from the cluster, on any other node in the cluster, run:
    ```
    # su - gitlab-psql
    $ repmgr -f /var/opt/gitlab/postgresql/repmgr.conf standby unregister --node=X # X should be the value of node in repmgr.conf on the old server
    ```

1. If the failed master has been recovered, it can be converted to a standby server and follow the new master server[^1]
    ```
    # su - gitlab-psql
    # repmgr -f /var/opt/gitlab/postgresql/repmgr.conf -h NEW_MASTER -U gitlab_replicator -d repmgr -d /var/opt/gitlab/postgresql/data standby follow
    ```

[^1]: When the server is back online, and before you switch it to a standby node, repmgr will report that there are two masters.
If there are any clients that are still writing to the old master, this will cause a split, and the old master will need to be resynced from scratch by performing a `standby clone` before you run `standby follow`

## Configuring the Application
After database setup is complete, the next step is to Configure the GitLab application servers with the appropriate details.
When prompted for `gitlab_rails['db_host']`, this should be set to the master node in your cluster.
This step is covered in [Configuring GitLab for HA](gitlab.md).

---

Read more on high-availability configuration:

1. [Configure Redis](redis.md)
1. [Configure NFS](nfs.md)
1. [Configure the GitLab application servers](gitlab.md)
1. [Configure the load balancers](load_balancer.md)
