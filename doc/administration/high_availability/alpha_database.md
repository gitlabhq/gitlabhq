# Omnibus GitLab PostgreSQL High Availability

> Available in [Omnibus GitLab Enterprise Edition Premium](https://about.gitlab.com/gitlab-ee/).

CAUTION: **Warning:**
This functionality should be considered **beta**, use with caution.

## Overview

GitLab supports multiple options for its database backend:

1. Using the Omnibus GitLab package to configure PG in HA setup (Enterprise Premium only).
1. Using GitLab with an [externally managed PostgreSQL service](../external_database.md).
   This could be a cloud provider, your own service, or for a non-HA option.
1. Using the Omnibus Gitlab Community or Enterprise Starter Edition packages with
   a [single PostgreSQL instance](http://docs.gitlab.com/omnibus/settings/database.html).

This document focuses on the first option.

## Preparation

The recommended configuration for a PostgreSQL HA setup requires:

- A minimum of three consul server nodes
- A minimum of two database nodes
  - Each node will run the following services:
    - PostgreSQL - The database itself
    - repmgrd - A service to monitor, and handle failover in case of a master failure
    - Consul - Used for service discovery, to alert other nodes when failover occurs
- At least one separate node for running the `pgbouncer` service.

## Required information

**Network information for all nodes**

- DNS names - By default, `repmgr` and `pgbouncer` use DNS to locate nodes
- IP address - PostgreSQL does not listen on any network interface by default.
  It needs to know which IP address to listen on in order to use the network
  interface. It can be set to `0.0.0.0` to listen on all interfaces. It cannot
  be set to the loopack address `127.0.0.1`
- Network Address - PostgreSQL access is controlled based on the network source.
  This can be in subnet (i.e. `192.168.0.0/255.255.255.0`) or CIDR (i.e.
  `192.168.0.0/24`) form.

**User information for `pgbouncer` service**

- The service runs as the same user as the database, default of `gitlab-psql`
- The service will have a regular database user account generated for it
- Default username is `pgbouncer`. In the rest of the documentation we will
  refer to this username as `PGBOUNCER_USERNAME`
- Password for `pgbouncer` service. In the rest of the documentation we will
  refer to this password as `PGBOUNCER_PASSWORD`
- Password hash for `pgbouncer` service generated from the `pgbouncer` username
  and password pair with:

    ```sh
    echo -n 'PASSWORD+USERNAME' | md5sum
    ```

    In the rest of the documentation we will refer to this hash as `PGBOUNCER_PASSWORD_HASH`
- This password will be stored in the following locations:
  - `/etc/gitlab/gitlab.rb`: hashed, and in plain text
  - `/var/opt/gitlab/pgbouncer/pg_auth`: hashed

**User information for the Repmgr service**

- The service runs under the same system account as the database by default.
- The service requires a superuser database account be generated for it. This
  defaults to `gitlab_repmgr`

**User information for the Consul service**

- The consul service runs under a dedicated system account by default,
  `gitlab-consul`. In the rest of the documentation we will refer to this
  username as `CONSUL_USERNAME`
- There will be a database user created with read only access to the repmgr
  database
- Password for the database user. In the rest of the documentation we will
  refer to this password as `CONSUL_DATABASE_PASSWORD`
- Password hash for `gitlab-consul` service generated from the `gitlab-consul`
  username and password pair with:

      ```sh
      echo -n 'PASSWORD+USERNAME' | md5sum
      ```

      In the rest of the documentation we will refer to this hash as `CONSUL_PASSWORD_HASH`
- This password will be stored in the following locations:
  - `/etc/gitlab/gitlab.rb`: hashed
  - `/var/opt/gitlab/pgbouncer/pg_auth`: hashed
  - `/var/opt/gitlab/gitlab-consul/.pgpass`: plaintext

**The number of nodes in the database cluster**

When configuring PostgreSQL, we will set `max_wal_senders` to one more than
this number. This is used to prevent replication from using up all of the
available database connections.

## Installing Omnibus GitLab

First, make sure to [download/install](https://about.gitlab.com/installation)
GitLab Omnibus **on each node**.

Just follow **steps 1 and 2**, do not complete any other steps shown in the
page above.

## Initial node configuration

Each node needs to be configured to run only the services it needs.

### Configuring the Consul server nodes

On each Consul node perform the following:

1. Edit `/etc/gitlab/gitlab.rb`:

    ```ruby
    # Disable all components except Consul
    bootstrap['enable'] = false
    gitlab_rails['auto_migrate'] = false
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

1. [Reconfigure GitLab] for the changes to take effect.

### Configuring the Database nodes

On each database node perform the following:

1. Edit `/etc/gitlab/gitlab.rb`:

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

1. [Reconfigure GitLab] for the changes to take effect.

### Configuring the Pgbouncer node

1. Edit `/etc/gitlab/gitlab.rb`:

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
    pgbouncer['admin_users'] = %w(pgbouncer gitlab-consul)
    pgbouncer['listen_address'] = '0.0.0.0'

    # Enable the consul agent
    consul['enable'] = true
    consul['watchers'] = %w(postgresql)

    # START user configuration
    # Please set the real values as explained in Required Information section
    #
    pgbouncer['users'] = {
      'gitlab-consul': {
        password: 'CONSUL_PASSWORD_HASH'
      },
      'pgbouncer': {
        password: 'PGBOUNCER_PASSWORD_HASH'
      }
    }
    consul['configuration'] = {
      retry_join: %w(NAMES OR IPS OF ALL CONSUL NODES)
    }
    #
    # END user configuration
    ```

1. [Reconfigure GitLab] for the changes to take effect.

### Configuring the Application nodes

These will be the nodes running the `gitlab-rails` service. You may have other
attributes set, but the following need to be set.

1. Edit `/etc/gitlab/gitlab.rb`:

    ```ruby
    gitlab_rails['db_host'] = 'PGBOUNCER_NODE'
    gitlab_rails['db_port'] = 6432
    ```

1. [Reconfigure GitLab] for the changes to take effect.

## Node post-configuration

After reconfigure successfully runs, the following steps must be completed to
get the cluster up and running.

### Consul post-configuration

Verify the nodes are all communicating:

```sh
sudo /opt/gitlab/embedded/bin/consul members
```

The output should be similar to:

```
Node         Address              Status  Type    Build  Protocol  DC
NODE_ONE    XXX.XXX.XXX.YYY:8301  alive   server  0.9.2  2         gitlab_cluster
NODE_TWO    XXX.XXX.XXX.YYY:8301  alive   server  0.9.2  2         gitlab_cluster
NODE_THREE  XXX.XXX.XXX.YYY:8301  alive   server  0.9.2  2         gitlab_cluster
```

### Primary database node post-configuration

1. Open a database prompt:

    ```sh
    sudo gitlab-psql -d gitlabhq_production
    ```

1. Enable the `pg_trgm` extension:

    ```sh
    gitlabhq_production=# CREATE EXTENSION pg_trgm;

    # Output:

    CREATE EXTENSION
    ```

1. Exit the database prompt by typing `\q` and Enter.
1. Verify the cluster is initialized with one node:

     ```sh
     sudo gitlab-ctl repmgr cluster show
     ```

     The output should be similar to the following:

     ```
     Role      | Name     | Upstream | Connection String
     ----------+----------|----------|----------------------------------------
     * master  | HOSTNAME |          | host=HOSTNAME user=gitlab_repmgr dbname=gitlab_repmgr
     ```

### Standby nodes post-configuration

1. Setup the repmgr standby:

    ```sh
    sudo gitlab-ctl repmgr standby setup MASTER_NODE
    ```

1. Verify the node now appears in the cluster:

     ```sh
     sudo gitlab-ctl repmgr cluster show
     ```

     The output should be similar to the following:

     ```
     Role      | Name    | Upstream  | Connection String
     ----------+---------|-----------|------------------------------------------------
     * master  | MASTER  |           | host=MASTER_HOSTNAME  user=gitlab_repmgr dbname=gitlab_repmgr
       standby | STANDBY | MASTER    | host=STANDBY_HOSTNAME user=gitlab_repmgr dbname=gitlab_repmgr
     ```

### Pgbouncer node post-configuration

1. Create a `.pgpass` file user for the `CONSUL_USER` account to be able to
   reload pgbouncer. Confirm the password twice when asked:

     ```sh
     sudo gitlab-ctl write-pgpass --host PGBOUNCER_HOST --database pgbouncer --user pgbouncer --hostuser gitlab-consul
     ```

1. Ensure the node is talking to the current master:

     ```sh
     sudo /opt/gitlab/embedded/bin/psql -h 127.0.0.1 -p 6432 -d pgbouncer pgbouncer # You will be prompted for PGBOUNCER_PASSWORD
     ```

     Then run:

     ```sh
     show databases ; show clients ;
     ```

     The output should be similar to the following:

     ```
             name         |  host       | port |      database       | force_user | pool_size | reserve_pool | pool_mode | max_connections | current_connections
     ---------------------+-------------+------+---------------------+------------+-----------+--------------+-----------+-----------------+---------------------
      gitlabhq_production | MASTER_HOST | 5432 | gitlabhq_production |            |        20 |            0 |           |               0 |                   0
      pgbouncer           |             | 6432 | pgbouncer           | pgbouncer  |         2 |            0 | statement |               0 |                   0
     (2 rows)

      type |   user    |      database       |  state  |   addr         | port  | local_addr | local_port |    connect_time     |    request_time     |    ptr    | link | remote_pid | tls
     ------+-----------+---------------------+---------+----------------+-------+------------+------------+---------------------+---------------------+-----------+------+------------+-----
      C    | (nouser)  | gitlabhq_production | waiting | IP_OF_APP_NODE | 56512 | 127.0.0.1  |       6432 | 2017-08-21 18:08:51 | 2017-08-21 18:08:51 | 0x22b3700 |      |          0 |
      C    | pgbouncer | pgbouncer           | active  | 127.0.0.1      | 56846 | 127.0.0.1  |       6432 | 2017-08-21 18:09:59 | 2017-08-21 18:10:48 | 0x22b3880 |      |          0 |
     (2 rows)
     ```

1. It may be necessary to manually run migrations:

     ```sh
     sudo gitlab-rake gitlab:db:configure
     ```

## Ensure GitLab is running

At this point, your GitLab instance should be up and running. Verify you are
able to login, and create issues and merge requests.

## Failover procedure

By default, if the master database fails, `repmgrd` should promote one of the
standby nodes to master automatically, and consul will update pgbouncer with
the new master.

If you need to failover manually, you have two options:

**Shutdown the current master database**

Run:

```sh
sudo gitlab-ctl stop postgresql
```

The automated failover process will see this and failover to one of the
standby nodes.

**Or perform a manual failover**

1. Ensure the old master node is not still active.
1. Login to the server that should become the new master and run:

    ```sh
    sudo gitlab-ctl repmgr standby promote
    ```

1. If there are any other standby servers in the cluster, have them follow
   the new master server:

    ```sh
    sudo gitlab-ctl repmgr standby follow NEW_MASTER
    ```

## Restore procedure

If a node fails, it can be removed from the cluster, or added back as a standby
after it has been restored to service.

- If you want to remove the node from the cluster, on any other node in the
  cluster, run:

    ```sh
    sudo gitlab-ctl repmgr standby unregister --node=X
    ```

    where X is be the value of node in `repmgr.conf` on the old server.

- To add the node as a standby server:

    ```sh
    sudo gitlab-ctl repmgr standby follow NEW_MASTER
    sudo gitlab-ctl restart repmgrd
    ```

    CAUTION: **Warning:** When the server is brought back online, and before
    you switch it to a standby node, repmgr will report that there are two masters.
    If there are any clients that are still attempting to write to the old master,
    this will cause a split, and the old master will need to be resynced from
    scratch by performing a `standby setup NEW_MASTER`.

## Alternate configurations

### Database authorization

By default, we give any host on the database network the permission to perform
repmgr operations using PostgreSQL's `trust` method. If you do not want this
level of trust, there are alternatives.

You can trust only the specific nodes that will be database clusters, or you
can require md5 authentication.

#### Trust specific addresses

If you know the IP address, or FQDN of all database and pgbouncer nodes in the
cluster, you can trust only those nodes.

In `/etc/gitlab/gitlab.rb` on all of the database nodes, set
`repmgr['trust_auth_cidr_addresses']` to an array of strings containing all of
the addresses.

If setting to a node's FQDN, they must have a corresponding PTR record in DNS.
If setting to a node's IP address, specify it as `XXX.XXX.XXX.XXX/32`.

For example:

```ruby
repmgr['trust_auth_cidr_addresses'] = %w(192.168.1.44/32 db2.example.com)
```

#### MD5 Authentication

If you are running on an untrusted network, repmgr can use md5 authentication
with a [.pgpass file](https://www.postgresql.org/docs/9.6/static/libpq-pgpass.html)
to authenticate.

You can specify by IP address, FQDN, or by subnet, using the same format as in
the previous section:

1. On the current master node, create a password for the `gitlab` and
   `gitlab_repmgr` user:

    ```sh
    sudo gitlab-psql -d template1
    template1=# \password gitlab_repmgr
    Enter password: ****
    Confirm password: ****
    template1=# \password gitlab
    ```

1. On each database node:

  1. Edit `/etc/gitlab/gitlab.rb`:
    1. Ensure `repmgr['trust_auth_cidr_addresses']` is **not** set
    1. Set `postgresql['md5_auth_cidr_addresses']` to the desired value
    1. Set `postgresql['sql_replication_user'] = 'gitlab_repmgr'`
    1. Reconfigure with `gitlab-ctl reconfigure`
    1. Restart postgresql with `gitlab-ctl restart postgresql`

  1. Create a `.pgpass` file. Enter the `gitlab_repmgr` password twice to
     when asked:

        ```sh
        sudo gitlab-ctl write-pgpass --user gitlab_repmgr --hostuser gitlab-psql --database '*'
        ```

1. On each pgbouncer node, edit `/etc/gitlab/gitlab.rb`:
  1. Ensure `gitlab_rails['db_password']` is set to the plaintext password for
     the `gitlab` database user
  1. [Reconfigure GitLab] for the changes to take effect

---

Read more on high-availability configuration:

1. [Configure Redis](redis.md)
1. [Configure NFS](nfs.md)
1. [Configure the GitLab application servers](gitlab.md)
1. [Configure the load balancers](load_balancer.md)

[reconfigure GitLab]: ../restart_gitlab.md#omnibus-gitlab-reconfigure
