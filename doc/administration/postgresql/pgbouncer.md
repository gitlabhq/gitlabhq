---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Working with the bundled PgBouncer service
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

NOTE:
PgBouncer is bundled in the `gitlab-ee` package, but is free to use.
For support, you need a [Premium subscription](https://about.gitlab.com/pricing/).

[PgBouncer](https://www.pgbouncer.org/) is used to seamlessly migrate database
connections between servers in a failover scenario. Additionally, it can be used
in a non-fault-tolerant setup to pool connections, speeding up response time
while reducing resource usage.

GitLab Premium includes a bundled version of PgBouncer that can be managed
through `/etc/gitlab/gitlab.rb`.

## PgBouncer as part of a fault-tolerant GitLab installation

This content has been moved to a [new location](replication_and_failover.md#configure-pgbouncer-nodes).

## PgBouncer as part of a non-fault-tolerant GitLab installation

1. Generate `PGBOUNCER_USER_PASSWORD_HASH` with the command `gitlab-ctl pg-password-md5 pgbouncer`

1. Generate `SQL_USER_PASSWORD_HASH` with the command `gitlab-ctl pg-password-md5 gitlab`. Enter the plaintext SQL_USER_PASSWORD later.

1. On your database node, ensure the following is set in your `/etc/gitlab/gitlab.rb`

   ```ruby
   postgresql['pgbouncer_user_password'] = 'PGBOUNCER_USER_PASSWORD_HASH'
   postgresql['sql_user_password'] = 'SQL_USER_PASSWORD_HASH'
   postgresql['listen_address'] = 'XX.XX.XX.Y' # Where XX.XX.XX.Y is the ip address on the node postgresql should listen on
   postgresql['md5_auth_cidr_addresses'] = %w(AA.AA.AA.B/32) # Where AA.AA.AA.B is the IP address of the pgbouncer node
   ```

1. Run `gitlab-ctl reconfigure`

   NOTE:
   If the database was already running, it needs to be restarted after reconfigure by running `gitlab-ctl restart postgresql`.

1. On the node you are running PgBouncer on, make sure the following is set in `/etc/gitlab/gitlab.rb`

   ```ruby
   pgbouncer['enable'] = true
   pgbouncer['databases'] = {
     gitlabhq_production: {
       host: 'DATABASE_HOST',
       user: 'pgbouncer',
       password: 'PGBOUNCER_USER_PASSWORD_HASH'
     }
   }
   ```

   You can pass additional configuration parameters per database, for example:

   ```ruby
   pgbouncer['databases'] = {
     gitlabhq_production: {
        ...
        pool_mode: 'transaction'
     }
   }
   ```

   Use these parameters with caution. For the complete list of parameters refer to the
   [PgBouncer documentation](https://www.pgbouncer.org/config.html#section-databases).

1. Run `gitlab-ctl reconfigure`

1. On the node running Puma, make sure the following is set in `/etc/gitlab/gitlab.rb`

   ```ruby
   gitlab_rails['db_host'] = 'PGBOUNCER_HOST'
   gitlab_rails['db_port'] = '6432'
   gitlab_rails['db_password'] = 'SQL_USER_PASSWORD'
   ```

1. Run `gitlab-ctl reconfigure`

1. At this point, your instance should connect to the database through PgBouncer. If you are having issues, see the [Troubleshooting](#troubleshooting) section

## Backups

Do not backup or restore GitLab through a PgBouncer connection: it causes a GitLab outage.

[Read more about this and how to reconfigure backups](../backup_restore/backup_gitlab.md#back-up-and-restore-for-installations-using-pgbouncer).

## Enable Monitoring

If you enable Monitoring, it must be enabled on **all** PgBouncer servers.

1. Create/edit `/etc/gitlab/gitlab.rb` and add the following configuration:

   ```ruby
   # Enable service discovery for Prometheus
   consul['enable'] = true
   consul['monitoring_service_discovery'] =  true

   # Replace placeholders
   # Y.Y.Y.Y consul1.gitlab.example.com Z.Z.Z.Z
   # with the addresses of the Consul server nodes
   consul['configuration'] = {
      retry_join: %w(Y.Y.Y.Y consul1.gitlab.example.com Z.Z.Z.Z),
   }

   # Set the network addresses that the exporters will listen on
   node_exporter['listen_address'] = '0.0.0.0:9100'
   pgbouncer_exporter['listen_address'] = '0.0.0.0:9188'
   ```

1. Run `sudo gitlab-ctl reconfigure` to compile the configuration.

## Administrative console

In Linux package installations, a command is provided to automatically connect to the
PgBouncer administrative console. See the
[PgBouncer documentation](https://www.pgbouncer.org/usage.html#admin-console)
for detailed instructions on how to interact with the console.

To start a session run the following and provide the password for the `pgbouncer`
user:

```shell
sudo gitlab-ctl pgb-console
```

To get some basic information about the instance:

```shell
pgbouncer=# show databases; show clients; show servers;
        name         |   host    | port |      database       | force_user | pool_size | reserve_pool | pool_mode | max_connections | current_connections
---------------------+-----------+------+---------------------+------------+-----------+--------------+-----------+-----------------+---------------------
 gitlabhq_production | 127.0.0.1 | 5432 | gitlabhq_production |            |       100 |            5 |           |               0 |                   1
 pgbouncer           |           | 6432 | pgbouncer           | pgbouncer  |         2 |            0 | statement |               0 |                   0
(2 rows)

 type |   user    |      database       | state  |   addr    | port  | local_addr | local_port |    connect_time     |    request_time     |    ptr    | link
| remote_pid | tls
------+-----------+---------------------+--------+-----------+-------+------------+------------+---------------------+---------------------+-----------+------
+------------+-----
 C    | gitlab    | gitlabhq_production | active | 127.0.0.1 | 44590 | 127.0.0.1  |       6432 | 2018-04-24 22:13:10 | 2018-04-24 22:17:10 | 0x12444c0 |
|          0 |
 C    | gitlab    | gitlabhq_production | active | 127.0.0.1 | 44592 | 127.0.0.1  |       6432 | 2018-04-24 22:13:10 | 2018-04-24 22:17:10 | 0x12447c0 |
|          0 |
 C    | gitlab    | gitlabhq_production | active | 127.0.0.1 | 44594 | 127.0.0.1  |       6432 | 2018-04-24 22:13:10 | 2018-04-24 22:17:10 | 0x1244940 |
|          0 |
 C    | gitlab    | gitlabhq_production | active | 127.0.0.1 | 44706 | 127.0.0.1  |       6432 | 2018-04-24 22:14:22 | 2018-04-24 22:16:31 | 0x1244ac0 |
|          0 |
 C    | gitlab    | gitlabhq_production | active | 127.0.0.1 | 44708 | 127.0.0.1  |       6432 | 2018-04-24 22:14:22 | 2018-04-24 22:15:15 | 0x1244c40 |
|          0 |
 C    | gitlab    | gitlabhq_production | active | 127.0.0.1 | 44794 | 127.0.0.1  |       6432 | 2018-04-24 22:15:15 | 2018-04-24 22:15:15 | 0x1244dc0 |
|          0 |
 C    | gitlab    | gitlabhq_production | active | 127.0.0.1 | 44798 | 127.0.0.1  |       6432 | 2018-04-24 22:15:15 | 2018-04-24 22:16:31 | 0x1244f40 |
|          0 |
 C    | pgbouncer | pgbouncer           | active | 127.0.0.1 | 44660 | 127.0.0.1  |       6432 | 2018-04-24 22:13:51 | 2018-04-24 22:17:12 | 0x1244640 |
|          0 |
(8 rows)

 type |  user  |      database       | state |   addr    | port | local_addr | local_port |    connect_time     |    request_time     |    ptr    | link | rem
ote_pid | tls
------+--------+---------------------+-------+-----------+------+------------+------------+---------------------+---------------------+-----------+------+----
--------+-----
 S    | gitlab | gitlabhq_production | idle  | 127.0.0.1 | 5432 | 127.0.0.1  |      35646 | 2018-04-24 22:15:15 | 2018-04-24 22:17:10 | 0x124dca0 |      |
  19980 |
(1 row)
```

## Procedure for bypassing PgBouncer

### Linux package installations

Some database changes have to be done directly, and not through PgBouncer.

The main affected tasks are [database restores](../backup_restore/backup_gitlab.md#back-up-and-restore-for-installations-using-pgbouncer)
and [GitLab upgrades with database migrations](../../update/zero_downtime.md).

1. To find the primary node, run the following on a database node:

   ```shell
   sudo gitlab-ctl patroni members
   ```

1. Edit `/etc/gitlab/gitlab.rb` on the application node you're performing the task on, and update
   `gitlab_rails['db_host']` and `gitlab_rails['db_port']` with the database
   primary's host and port.

1. Run reconfigure:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

After you've performed the tasks or procedure, switch back to using PgBouncer:

1. Change back `/etc/gitlab/gitlab.rb` to point to PgBouncer.
1. Run reconfigure:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### Helm chart installations

High-availability deployments also need to bypass PgBouncer for the same reasons as Linux package-based ones.
For Helm chart installations:

- Database backup and restore tasks are performed by the toolbox container.
- Migration tasks are performed by the migrations container.

You should override the PostgreSQL port on each subchart, so these tasks can execute and connect to PostgreSQL directly:

- [Toolbox](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/charts/gitlab/charts/toolbox/values.yaml#L40)
- [Migrations](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/charts/gitlab/charts/migrations/values.yaml#L46)

## Fine tuning

PgBouncer's default settings suit the majority of installations.
In specific cases you may want to change the performance-specific and resource-specific variables to either increase possible
throughput or to limit resource utilization that could cause memory exhaustion on the database.

You can find the parameters and respective documentation on the [official PgBouncer documentation](https://www.pgbouncer.org/config.html).
Listed below are the most relevant ones and their defaults on a Linux package installation:

- `pgbouncer['max_client_conn']` (default: `2048`, depends on server file descriptor limits)
  This is the "frontend" pool in PgBouncer: connections from Rails to PgBouncer.
- `pgbouncer['default_pool_size']` (default: `100`)
  This is the "backend" pool in PgBouncer: connections from PgBouncer to the database.

The ideal number for `default_pool_size` must be enough to handle all provisioned services that need to access
the database. Each of the listed services below use the following formula to define database pool size:

- `puma` : `max_threads + headroom` (default `14`)
  - `max_threads` is configured via: `gitlab['puma']['max_threads']` (default: `4`)
  - `headroom` can be configured via `DB_POOL_HEADROOM` environment variable (default to `10`)
- `sidekiq` : `max_concurrency + 1 + headroom` (default: `31`)
  - `max_concurrency` is configured via: `sidekiq['max_concurrency']` (default: `20`)
  - `headroom` can be configured via `DB_POOL_HEADROOM` environment variable (default to `10`)
- `geo-logcursor`: `1+headroom` (default: `11`)
  - `headroom` can be configured via `DB_POOL_HEADROOM` environment variable (default to `10`)

To calculate the `default_pool_size`, multiply the number of instances of `puma`, `sidekiq` and `geo-logcursor` by the
number of connections each can consume as per listed above. The total is the suggested `default_pool_size`.

If you are using more than one PgBouncer with an internal Load Balancer, you may be able to divide the
`default_pool_size` by the number of instances to guarantee an evenly distributed load between them.

The `pgbouncer['max_client_conn']` is the hard limit of connections PgBouncer can accept. It's unlikely you need
to change this. If you are hitting that limit, you may want to consider adding additional PgBouncers with an internal
Load Balancer.

When setting up the limits for a PgBouncer that points to the Geo Tracking Database,
you can likely ignore `puma` from the equation, as it is only accessing that database sporadically.

## Troubleshooting

In case you are experiencing any issues connecting through PgBouncer, the first
place to check is always the logs:

```shell
sudo gitlab-ctl tail pgbouncer
```

Additionally, you can check the output from `show databases` in the
[administrative console](#administrative-console). In the output, you would expect
to see values in the `host` field for the `gitlabhq_production` database.
Additionally, `current_connections` should be greater than 1.

### Message: `LOG:  invalid CIDR mask in address`

See the suggested fix [in Geo documentation](../geo/replication/troubleshooting/postgresql_replication.md#message-log--invalid-cidr-mask-in-address).

### Message: `LOG:  invalid IP mask "md5": Name or service not known`

See the suggested fix [in Geo documentation](../geo/replication/troubleshooting/postgresql_replication.md#message-log--invalid-ip-mask-md5-name-or-service-not-known).
