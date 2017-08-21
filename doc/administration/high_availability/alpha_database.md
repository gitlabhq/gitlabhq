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
  * The service runs as the same user as the database, default of `gitlab-psql`
  * The service will have a regular database user account generated for it
  * Default username is `pgbouncer`. In the rest of the documentation we will refer to this username as `PGBOUNCER_USERNAME`
  * Password for `pgbouncer` service. In the rest of the documentation we will refer to this password as `PGBOUNCER_PASSWORD`
  * Password hash for `pgbouncer` service
    * This should be generated from `pgbouncer` username and password pair
    * Generate the hash with:
      ``
      $ echo -n 'PASSWORD+USERNAME' | md5sum
      ``
    * In the rest of the documentation we will refer to this hash as `PGBOUNCER_PASSWORD_HASH`
  * This password will be stored in the following locations
    * `/etc/gitlab/gitlab.rb`: hashed, and in plain text
    * `/var/opt/gitlab/pgbouncer/pg_auth`: hashed
* User information for the Repmgr service
  * The service runs under the same system account as the database by default.
  * The service requires a superuser database account be generated for it. This defaults to `gitlab_repmgr`
* User information for the Consul service
  * The consul service runs under a dedicated system account by default, `gitlab-consul`. In the rest of the documentation we will refer to this username as `CONSUL_USERNAME`
  * There will be a database user created with read only access to the repmgr database
  * Password for the database user. In the rest of the documentation we will refer to this password as `CONSUL_DATABASE_PASSWORD`
  * Password hash for `gitlab-consul` service
    * This should be generated from `gitlab-consul` username and password pair
    * Generate the hash with:
      ``
      $ echo -n 'PASSWORD+USERNAME' | md5sum
      ``
    * In the rest of the documentation we will refer to this hash as `CONSUL_PASSWORD_HASH`
  * This password will be stored in the following locations
    * '/etc/gitlab/gitlab.rb`: hashed
    * '/var/opt/gitlab/pgbouncer/pg_auth': hashed
    * '/var/opt/gitlab/gitlab-consul/.pgpass': plaintext
* The number of nodes in the database cluster.
  * When configuring PostgreSQL, we will set `max_wal_senders` to one more than this number. This is used to prevent replication from using up all of the available database connections.

### Installation

#### On each node
1. Download/install GitLab Omnibus using **steps 1 and 2** from
   [GitLab downloads](https://about.gitlab.com/downloads). Do not complete other
   steps on the download page.

#### Configuration
Each node needs to be configured to run only the services it needs. Create an `/etc/gitlab/gitlab.rb` on each node which looks like the following, then run `gitlab-ctl reconfigure`

##### On each consul server node
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
# START user configuration
# Please set the real values as explained in Required Information section
#
consul['configuration'] = {
  server: true,
  retry_join: %w(NAMES OR IPS OF ALL CONSUL NODES)
}
#
# END user configuration
```

##### On each database node
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
postgresql['md5_auth_cidr_addresses'] = %w(0.0.0.0/0)
postgresql['hot_standby'] = 'on'
postgresql['wal_level'] = 'replica'
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
postgresql['max_wal_senders'] = X
repmgr['trust_auth_cidr_addresses'] = %w(XXX.XXX.XXX.XXX/YY) # This should be the CIDR of the network(s) your database nodes are on
consul['configuration'] = {
  retry_join: %w(NAMES OR IPS OF ALL CONSUL NODES)
}
#
# END user configuration
```

##### On the pgbouncer node
Ensure the following attributes are set
```ruby
# Disable all components except Pgbouncer
postgresql['enable'] = false
bootstrap['enable'] = false
nginx['enable'] = false
unicorn['enable'] = false
sidekiq['enable'] = false
redis['enable'] = false
gitaly['enable'] = false
gitlab_workhorse['enable'] = false
mailroom['enable'] = false
pgbouncer['enable'] = true

# Configure pgbouncer
pgbouncer['listen_address'] = '0.0.0.0'

# Enable the consul agent
consul['enable'] = true
consul['watchers'] = %w(postgresql)

# START user configuration
# Please set the real values as explained in Required Information section
#
consul['configuration'] = {
  retry_join: %w(NAMES OR IPS OF ALL CONSUL NODES)
}
#
# END user configuration
```

##### Application node(s)
These will be the nodes running the gitlab-rails service. You may have other attributes set, but the following need to be set
```ruby
gitlab_rails['db_host'] = 'PGBOUNCER_NODE'
gitlab_rails['db_port'] = 6432
```

#### Post-configuration
After reconfigure successfully runs, the following steps must be completed to get the cluster up and running

#### Consul server nodes
1. Verify the nodes are all communicating
    ```
    # consul members
    Node         Address              Status  Type    Build  Protocol  DC
    NODE_ONE    XXX.XXX.XXX.YYY:8301  alive   server  0.9.2  2         gitlab_cluster
    NODE_TWO    XXX.XXX.XXX.YYY:8301  alive   server  0.9.2  2         gitlab_cluster
    NODE_THREE  XXX.XXX.XXX.YYY:8301  alive   server  0.9.2  2         gitlab_cluster
    ```

##### On the primary database node

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

##### On each standby node
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

##### On the pgbouncer node
1. Create a `.pgpass` file user for the `CONSUL_USER` account to be able to reload pgbouncer
   ```
   # gitlab-ctl write-pgpass --host PGBOUNCER_HOSE --database pgbouncer --user gitlab-consul
   Please enter password: ****
   Confirm password: ****
   ```

1. Ensure the node is talking to the current master
   ```
   # /opt/gitlab/embedded/bin/psql -h 127.0.0.1 -p 6432 -d pgbouncer pgbouncer # You will be prompted for PGBOUNCER_PASSWORD
   pgbouncer=# show databases ; show clients ;
           name         |  host       | port |      database       | force_user | pool_size | reserve_pool | pool_mode | max_connections | current_connections
   ---------------------+-------------+------+---------------------+------------+-----------+--------------+-----------+-----------------+---------------------
    gitlabhq_production | MASTER_HOST | 5432 | gitlabhq_production |            |        20 |            0 |           |               0 |                   0
    pgbouncer           |             | 6432 | pgbouncer           | pgbouncer  |         2 |            0 | statement |               0 |                   0
   (2 rows)

    type |   user    |      database       |  state  |   addr         | port  | local_addr | local_port |    connect_time     |    request_time     |    ptr    | link
    | remote_pid | tls
   ------+-----------+---------------------+---------+----------------+-------+------------+------------+---------------------+---------------------+-----------+-----
   -+------------+-----
    C    | (nouser)  | gitlabhq_production | waiting | IP_OF_APP_NODE | 56512 | 127.0.0.1  |       6432 | 2017-08-21 18:08:51 | 2017-08-21 18:08:51 | 0x22b3700 |
    |          0 |
    C    | pgbouncer | pgbouncer           | active  | 127.0.0.1      | 56846 | 127.0.0.1  |       6432 | 2017-08-21 18:09:59 | 2017-08-21 18:10:48 | 0x22b3880 |
    |          0 |
   (2 rows)

1. It may be necessary to manually run migrations.
   ```
   # gitlab-rake db:migrate
   ```

#### Server running
At this point, your GitLab instance should be up and running, verify you are able to login, and create issues and merge requests.

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

### Restore procedure
If a node fails, it can be removed from the cluster, or added back as a standby after it has been restored to service.

* If you want to remove the node from the cluster, on any other node in the cluster, run:
    ```
    # gitlab-ctl repmgr standby unregister --node=X # X should be the value of node in repmgr.conf on the old server
    ```

* To add the node as a standby server[^1]
    ```
    # gitlab-ctl repmgr standby follow NEW_MASTER
    # gitlab-ctl restart repmgrd
    ```

[^1]: **Warning**: When the server is brought back online, and before you switch it to a standby node, repmgr will report that there are two masters.
If there are any clients that are still attempting to write to the old master, this will cause a split, and the old master will need to be resynced from scratch by performing a `standby setup NEW_MASTER`.

---

Read more on high-availability configuration:

1. [Configure Redis](redis.md)
1. [Configure NFS](nfs.md)
1. [Configure the GitLab application servers](gitlab.md)
1. [Configure the load balancers](load_balancer.md)
