# Configuring a Database for GitLab HA

There are multiple ways in which you can achieve Database High Availability
for use with GitLab:

* Use bundled services and configuration provided by the Omnibus GitLab package.
This option is available with [Enterprise Edition Premium](https://about.gitlab.com/gitlab-ee/) license.
* Use a cloud hosted solution
* Install and manage the database and other components yourself

> Important notes:
- Please read [database requirements document](https://docs.gitlab.com/ee/install/requirements.html#database) for more information on supported databases.
- This document will focus only on configuration supported with [GitLab Enterprise Edition Premium](https://about.gitlab.com/gitlab-ee/), using the Omnibus GitLab package.
- If you are a Community Edition or Enterprise Edition Starter user, consider using a cloud hosted solution.
- This document will not cover installations from source.

>
- If HA setup is not what you were looking for,  see the [database configuration document](http://docs.gitlab.com/omnibus/settings/database.html)
for the Omnibus GitLab packages.

## Overview

>
Please read this document fully before attempting to configure PostgreSQL HA
for GitLab.

The recommended configuration for a PostgreSQL HA requires:

- A minimum of three database nodes
  - Each node will run the following services:
    - `PostgreSQL` - The database itself
    - `repmgrd` - A service to monitor, and handle failover in case of a failure
    - `Consul` agent - Used for service discovery, to alert other nodes when failover occurs
- A minimum of three `Consul` server nodes
- A minimum of one `pgbouncer` service node

You also need to take into consideration the underlying network topology,
making sure you have redundant connectivity between all Database and GitLab instances,
otherwise the networks will become a single point of failure.

## Required information

Before proceeding with configuration, you will need to collect all the necessary
information.

### Network information

PostgreSQL does not listen on any network interface by default. It needs to know
which IP address to listen on in order to be accessible to other services.
Similarly, PostgreSQL access is controlled based on the network source.

This is why you will need:

> IP address of each nodes network interface
- This can be set to `0.0.0.0` to listen on all interfaces. It cannot
  be set to the loopack address `127.0.0.1`

> Network Address
- This can be in subnet (i.e. `192.168.0.0/255.255.255.0`) or CIDR (i.e.
  `192.168.0.0/24`) form.

### User information

Various services require different configuration to secure
the communication as well as information required for running the service.
Bellow you will find details on each service and the minimum required
information you need to provide.

#### Consul

When using default setup, minimum configuration requires:

- `CONSUL_DATABASE_PASSWORD`. Password for the database user.
- `CONSUL_PASSWORD_HASH`. This is a hash generated out of consul username/password pair.
Can be generated with:
    ```sh
    echo -n 'CONSUL_DATABASE_PASSWORDCONSUL_USERNAME' | md5sum
    ```
- You'll also need to supply the IP addresses or DNS records of Consul
server nodes.

Few notes on the service itself:

- The service runs under a system account, by default `gitlab-consul`.
  - If you are using a different username, you will have to specify it. We
will refer to it with `CONSUL_USERNAME`,
- There will be a database user created with read only access to the repmgr
database
- Passwords will be stored in the following locations:
  - `/etc/gitlab/gitlab.rb`: hashed
  - `/var/opt/gitlab/pgbouncer/pg_auth`: hashed
  - `/var/opt/gitlab/gitlab-consul/.pgpass`: plaintext

#### PostgreSQL

When configuring PostgreSQL, we will set `max_wal_senders` to one more than
the number of database nodes in the cluster.
This is used to prevent replication from using up all of the
available database connections.

> Note:
- In this document we are assuming 3 database nodes, which makes this configuration:

```
postgresql['max_wal_senders'] = 4
```

As previously mentioned, you'll have to prepare the network subnets that will
be allowed to authenticate with the database.
You'll also need to supply the IP addresses or DNS records of Consul
server nodes.

#### Pgbouncer

When using default setup, minimum configuration requires:

- `PGBOUNCER_PASSWORD`. This is a password for pgbouncer service.
- `PGBOUNCER_PASSWORD_HASH`. This is a hash generated out of pgbouncer username/password pair.
Can be generated with:
    ```sh
    echo -n 'PGBOUNCER_PASSWORDPGBOUNCER_USERNAME' | md5sum
    ```
- `PGBOUNCER_NODE`, is the IP address or a FQDN of the node running Pgbouncer.

Few notes on the service itself:

- The service runs as the same system account as the database
  - In the package, this is by default `gitlab-psql`
- If you use a non-default user account for Pgbouncer service (by default `pgbouncer`), you will have to specify this username. We will refer to this requirement with `PGBOUNCER_USERNAME`.
- The service will have a regular database user account generated for it
  - This defaults to `repmgr`
- Passwords will be stored in the following locations:
  - `/etc/gitlab/gitlab.rb`: hashed, and in plain text
  - `/var/opt/gitlab/pgbouncer/pg_auth`: hashed

#### Repmgr

When using default setup, you will only have to prepare the network subnets that will
be allowed to authenticate with the service.

Few notes on the service itself:

- The service runs under the same system account as the database
  -  In the package, this is by default `gitlab-psql`
- The service will have a superuser database user account generated for it
  - This defaults to `gitlab_repmgr`

## Installing Omnibus GitLab

First, make sure to [download/install](https://about.gitlab.com/installation)
GitLab Omnibus **on each node**.

Make sure you install the necessary dependencies from step 1,
add GitLab package repository from step 2.
When installing the GitLab package, do not supply `EXTERNAL_URL` value.

## Initial node configuration

Each node needs to be configured to run only the services it needs.

### Consul nodes

On each Consul node perform the following:

1. Make sure you collect all required information before executing the next step.
See `START user configuration` section in the next step for required information.
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
    prometheus['enable'] = false
    unicorn['enable'] = false

    consul['enable'] = true
    # START user configuration
    # Replace placeholders:
    #
    # Y.Y.Y.Y consul1.gitlab.example.com Z.Z.Z.Z
    # with real information.
    consul['configuration'] = {
      server: true,
      retry_join: %w(Y.Y.Y.Y consul1.gitlab.example.com Z.Z.Z.Z)
    }
    #
    # END user configuration
    ```

1. [Reconfigure GitLab] for the changes to take effect.

After this is completed on each Consul server node, proceed further.

### Database nodes

On each database node perform the following:

1. Make sure you collect all required information before executing the next step.
See `START user configuration` section in the next step for required information.
1. Edit `/etc/gitlab/gitlab.rb`:

    ```ruby
    # Disable all components except PostgreSQL and Repmgr and Consul
    bootstrap['enable'] = false
    gitaly['enable'] = false
    mailroom['enable'] = false
    nginx['enable'] = false
    unicorn['enable'] = false
    sidekiq['enable'] = false
    redis['enable'] = false
    gitlab_workhorse['enable'] = false
    mailroom['enable'] = false
    prometheus['enable'] = false

    repmgr['enable'] = true
    postgresql['enable'] = true
    consul['enable'] = true

    # PostgreSQL configuration
    postgresql['listen_address'] = '0.0.0.0'
    postgresql['hot_standby'] = 'on'
    postgresql['wal_level'] = 'replica'
    postgresql['shared_preload_libraries'] = 'repmgr_funcs'

    # Disable automatic database migrations
    gitlab_rails['auto_migrate'] = false

    # Configure the consul agent
    consul['services'] = %w(postgresql)

    # START user configuration
    # Please set the real values as explained in Required Information section
    #
    # Replace PGBOUNCER_PASSWORD_HASH with a generated md5 value
    postgresql['pgbouncer_user_password'] = 'PGBOUNCER_PASSWORD_HASH'
    # Replace X with value of number of db nodes + 1
    postgresql['max_wal_senders'] = X

    # Replace XXX.XXX.XXX.XXX/YY with Network Address
    postgresql['trust_auth_cidr_addresses'] = %w(XXX.XXX.XXX.XXX/YY)
    repmgr['trust_auth_cidr_addresses'] = %w(XXX.XXX.XXX.XXX/YY)

    # Replace placeholders:
    #
    # Y.Y.Y.Y consul1.gitlab.example.com Z.Z.Z.Z
    # with real information.
    consul['configuration'] = {
      retry_join: %w(Y.Y.Y.Y consul1.gitlab.example.com Z.Z.Z.Z)
    }
    #
    # END user configuration
    ```

1. [Reconfigure GitLab] for the changes to take effect.

> Please note:
- If you want your database to listen on a specific interface, change the config:
`postgresql['listen_address'] = '0.0.0.0'`
- If your Pgbouncer service runs under a different user account,
you also need to specify: `postgresql['pgbouncer_user'] = PGBOUNCER_USERNAME` in
your configuration
`

### Configuring the Pgbouncer node

1. Edit `/etc/gitlab/gitlab.rb`:

    ```ruby
    # Disable all components except Pgbouncer and Consul agent
    bootstrap['enable'] = false
    gitaly['enable'] = false
    mailroom['enable'] = false
    nginx['enable'] = false
    redis['enable'] = false
    prometheus['enable'] = false
    postgresql['enable'] = false
    unicorn['enable'] = false
    sidekiq['enable'] = false
    gitlab_workhorse['enable'] = false

    pgbouncer['enable'] = true
    consul['enable'] = true

    # Configure Pgbouncer
    pgbouncer['admin_users'] = %w(pgbouncer gitlab-consul)

    # Configure Consul agent
    consul['watchers'] = %w(postgresql)

    # START user configuration
    # Please set the real values as explained in Required Information section
    # Replace CONSUL_PASSWORD_HASH with with a generated md5 value
    # Replace PGBOUNCER_PASSWORD_HASH with with a generated md5 value
    pgbouncer['users'] = {
      'gitlab-consul': {
        password: 'CONSUL_PASSWORD_HASH'
      },
      'pgbouncer': {
        password: 'PGBOUNCER_PASSWORD_HASH'
      }
    }
    # Replace placeholders:
    #
    # Y.Y.Y.Y consul1.gitlab.example.com Z.Z.Z.Z
    # with real information.
    consul['configuration'] = {
      retry_join: %w(Y.Y.Y.Y consul1.gitlab.example.com Z.Z.Z.Z)
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
    # Disable PostgreSQL on the application node
    postgresql['enable'] = false

    gitlab_rails['db_host'] = 'PGBOUNCER_NODE'
    gitlab_rails['db_port'] = 6432
    ```

1. [Reconfigure GitLab] for the changes to take effect.

## Node post-configuration

After reconfigure successfully runs, the following steps must be completed to
get the cluster up and running.

### Consul

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

### Database nodes

#### Primary node

Select one node as a primary node.

1. Open a database prompt:

    ```sh
    sudo gitlab-psql -d gitlabhq_production
    ```

1. Enable the `pg_trgm` extension:

    ```sh
    CREATE EXTENSION pg_trgm;
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
1. Note down the value in the `Name` column. We will refer to it in the next section
as `MASTER_NODE_NAME`.

#### Secondary nodes

1. Setup the repmgr standby:

    ```sh
    sudo gitlab-ctl repmgr standby setup MASTER_NODE_NAME
    ```
    Do note that this will remove the existing data on the node. The command
    has a wait time.

1. Verify the node now appears in the cluster:

     ```sh
     sudo gitlab-ctl repmgr cluster show
     ```

     The output should be similar to the following:

     ```
     Role      | Name    | Upstream  | Connection String
     ----------+---------|-----------|------------------------------------------------
     * master  | MASTER  |           | host=MASTER_NODE_NAME user=gitlab_repmgr dbname=gitlab_repmgr
       standby | STANDBY | MASTER    | host=STANDBY_HOSTNAME user=gitlab_repmgr dbname=gitlab_repmgr
     ```

Repeat the above steps on all secondary nodes.

### Pgbouncer node

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

### Application node

Ensure that all migrations ran:

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
1. [Manage the bundled Consul cluster](consul.md)

[reconfigure GitLab]: ../restart_gitlab.md#omnibus-gitlab-reconfigure
