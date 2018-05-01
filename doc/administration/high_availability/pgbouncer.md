# Working with the bundle Pgbouncer service

## Overview

As part of its High Availability stack, GitLab Premium includes a bundled version of [Pgbouncer](https://pgbouncer.github.io/) that can be managed through `/etc/gitlab/gitlab.rb`.

In a High Availability setup, Pgbounce is used to seamlessly migrate database connections between servers in a failover scenario.

Additionally, it can be used in a non-HA setup to pool connections, speeding up response time while reducing resource usage.

It is recommended to run pgbouncer alongside the `gitlab-rails` service, or on its own dedicated node in a cluster.

## Operations

### Running Pgbouncer as part of an HA GitLab installation
See our [HA documentation for PostgreSQL](database.md) for information on running pgbouncer as part of a HA setup

### Running Pgbouncer as part of a non-HA GitLab installation

1. Generate PGBOUNCER_USER_PASSWORD_HASH with the command `gitlab-ctl pg-password-md5 pgbouncer`

1. Generate SQL_USER_PASSWORD_HASH with the command `gitlab-ctl pg-password-md5 gitlab`. We'll also need to enter the plaintext SQL_USER_PASSWORD later

1. On your database node, ensure the following is set in your `/etc/gitlab/gitlab.rb`
   ```ruby
   postgresql['pgbouncer_user_password'] = 'PGBOUNCER_USER_PASSWORD_HASH'
   postgresql['sql_user_password'] = 'SQL_USER_PASSWORD_HASH'
   postgresql['listen_address'] = 'XX.XX.XX.Y' # Where XX.XX.XX.Y is the ip address on the node postgresql should listen on
   postgresql['md5_auth_cidr_addresses'] = %w(AA.AA.AA.B/32) # Where AA.AA.AA.B is the IP address of the pgbouncer node
   ```

1. Run `gitlab-ctl reconfigure`
   **Note:** If the database was already running, it will need to be restarted after reconfigure by running `gitlab-ctl restart postgresql`.

1. On the node you are running pgbouncer on, make sure the following is set in `/etc/gitlab/gitlab.rb`

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

1. Run `gitlab-ctl reconfigure`

1. On the node running unicorn, make sure the following is set in `/etc/gitlab/gitlab.rb`

   ```ruby
   gitlab_rails['db_host'] = 'PGBOUNCER_HOST'
   gitlab_rails['db_port'] = '6432'
   gitlab_rails['db_password'] = 'SQL_USER_PASSWORD'
   ```

1. Run `gitlab-ctl reconfigure`

1. At this point, your instance should connect to the database through pgbouncer. If you are having issues, see the [Troubleshooting](#troubleshooting) section

### Interacting with pgbouncer

#### Administrative console

As part of omnibus-gitlab, we provide a command `gitlab-ctl pgb-console` to automatically connect to the pgbouncer administrative console. Please see the [pgbouncer documentation](https://pgbouncer.github.io/usage.html#admin-console) for detailed instructions on how to interact with the console.

To start a session, run

```shell
# gitlab-ctl pgb-console
Password for user pgbouncer:
psql (9.6.8, server 1.7.2/bouncer)
Type "help" for help.

pgbouncer=#
```

The password you will be prompted for is the PGBOUNCER_USER_PASSWORD

To get some basic information about the instance, run
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

## Troubleshooting

In case you are experiencing any issues connecting through pgbouncer, the first place to check is always the logs:

```shell
# gitlab-ctl tail pgbouncer
```

Additionally, you can check the output from `show databases` in the [Administrative console](#administrative-console). In the output, you would expect to see values in the `host` field for the `gitlabhq_production` database. Additionally, `current_connections` should be greater than 1.
