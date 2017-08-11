# Configuring Databases for GitLab HA
> Note: GitLab HA requires an Enterprise Edition Premium license

**Warning**
This functionality should be considered beta, use with caution.
**Warning**

## Overview

GitLab supports multiple options for its database backend
* Using the Omnibus GitLab package to configure PG in HA setup (EEP only). This document contains directions for EEP users.
* Using GitLab with an [externally managed PostgreSQL service](../external_database.md). This could be a cloud provider, or your own service.
or for a non-HA option
* Using the Omnibus Gitlab CE/EES package with a [single PostgreSQL instance](http://docs.gitlab.com/omnibus/settings/database.html).

## Configure Omnibus GitLab package database HA (Enterprise Edition Premium)




### Preparation

The recommended configuration for a PostgreSQL HA setup requires:
* A minimum of three consul server nodes
* A minimum of two database nodes
  * Each node will run the following services
    * postgresql -- The database itself
    * repmgrd -- A service to monitor, and handle failover in case of a master failure
    * consul -- Used for service discovery, to alert other nodes when failover occurs
* At least one separate node for running the `pgbouncer` service.

#### Required information

* Network information for all nodes
  * DNS names -- By default, `repmgr` and `pgbouncer` use DNS to locate nodes
  * IP address -- PostgreSQL does not listen on any network interface by default. It needs to know which IP address to listen on in order to use the network interface. It can be set to `0.0.0.0` to listen on all interfaces. It cannot be set to the loopack address 127.0.0.1
  * Network Address -- PostgreSQL access is controlled based on the network source. This can be in subnet (i.e. 192.168.0.0/255.255.255.0) or CIDR (i.e. 192.168.0.0/24) form.
* User information for `pgbouncer` service
  * Default username is `pgbouncer`. In the rest of the documentation we will refer to this username as `PGBOUNCER_USERNAME`
  * Password for `pgbouncer` service. In the rest of the documentation we will refer to this password as `PGBOUNCER_PASSWORD`
  * Password hash for `pgbouncer` service
    * This should be generated from `pgbouncer` username and password pair
    * Generate the hash with:
      ``
      $ echo -n 'PASSWORD+USERNAME' | md5sum
      ``
    * In the rest of the documentation we will refer to this hash as `PGBOUNCER_PASSWORD_HASH`
* The number of nodes in the database cluster.
  * When configuring PostgreSQL, we will set `max_wal_senders` to one more than this number. This is used to prevent replication from using up all of the available database connections.

### Installation

#### On each node
1. Download/install GitLab Omnibus using **steps 1 and 2** from
   [GitLab downloads](https://about.gitlab.com/downloads). Do not complete other
   steps on the download page.

#### On each consul server node
1. Edit `/etc/gitlab/gitlab.rb` and use the following configuration
    ```ruby
    # Disable all components except Consul
    bootstrap['enable'] = false
    gitaly['enable'] = false
    gitlab_workhorse['enable'] = false
    mailroom['enable'] = false
    nginx['enable'] = false
    postgresql['enable'] = false
    redis['enable'] = false
    sidekiq['enable'] = false
    unicorn['enable'] = false

    consul['enable'] = true
    consul['configuration'] = {
      server: true
    }
    ```

1. Reconfigure GitLab for the new settings to take effect
    ```
    # gitlab-ctl reconfigure
    ```

1. Pick one node, and tell the remaining nodes to join that node
    ```
    # /opt/gitlab/embedded/bin/consul join FIRST_NODE
    ```

1. Verify the nodes are all communicating
    ```
    # consul members
    Node         Address              Status  Type    Build  Protocol  DC
    NODE_ONE    XXX.XXX.XXX.YYY:8301  alive   server  0.9.2  2         gitlab_cluster
    NODE_TWO    XXX.XXX.XXX.YYY:8301  alive   server  0.9.2  2         gitlab_cluster
    NODE_THREE  XXX.XXX.XXX.YYY:8301  alive   server  0.9.2  2         gitlab_cluster
    ```

#### On each database node
1. Edit `/etc/gitlab/gitlab.rb` and use the following configuration.
   If there is a directive listed below that you do not see in the configuration, be sure to add it.
    ```ruby
    # Disable all components except PostgreSQL
    postgresql['enable'] = true
    bootstrap['enable'] = false
    nginx['enable'] = false
    unicorn['enable'] = false
    sidekiq['enable'] = false
    redis['enable'] = false
    gitaly['enable'] = false
    gitlab_workhorse['enable'] = false
    mailroom['enable'] = false

    # PostgreSQL configuration
    postgresql['listen_address'] = '0.0.0.0'
    postgresql['trust_auth_cidr_addresses'] = %w(127.0.0.0/24)
    postgresql['hot_standby'] = 'on'
    postgresql['wal_level'] = 'replica'
    postgresql['max_wal_senders'] = X
    postgresql['shared_preload_libraries'] = 'repmgr_funcs'

    # repmgr configuration
    repmgr['enable'] = true

    # Disable automatic database migrations
    gitlab_rails['auto_migrate'] = false

    # Enable the consul agent
    consul['enable'] = true
    consul['services'] = %w(postgresql)

    # START user configuration
    # Please set the real values as explained in Required Information section
    #
    postgresql['pgbouncer_user'] = 'PGBOUNCER_USER'
    postgresql['pgbouncer_user_password'] = 'PGBOUNCER_PASSWORD_HASH' # This is the hash generated in the preparation section
    repmgr['trust_auth_cidr_addresses'] = %w(XXX.XXX.XXX.XXX/YY) # This should be the CIDR of the network(s) your database nodes are on
    #
    # END user configuration
    ```

1. Reconfigure GitLab for the new settings to take effect
    ```
    # gitlab-ctl reconfigure
    ```

1. Join the node to the consul cluster. SERVER_NODE can be any of the consul server nodes
    ```
    # /opt/gitlab/embedded/bin/consul join SERVER_NODE
    Successfully joined cluster by contacting 1 nodes.
    ```

#### On the primary database node

1. Open a database prompt:

    ```
    $ gitlab-psql -d gitlabhq_production
    # Output:

    psql (DB_VERSION)
    Type "help" for help.

    gitlabhq_production=#
    ```

1. Enable the `pg_trgm` extension:
    ```
    gitlabhq_production=# CREATE EXTENSION pg_trgm;

    # Output:

    CREATE EXTENSION
    ```

1. Exit the database prompt by typing `\q` and Enter.

1. Verify the cluster is initialized with one node
   ```
   # gitlab-ctl repmgr cluster show
   Role      | Name        | Upstream | Connection String
   ----------+-------------|----------|----------------------------------------
   * master  | HOSTNAME    |          | host=HOSTNAME user=gitlab_repmgr dbname=gitlab_repmgr
   ```

#### On each standby node
1. Setup the repmgr standby
    ```
    # gitlab-ctl repmgr standby setup MASTER_NODE
    ```

1. Verify the node now appears in the cluster
   ```
   # gitlab-ctl repmgr cluster show
   Role      | Name       | Upstream   | Connection String
   ----------+------------|------------|------------------------------------------------
   * master  | MASTER     |            | host=MASTER_HOSTNAME  user=gitlab_repmgr dbname=gitlab_repmgr
     standby | STANDBY    | MASTER     | host=STANDBY_HOSTNAME user=gitlab_repmgr dbname=gitlab_repmgr
   ```

#### On the pgbouncer node
Ensure the following attributes are set
```ruby
pgbouncer['enable'] = true
pgbouncer['databases'] = {
  gitlabhq_production: {
    host: 'CURRENT_MASTER',
    user: 'PGBOUNCER_USER',
    password: 'PGBOUNCER_PASSWORD_HASH' # This should be the hash from the preparation section
  }
}
consul['enable'] = true
consul['watchers'] = %w(postgresql)
```

#### Configuring the Application
After database setup is complete, the next step is to Configure the GitLab application servers with the appropriate details.
Add the following to `/etc/gitlab/gitlab.rb` on the application nodes
```ruby
gitlab_rails['db_host'] = 'PGBOUNCER_NODE'
gitlab_rails['db_port'] = 6432
```

### Failover procedure
By default, if the master database fails, repmgrd should promote one of the standby nodes to master automatically, and consul will update pgbouncer with the new master.

If you need to failover manually, you have two options:
1. Shutdown the current master database
   ```
   # gitlab-ctl stop postgresql
   ```
   The automated failover process will see this and failover to one of the standby nodes.

1. Manually failover
  1. Ensure the old master node is not still active.

  1. Login to the server that should become the new master and run the following
      ```
      # gitlab-ctl repmgr standby promote
      ```

  1. If there are any other standby servers in the cluster, have them follow the new master server
      ```
      # gitlab-ctl repmgr standby follow NEW_MASTER
      ```

  1. On the pgbouncer nodes run the following
      ```
      # gitlab-ctl pgb-notify --host NEW_MASTER
      ```

### Restore procedure
If a node fails, it can be removed from the cluster, or added back as a standby after it has been restored to service.

* If you want to remove the node from the cluster, on any other node in the cluster, run:
    ```
    # gitlab-ctl repmgr standby unregister --node=X # X should be the value of node in repmgr.conf on the old server
    ```

* To add the node as a standby server[^1]
    ```
    # gitlab-ctl repmgr standby follow NEW_MASTER
    ```

[^1]: **Warning**: When the server is brought back online, and before you switch it to a standby node, repmgr will report that there are two masters.
If there are any clients that are still attempting to write to the old master, this will cause a split, and the old master will need to be resynced from scratch by performing a `standby setup NEW_MASTER`.

---

Read more on high-availability configuration:

1. [Configure Redis](redis.md)
1. [Configure NFS](nfs.md)
1. [Configure the GitLab application servers](gitlab.md)
1. [Configure the load balancers](load_balancer.md)
