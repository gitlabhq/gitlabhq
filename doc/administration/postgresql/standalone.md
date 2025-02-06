---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Standalone PostgreSQL for Linux package installations
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

If you wish to have your database service hosted separately from your GitLab
application servers, you can do this using the PostgreSQL binaries packaged
together with the Linux package. This is recommended as part of our
[reference architecture for up to 40 RPS or 2,000 users](../reference_architectures/2k_users.md).

## Setting it up

1. SSH in to the PostgreSQL server.
1. [Download and install](https://about.gitlab.com/install/) the Linux
   package you want using *steps 1 and 2* from the GitLab downloads page. Do not complete any other steps on the
   download page.
1. Generate a password hash for PostgreSQL. This assumes you are using the default
   username of `gitlab` (recommended). The command requests a password
   and confirmation. Use the value that is output by this command in the next
   step as the value of `POSTGRESQL_PASSWORD_HASH`.

   ```shell
   sudo gitlab-ctl pg-password-md5 gitlab
   ```

1. Edit `/etc/gitlab/gitlab.rb` and add the contents below, updating placeholder
   values appropriately.

   - `POSTGRESQL_PASSWORD_HASH` - The value output from the previous step
   - `APPLICATION_SERVER_IP_BLOCKS` - A space delimited list of IP subnets or IP
     addresses of the GitLab application servers that connect to the
     database. Example: `%w(123.123.123.123/32 123.123.123.234/32)`

   ```ruby
   # Disable all components except PostgreSQL
   roles(['postgres_role'])
   prometheus['enable'] = false
   alertmanager['enable'] = false
   pgbouncer_exporter['enable'] = false
   redis_exporter['enable'] = false
   gitlab_exporter['enable'] = false

   postgresql['listen_address'] = '0.0.0.0'
   postgresql['port'] = 5432

   # Replace POSTGRESQL_PASSWORD_HASH with a generated md5 value
   postgresql['sql_user_password'] = 'POSTGRESQL_PASSWORD_HASH'

   # Replace XXX.XXX.XXX.XXX/YY with Network Address
   # ????
   postgresql['trust_auth_cidr_addresses'] = %w(APPLICATION_SERVER_IP_BLOCKS)

   # Disable automatic database migrations
   gitlab_rails['auto_migrate'] = false
   ```

1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.
1. Note the PostgreSQL node's IP address or hostname, port, and
   plain text password. These are necessary when configuring the GitLab
   application servers later.
1. [Enable monitoring](replication_and_failover.md#enable-monitoring)

Advanced configuration options are supported and can be added if
needed.
