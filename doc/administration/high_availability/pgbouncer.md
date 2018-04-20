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

1. Generate SQL_USER_PASSWORD_HASH with the command `gitlab-ctl pg-password-md5 gitlab. We'll also need to enter the plaintext SQL_USER_PASSWORD later

1. On your database node, ensure the following is set in your `/etc/gitlab/gitlab.rb`
   ```ruby
   postgresql['pgbouncer_user_password'] = 'PGBOUNCER_USER_PASSWORD_HASH'
   postgresql['sql_user_password'] = 'SQL_USER_PASSWORD_HASH'
   postgresql['listen_address'] = 'XX.XX.XX.Y' # Where XX.XX.XX.Y is the ip address on the node postgresql should listen on
   postgresql['md5_auth_cidr_addresses'] = %w(AA.AA.AA.B/32) # Where AA.AA.AA.B is the IP address of the pgbouncer node
   ```

1. Run `gitlab-ctl reconfigure`

1. On the node you are running pgbouncer on, make sure the following is set in `/etc/gitlab/gitlab.rb`

   ```ruby
   pgbouncer['enable'] = true
   pgbouncer['user'] = {
     'pgbouncer': {
       'password': 'PGBOUNCER_USER_PASSWORD_HASH'
     }
   }
   pgbouncer['databases'] = {
     gitlabhq_production: {
       host: 'DATABASE_HOST'
     }
   }
   ```

1. Run `gitlab-ctl reconfigure`

1. On the node running unicorn, make sure the following is seti in `/etc/gitlab/gitlab.rb`

   ```ruby
   gitlab_rails['db_host'] = 'PGBOUNCER_HOST'
   gitlab_rails['db_password'] = 'SQL_USER_PASSWORD'
   ```

1. Run `gitlab-ctl reconfigure`

1. At this point, your instance should connect to the database through pgbouncer. If you are having issues, see the [Troubleshooting]() section

### Interacting with pgbouncer

## Troubleshooting

### Debugging connection issues

