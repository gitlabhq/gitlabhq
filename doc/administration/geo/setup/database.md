---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Geo database replication
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

This document describes the minimal required steps to replicate your primary
GitLab database to a secondary site's database. You may have to change some
values, based on attributes including your database's setup and size.

{{< alert type="note" >}}

If your GitLab installation uses external PostgreSQL instances (not managed by a Linux package installation),
the roles cannot perform all necessary configuration steps. In this case, use the
[Geo with external PostgreSQL instances](external_database.md) process instead.

{{< /alert >}}

{{< alert type="note" >}}

The stages of the setup process must be completed in the documented order.
If not, [complete all prior stages](_index.md#using-linux-package-installations) before proceeding.
{{< /alert >}}

Ensure the **secondary** site is running the same version of GitLab Enterprise Edition as the **primary** site. Confirm you have added a license for a [Premium or Ultimate subscription](https://about.gitlab.com/pricing/) to your **primary** site.

Be sure to read and review all of these steps before you execute them in your
testing or production environments.

## Single instance database replication

A single instance database replication is easier to set up and still provides the same Geo capabilities
as a clustered alternative. It's useful for setups running on a single machine
or trying to evaluate Geo for a future clustered installation.

A single instance can be expanded to a clustered version using Patroni, which is recommended for a
highly available architecture.

Follow the instructions below on how to set up PostgreSQL replication as a single instance database.
Alternatively, you can look at the [Multi-node database replication](#multi-node-database-replication)
instructions on setting up replication with a Patroni cluster.

### PostgreSQL replication

The GitLab **primary** site where the write operations happen connects to
the **primary** database server. **Secondary** sites
connect to their own database servers (which are read-only).

You should use [PostgreSQL's replication slots](https://medium.com/@tk512/replication-slots-in-postgresql-b4b03d277c75)
to ensure that the **primary** site retains all the data necessary for the **secondary** sites to
recover. See below for more details.

The following guide assumes that:

- You are using the Linux package (so are using PostgreSQL 12 or later),
  which includes the [`pg_basebackup` tool](https://www.postgresql.org/docs/16/app-pgbasebackup.html).
- You have a **primary** site already set up (the GitLab server you are
  replicating from), running PostgreSQL (or equivalent version) managed by your Linux package installation, and
  you have a new **secondary** site set up with the same
  [versions of PostgreSQL](../_index.md#requirements-for-running-geo),
  OS, and GitLab on all sites.

{{< alert type="warning" >}}

Geo works with streaming replication. Logical replication is not supported at this time.
There is an [issue where support is being discussed](https://gitlab.com/gitlab-org/gitlab/-/issues/7420).

{{< /alert >}}

#### Step 1. Configure the **primary** site

1. SSH into your GitLab **primary** site and sign in as root:

   ```shell
   sudo -i
   ```

1. [Opt out of automatic PostgreSQL upgrades](https://docs.gitlab.com/omnibus/settings/database/#opt-out-of-automatic-postgresql-upgrades) to avoid unintended downtime when upgrading GitLab. Be aware of the known [caveats when upgrading PostgreSQL with Geo](https://docs.gitlab.com/omnibus/settings/database/#caveats-when-upgrading-postgresql-with-geo). Especially for larger environments, PostgreSQL upgrades must be planned and executed consciously. As a result and going forward, ensure PostgreSQL upgrades are part of the regular maintenance activities.

1. Edit `/etc/gitlab/gitlab.rb` and add a **unique** name for your site:

   ```ruby
   ##
   ## The unique identifier for the Geo site. See
   ## https://docs.gitlab.com/ee/administration/geo_sites.html#common-settings
   ##
   gitlab_rails['geo_node_name'] = '<site_name_here>'
   ```

1. Reconfigure the **primary** site for the change to take effect:

   ```shell
   gitlab-ctl reconfigure
   ```

1. Execute the command below to define the site as **primary** site:

   ```shell
   gitlab-ctl set-geo-primary-node
   ```

   This command uses your defined `external_url` in `/etc/gitlab/gitlab.rb`.

1. Define a password for the `gitlab` database user:

   Generate a MD5 hash of the desired password:

   ```shell
   gitlab-ctl pg-password-md5 gitlab
   # Enter password: <your_db_password_here>
   # Confirm password: <your_db_password_here>
   # fca0b89a972d69f00eb3ec98a5838484
   ```

   Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   # Fill with the hash generated by `gitlab-ctl pg-password-md5 gitlab`
   postgresql['sql_user_password'] = '<md5_hash_of_your_db_password>'

   # Every node that runs Puma or Sidekiq needs to have the database
   # password specified as below. If you have a high-availability setup, this
   # must be present in all application nodes.
   gitlab_rails['db_password'] = '<your_db_password_here>'
   ```

1. Define a password for the database [replication user](https://www.postgresql.org/docs/16/warm-standby.html#STREAMING-REPLICATION).

   Use the username defined in `/etc/gitlab/gitlab.rb` under the `postgresql['sql_replication_user']`
   setting. The default value is `gitlab_replicator`. If you changed the username to something else, adapt
   the instructions below.

   Generate a MD5 hash of the desired password:

   ```shell
   gitlab-ctl pg-password-md5 gitlab_replicator
   # Enter password: <your_replication_password_here>
   # Confirm password: <your_replication_password_here>
   # 950233c0dfc2f39c64cf30457c3b7f1e
   ```

   Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   # Fill with the hash generated by `gitlab-ctl pg-password-md5 gitlab_replicator`
   postgresql['sql_replication_password'] = '<md5_hash_of_your_replication_password>'
   ```

   If you are using an external database not managed by your Linux package installation, you need
   to create the `gitlab_replicator` user and define a password for that user manually:

   ```sql
   --- Create a new user 'replicator'
   CREATE USER gitlab_replicator;

   --- Set/change a password and grants replication privilege
   ALTER USER gitlab_replicator WITH REPLICATION ENCRYPTED PASSWORD '<replication_password>';
   ```

1. Edit `/etc/gitlab/gitlab.rb` and set the role to `geo_primary_role` (for more information, see [Geo roles](https://docs.gitlab.com/omnibus/roles/#gitlab-geo-roles)):

   ```ruby
   ## Geo Primary role
   roles(['geo_primary_role'])
   ```

1. Configure PostgreSQL to listen on network interfaces:

   For security reasons, PostgreSQL does not listen on any network interfaces
   by default. However, Geo requires the **secondary** site to be able to
   connect to the **primary** site's database. For this reason, you need the IP address of
   each site.

   {{< alert type="note" >}}

   For external PostgreSQL instances, see [additional instructions](external_database.md).

   {{< /alert >}}

   If you are using a cloud provider, you can look up the addresses for each
   Geo site through your cloud provider's management console.

   To look up the address of a Geo site, SSH into the Geo site and execute:

   ```shell
   ##
   ## Private address
   ##
   ip route get 255.255.255.255 | awk '{print "Private address:", $NF; exit}'

   ##
   ## Public address
   ##
   echo "External address: $(curl --silent "ipinfo.io/ip")"
   ```

   In most cases, the following addresses are used to configure GitLab
   Geo:

   | Configuration                           | Address                                                               |
   |:----------------------------------------|:----------------------------------------------------------------------|
   | `postgresql['listen_address']`          | **Primary** site's public or VPC private address.                     |
   | `postgresql['md5_auth_cidr_addresses']` | **Primary** and **Secondary** sites' public or VPC private addresses. |

   If you are using Google Cloud Platform, SoftLayer, or any other vendor that
   provides a virtual private cloud (VPC), we recommend using the **primary**
   and **secondary** sites' "private" or "internal" addresses for
   `postgresql['md5_auth_cidr_addresses']` and `postgresql['listen_address']`.

   The `listen_address` option opens PostgreSQL up to network connections with the interface
   corresponding to the given address. See [the PostgreSQL documentation](https://www.postgresql.org/docs/16/runtime-config-connection.html)
   for more details.

   {{< alert type="note" >}}

   If you need to use `0.0.0.0` or `*` as the `listen_address`, you also must add
   `127.0.0.1/32` to the `postgresql['md5_auth_cidr_addresses']` setting, to allow Rails to connect through
   `127.0.0.1`. For more information, see [issue 5258](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5258).

   {{< /alert >}}

   Depending on your network configuration, the suggested addresses may
   be incorrect. If your **primary** and **secondary** sites connect over a local
   area network, or a virtual network connecting availability zones like the
   [Amazon VPC](https://aws.amazon.com/vpc/) or the [Google VPC](https://cloud.google.com/vpc/),
   you should use the **secondary** site's private address for `postgresql['md5_auth_cidr_addresses']`.

   Edit `/etc/gitlab/gitlab.rb` and add the following, replacing the IP
   addresses with addresses appropriate to your network configuration:

   ```ruby
   ##
   ## Primary address
   ## - replace '<primary_node_ip>' with the public or VPC address of your Geo primary node
   ##
   postgresql['listen_address'] = '<primary_site_ip>'

   ##
   # Allow PostgreSQL client authentication from the primary and secondary IPs. These IPs may be
   # public or VPC addresses in CIDR format, for example ['198.51.100.1/32', '198.51.100.2/32']
   ##
   postgresql['md5_auth_cidr_addresses'] = ['<primary_site_ip>/32', '<secondary_site_ip>/32']

   ##
   ## Replication settings
   ##
   # postgresql['max_replication_slots'] = 1 # Set this to be the number of Geo secondary nodes if you have more than one
   # postgresql['max_wal_senders'] = 10
   # postgresql['wal_keep_segments'] = 10
   ```

1. Disable automatic database migrations temporarily until PostgreSQL is restarted and listening on the private address.
   Edit `/etc/gitlab/gitlab.rb` and change the configuration to false:

   ```ruby
   ## Disable automatic database migrations
   gitlab_rails['auto_migrate'] = false
   ```

1. Optional: If you want to add another **secondary** site, the relevant setting would look like:

   ```ruby
   postgresql['md5_auth_cidr_addresses'] = ['<primary_site_ip>/32', '<secondary_site_ip>/32', '<another_secondary_site_ip>/32']
   ```

   You may also want to edit the `wal_keep_segments` and `max_wal_senders` to match your
   database replication requirements. Consult the [PostgreSQL - Replication documentation](https://www.postgresql.org/docs/16/runtime-config-replication.html)
   for more information.

1. Save the file and reconfigure GitLab for the database listen changes and
   the replication slot changes to be applied:

   ```shell
   gitlab-ctl reconfigure
   ```

   Restart PostgreSQL for its changes to take effect:

   ```shell
   gitlab-ctl restart postgresql
   ```

1. Re-enable migrations now that PostgreSQL is restarted and listening on the
   private address.

   Edit `/etc/gitlab/gitlab.rb` and **change** the configuration to `true`:

   ```ruby
   gitlab_rails['auto_migrate'] = true
   ```

   Save the file and reconfigure GitLab:

   ```shell
   gitlab-ctl reconfigure
   ```

1. Now that the PostgreSQL server is set up to accept remote connections, run
   `netstat -plnt | grep 5432` to ensure that PostgreSQL is listening on port
   `5432` to the **primary** site's private address.

1. A certificate was automatically generated when GitLab was reconfigured. This
   is used automatically to protect your PostgreSQL traffic from
   eavesdroppers. To protect against active ("man-in-the-middle") attackers,
   the **secondary** site needs a copy of the CA that signed the certificate. In
   the case of this self-signed certificate, make a copy of the PostgreSQL
   `server.crt` file on the **primary** site by running this command:

   ```shell
   cat ~gitlab-psql/data/server.crt
   ```

   Copy the output to the clipboard or into a local file. You
   need it when setting up the **secondary** site! The certificate is not sensitive
   data.

   However, this certificate is created with a generic `PostgreSQL` Common Name. For this,
   you must use the `verify-ca` mode when replicating the database, otherwise,
   the hostname mismatch causes errors.

1. Optional. Generate your own SSL certificate and manually
   [configure SSL for PostgreSQL](https://docs.gitlab.com/omnibus/settings/database.html#configuring-ssl),
   instead of using the generated certificate.

   You need at least the SSL certificate and key. Set the `postgresql['ssl_cert_file']` and
   `postgresql['ssl_key_file']` values to their full paths, as per the Database SSL docs.

   This allows you to use the `verify-full` SSL mode when replicating the database
   and get the extra benefit of verifying the full hostname in the CN.

   Going forward, you can use this certificate (that you have also set in `postgresql['ssl_cert_file']`) instead
   of the self-signed certificate automatically generated previously. This allows you to use `verify-full`
   without replication errors if the CN matches.

   On your primary database, open `/etc/gitlab/gitlab.rb` and search for `postgresql['ssl_ca_file']` (the CA certificate). Copy its value to your clipboard that you'll later paste into `server.crt`.

#### Step 2. Configure the **secondary** server

1. SSH into your GitLab **secondary** site and sign in as root:

   ```shell
   sudo -i
   ```

1. [Opt out of automatic PostgreSQL upgrades](https://docs.gitlab.com/omnibus/settings/database/#opt-out-of-automatic-postgresql-upgrades) to avoid unintended downtime when upgrading GitLab. Be aware of the known [caveats when upgrading PostgreSQL with Geo](https://docs.gitlab.com/omnibus/settings/database/#caveats-when-upgrading-postgresql-with-geo). Especially for larger environments, PostgreSQL upgrades must be planned and executed consciously. As a result and going forward, ensure PostgreSQL upgrades are part of the regular maintenance activities.

1. Stop application server and Sidekiq:

   ```shell
   gitlab-ctl stop puma
   gitlab-ctl stop sidekiq
   ```

   {{< alert type="note" >}}

   This step is important so you don't try to execute anything before the site is fully configured.

   {{< /alert >}}

1. [Check TCP connectivity](../../raketasks/maintenance.md) to the **primary** site's PostgreSQL server:

   ```shell
   gitlab-rake gitlab:tcp_check[<primary_site_ip>,5432]
   ```

   {{< alert type="note" >}}

   If this step fails, you may be using the wrong IP address, or a firewall may
   be preventing access to the site. Check the IP address, paying close
   attention to the difference between public and private addresses. Ensure
   that, if a firewall is present, the **secondary** site is permitted to connect to the
   **primary** site on port 5432.

   {{< /alert >}}

1. Create a file `server.crt` in the **secondary** site, with the content you got on the last step of the **primary** site's setup:

   ```shell
   editor server.crt
   ```

1. Set up PostgreSQL TLS verification on the **secondary** site:

   Install the `server.crt` file:

   ```shell
   install \
      -D \
      -o gitlab-psql \
      -g gitlab-psql \
      -m 0400 \
      -T server.crt ~gitlab-psql/.postgresql/root.crt
   ```

   PostgreSQL now only recognizes that exact certificate when verifying TLS
   connections. The certificate can only be replicated by someone with access
   to the private key, which is **only** present on the **primary** site.

1. Test that the `gitlab-psql` user can connect to the **primary** site's database
   (the default database name is `gitlabhq_production` on a Linux package installation):

   ```shell
   sudo \
      -u gitlab-psql /opt/gitlab/embedded/bin/psql \
      --list \
      -U gitlab_replicator \
      -d "dbname=gitlabhq_production sslmode=verify-ca" \
      -W \
      -h <primary_site_ip>
   ```

   {{< alert type="note" >}}

   If you are using manually generated certificates and want to use
   `sslmode=verify-full` to benefit from the full hostname verification,
   replace `verify-ca` with `verify-full` when
   running the command.

   {{< /alert >}}

   When prompted, enter the plaintext password you set in the first step for the
   `gitlab_replicator` user. If all worked correctly, you should see
   the list of the **primary** site's databases.

   A failure to connect here indicates that the TLS configuration is incorrect.
   Ensure that the contents of `~gitlab-psql/data/server.crt` on the **primary** site
   match the contents of `~gitlab-psql/.postgresql/root.crt` on the **secondary** site.

1. Edit `/etc/gitlab/gitlab.rb` and set the role to `geo_secondary_role` (for more information, see [Geo roles](https://docs.gitlab.com/omnibus/roles/#gitlab-geo-roles)):

   ```ruby
   ##
   ## Geo Secondary role
   ## - configure dependent flags automatically to enable Geo
   ##
   roles(['geo_secondary_role'])
   ```

1. Configure PostgreSQL:

   This step is similar to how you configured the **primary** instance.
   You must enable this, even if using a single node.

   Edit `/etc/gitlab/gitlab.rb` and add the following, replacing the IP
   addresses with addresses appropriate to your network configuration:

   ```ruby
   ##
   ## Secondary address
   ## - replace '<secondary_site_ip>' with the public or VPC address of your Geo secondary site
   ##
   postgresql['listen_address'] = '<secondary_site_ip>'
   postgresql['md5_auth_cidr_addresses'] = ['<secondary_site_ip>/32']

   ##
   ## Database credentials password (defined previously in primary site)
   ## - replicate same values here as defined in primary site
   ##
   postgresql['sql_replication_password'] = '<md5_hash_of_your_replication_password>'
   postgresql['sql_user_password'] = '<md5_hash_of_your_db_password>'
   gitlab_rails['db_password'] = '<your_db_password_here>'
   ```

   For external PostgreSQL instances, see [additional instructions](external_database.md).
   If you bring a former **primary** site back online to serve as a **secondary** site, then you also must remove `roles(['geo_primary_role'])` or `geo_primary_role['enable'] = true`.

1. Reconfigure GitLab for the changes to take effect:

   ```shell
   gitlab-ctl reconfigure
   ```

1. Restart PostgreSQL for the IP change to take effect:

   ```shell
   gitlab-ctl restart postgresql
   ```

#### Step 3. Initiate the replication process

Below is a script that connects the database on the **secondary** site to
the database on the **primary** site. This script replicates the database and creates the
needed files for streaming replication.

The directories used are the defaults that are set up in a Linux package installation. If you have
changed any defaults, configure the script accordingly (replacing any directories and paths).

{{< alert type="warning" >}}

Make sure to run this on the **secondary** site as it removes all PostgreSQL's
data before running `pg_basebackup`.

{{< /alert >}}

1. SSH into your GitLab **secondary** site and sign in as root:

   ```shell
   sudo -i
   ```

1. Choose a [database-friendly name](https://www.postgresql.org/docs/16/warm-standby.html#STREAMING-REPLICATION-SLOTS-MANIPULATION)
   to use for your **secondary** site to
   use as the replication slot name. For example, if your domain is
   `secondary.geo.example.com`, use `secondary_example` as the slot
   name as shown in the commands below.

1. Execute the command below to start a backup/restore and begin the replication

   {{< alert type="warning" >}}

   Each Geo **secondary** site must have its own unique replication slot name.
   Using the same slot name between two secondaries breaks PostgreSQL replication.

   {{< /alert >}}

   {{< alert type="note" >}}

   Replication slot names must only contain lowercase letters, numbers, and the underscore character.

   {{< /alert >}}

   When prompted, enter the plaintext password you set up for the `gitlab_replicator`
   user in the first step.

   ```shell
   gitlab-ctl replicate-geo-database \
      --slot-name=<secondary_site_name> \
      --host=<primary_site_ip> \
      --sslmode=verify-ca
   ```

   {{< alert type="note" >}}

   If you have generated custom PostgreSQL certificates, you need to use
   `--sslmode=verify-full` (or omit the `sslmode` line entirely), to benefit from the extra
   validation of the full host name in the certificate CN / SAN for additional security.
   Otherwise, using the automatically created certificate with `verify-full` fails,
   as it has a generic `PostgreSQL` CN which doesn't match the `--host` value in this command.

   {{< /alert >}}

   This command also takes a number of additional options. You can use `--help`
   to list them all, but here are some tips:

   - If your primary site has a single node, use the primary node host as the `--host` parameter.
   - If your primary site is using an external PostgreSQL database, you need to adjust the `--host` parameter:
      - For PgBouncer setups, target the actual PostgreSQL database host directly, not the PgBouncer address.
      - For Patroni configurations, target the current Patroni leader host.
      - When using a load balancer (for example, HAProxy), if the load balancer is configured to always route to the Patroni leader, you can target the load balancer's
        If not, you must target the actual database host.
      - For setups with a dedicated PostgreSQL node, target the dedicated database host directly.
   - Change the `--slot-name` to the name of the replication slot
     to be used on the **primary** database. The script attempts to create the
     replication slot automatically if it does not exist.
   - If PostgreSQL is listening on a non-standard port, add `--port=`.
   - If your database is too large to be transferred in 30 minutes, you need
     to increase the timeout. For example, use `--backup-timeout=3600` if you expect the
     initial replication to take under an hour.
   - Pass `--sslmode=disable` to skip PostgreSQL TLS authentication altogether
     (for example, you know the network path is secure, or you are using a site-to-site
     VPN). It is **not** safe over the public Internet!
   - You can read more details about each `sslmode` in the
     [PostgreSQL documentation](https://www.postgresql.org/docs/16/libpq-ssl.html#LIBPQ-SSL-PROTECTION).
     The instructions listed previously are carefully written to ensure protection against
     both passive eavesdroppers and active "man-in-the-middle" attackers.
   - If you're repurposing an old site into a Geo **secondary** site, you must
     add `--force` to the command line.
   - When not in a production machine, you can disable the backup step (if you
     are certain this is what you want) by adding `--skip-backup`.

The replication process is now complete.

{{< alert type="note" >}}

The replication process only copies the data from the primary site's database to the secondary site's database. To complete your secondary site configuration, [add the secondary site on your primary site](../replication/configuration.md#step-3-add-the-secondary-site).

{{< /alert >}}

### PgBouncer support (optional)

[PgBouncer](https://www.pgbouncer.org/) may be used with GitLab Geo to pool
PostgreSQL connections, which can improve performance even when using in a
single instance installation.

You should use PgBouncer if you use GitLab in a highly available
configuration with a cluster of nodes supporting a Geo **primary** site and
two other clusters of nodes supporting a Geo **secondary** site. You need two PgBouncer nodes: one for the
main database and the other for the tracking database. For more information,
see [the relevant documentation](../../postgresql/replication_and_failover.md).

### Changing the replication password

To change the password for the [replication user](https://www.postgresql.org/docs/16/warm-standby.html#STREAMING-REPLICATION)
when using PostgreSQL instances managed by a Linux package installation:

On the GitLab Geo **primary** site:

1. The default value for the replication user is `gitlab_replicator`, but if you've set a custom replication
   user in your `/etc/gitlab/gitlab.rb` under the `postgresql['sql_replication_user']` setting, ensure you
   adapt the following instructions for your own user.

   Generate an MD5 hash of the desired password:

   ```shell
   sudo gitlab-ctl pg-password-md5 gitlab_replicator
   # Enter password: <your_replication_password_here>
   # Confirm password: <your_replication_password_here>
   # 950233c0dfc2f39c64cf30457c3b7f1e
   ```

   Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   # Fill with the hash generated by `gitlab-ctl pg-password-md5 gitlab_replicator`
   postgresql['sql_replication_password'] = '<md5_hash_of_your_replication_password>'
   ```

1. Save the file and reconfigure GitLab to change the replication user's password in PostgreSQL:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Restart PostgreSQL for the replication password change to take effect:

   ```shell
   sudo gitlab-ctl restart postgresql
   ```

Until the password is updated on any **secondary** sites, the [PostgreSQL log](../../logs/_index.md#postgresql-logs) on
the secondaries report the following error message:

```console
FATAL:  could not connect to the primary server: FATAL:  password authentication failed for user "gitlab_replicator"
```

On all GitLab Geo **secondary** sites:

1. The first step isn't necessary from a configuration perspective, because the hashed `'sql_replication_password'`
   is not used on the GitLab Geo **secondary** sites. However in the event that **secondary** site needs to be promoted
   to the GitLab Geo **primary**, make sure to match the `'sql_replication_password'` in the **secondary** site configuration.

   Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   # Fill with the hash generated by `gitlab-ctl pg-password-md5 gitlab_replicator` on the Geo primary
   postgresql['sql_replication_password'] = '<md5_hash_of_your_replication_password>'
   ```

1. During the initial replication setup, the `gitlab-ctl replicate-geo-database` command writes the plaintext
   password for the replication user account to two locations:

   - `gitlab-geo.conf`: Used by the PostgreSQL replication process, written to the PostgreSQL data
     directory, by default at `/var/opt/gitlab/postgresql/data/gitlab-geo.conf`.
   - `.pgpass`: Used by the `gitlab-psql` user, located by default at `/var/opt/gitlab/postgresql/.pgpass`.

   Update the plaintext password in both of these files, and restart PostgreSQL:

   ```shell
   sudo gitlab-ctl restart postgresql
   ```

## Multi-node database replication

### Migrating a single PostgreSQL node to Patroni

Before the introduction of Patroni, Geo had no support for Linux package installations for HA setups on the **secondary** site.

With Patroni, this support is now possible. To migrate the existing PostgreSQL to Patroni:

1. Make sure you have a Consul cluster setup on the secondary (similar to how you set it up on the **primary** site).
1. [Configure a permanent replication slot](#step-1-configure-patroni-permanent-replication-slot-on-the-primary-site).
1. [Configure the internal load balancer](#step-2-configure-the-internal-load-balancer-on-the-primary-site).
1. [Configure a PgBouncer node](#step-3-configure-pgbouncer-nodes-on-the-secondary-site)
1. [Configure a Standby Cluster](#step-4-configure-a-standby-cluster-on-the-secondary-site)
   on that single node machine.

You end up with a **Standby Cluster** with a single node. That allows you to add additional Patroni nodes by following the same instructions listed previously.

### Patroni support

Patroni is the official replication management solution for Geo. Patroni
can be used to build a highly available cluster on the **primary** and a **secondary** Geo site.
Using Patroni on a **secondary** site is optional and you don't have to use the same number of
nodes on each Geo site.

For instructions on how to set up Patroni on the primary site, see the
[relevant documentation](../../postgresql/replication_and_failover.md#patroni).

#### Configuring Patroni cluster for a Geo secondary site

In a Geo secondary site, the main PostgreSQL database is a read-only replica of the primary site's PostgreSQL database.

A production-ready and secure setup requires at least:

- 3 Consul nodes _(primary and secondary sites)_
- 2 Patroni nodes _(primary and secondary sites)_
- 1 PgBouncer node _(primary and secondary sites)_
- 1 internal load-balancer _(primary site only)_

The internal load balancer provides a single endpoint for connecting to the Patroni cluster's leader whenever a new leader is
elected. The load balancer is required for enabling cascading replication from the secondary sites.

Be sure to use [password credentials](../../postgresql/replication_and_failover.md#database-authorization-for-patroni)
and other database best practices.

##### Step 1. Configure Patroni permanent replication slot on the primary site

Set up a persistent replication slot on the primary database to ensure continuous data replication from the primary
database to the Patroni cluster on the secondary node.

{{< tabs >}}

{{< tab title="Primary with Patroni cluster" >}}

To set up database replication with Patroni on a secondary site, you must
configure a permanent replication slot on the primary site's Patroni cluster,
and ensure password authentication is used.

On each node running a Patroni instance on the primary site **starting on the Patroni
Leader instance**:

1. SSH into your Patroni instance and sign in as root:

   ```shell
   sudo -i
   ```

1. [Opt out of automatic PostgreSQL upgrades](https://docs.gitlab.com/omnibus/settings/database/#opt-out-of-automatic-postgresql-upgrades) to avoid unintended downtime when upgrading GitLab. Be aware of the known [caveats when upgrading PostgreSQL with Geo](https://docs.gitlab.com/omnibus/settings/database/#caveats-when-upgrading-postgresql-with-geo). Especially for larger environments, PostgreSQL upgrades must be planned and executed consciously. As a result and going forward, ensure PostgreSQL upgrades are part of the regular maintenance activities.

1. Edit `/etc/gitlab/gitlab.rb` and add the following:

   ```ruby
   roles(['patroni_role'])

   consul['services'] = %w(postgresql)
   consul['configuration'] = {
     retry_join: %w[CONSUL_PRIMARY1_IP CONSUL_PRIMARY2_IP CONSUL_PRIMARY3_IP]
   }

   # You need one entry for each secondary, with a unique name following PostgreSQL slot_name constraints:
   #
   # Configuration syntax is: 'unique_slotname' => { 'type' => 'physical' },
   # We don't support setting a permanent replication slot for logical replication type
   patroni['replication_slots'] = {
     'geo_secondary' => { 'type' => 'physical' }
   }

   patroni['use_pg_rewind'] = true
   patroni['postgresql']['max_wal_senders'] = 8 # Use double of the amount of patroni/reserved slots (3 patronis + 1 reserved slot for a Geo secondary).
   patroni['postgresql']['max_replication_slots'] = 8 # Use double of the amount of patroni/reserved slots (3 patronis + 1 reserved slot for a Geo secondary).
   patroni['username'] = 'PATRONI_API_USERNAME'
   patroni['password'] = 'PATRONI_API_PASSWORD'
   patroni['replication_password'] = 'PLAIN_TEXT_POSTGRESQL_REPLICATION_PASSWORD'

   # Add all patroni nodes to the allowlist
   patroni['allowlist'] = %w[
     127.0.0.1/32
     PATRONI_PRIMARY1_IP/32 PATRONI_PRIMARY2_IP/32 PATRONI_PRIMARY3_IP/32
     PATRONI_SECONDARY1_IP/32 PATRONI_SECONDARY2_IP/32 PATRONI_SECONDARY3_IP/32
   ]

   # We list all secondary instances as they can all become a Standby Leader
   postgresql['md5_auth_cidr_addresses'] = %w[
     PATRONI_PRIMARY1_IP/32 PATRONI_PRIMARY2_IP/32 PATRONI_PRIMARY3_IP/32 PATRONI_PRIMARY_PGBOUNCER/32
     PATRONI_SECONDARY1_IP/32 PATRONI_SECONDARY2_IP/32 PATRONI_SECONDARY3_IP/32 PATRONI_SECONDARY_PGBOUNCER/32
   ]

   postgresql['pgbouncer_user_password'] = 'PGBOUNCER_PASSWORD_HASH'
   postgresql['sql_replication_password'] = 'POSTGRESQL_REPLICATION_PASSWORD_HASH'
   postgresql['sql_user_password'] = 'POSTGRESQL_PASSWORD_HASH'
   postgresql['listen_address'] = '0.0.0.0' # You can use a public or VPC address here instead
   ```

1. Reconfigure GitLab for the changes to take effect:

   ```shell
   gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Primary with single PostgreSQL instance" >}}

1. SSH into your single node instance and sign in as root:

   ```shell
   sudo -i
   ```

1. [Opt out of automatic PostgreSQL upgrades](https://docs.gitlab.com/omnibus/settings/database/#opt-out-of-automatic-postgresql-upgrades) to avoid unintended downtime when upgrading GitLab. Be aware of the known [caveats when upgrading PostgreSQL with Geo](https://docs.gitlab.com/omnibus/settings/database/#caveats-when-upgrading-postgresql-with-geo). Especially for larger environments, PostgreSQL upgrades must be planned and executed consciously. As a result and going forward, ensure PostgreSQL upgrades are part of the regular maintenance activities.

1. Edit `/etc/gitlab/gitlab.rb` and add the following:

   ```ruby
   postgresql['max_wal_senders'] = 2 # Use 2 per secondary site (1 temporary slot for initial Patroni replication + 1 reserved slot for a Geo secondary)
   postgresql['max_replication_slots'] = 2 # Use 2 per secondary site (1 temporary slot for initial Patroni replication + 1 reserved slot for a Geo secondary)
   ```

1. Reconfigure GitLab:

   ```shell
   gitlab-ctl reconfigure
   ```

1. Restart the PostgreSQL service so the new changes take effect:

   ```shell
   gitlab-ctl restart postgresql
   ```

1. Start a Database console

   ```shell
   gitlab-psql
   ```

1. Configure permanent replication slot on the primary site

   ```sql
   select pg_create_physical_replication_slot('geo_secondary')
   ```

1. Optional: If primary does not have PgBouncer, but secondary does:

   Configure the `pgbouncer` user on the primary site and add the necessary `pg_shadow_lookup` function for PgBouncer included with the Linux package. PgBouncer on the secondary server should still be able to connect to PostgreSQL nodes on the secondary site.

   ```sql
   --- Create a new user 'pgbouncer'
   CREATE USER pgbouncer;

   --- Set/change a password and grants replication privilege
   ALTER USER pgbouncer WITH REPLICATION ENCRYPTED PASSWORD '<pgbouncer_password_from_secondary>';

   CREATE OR REPLACE FUNCTION public.pg_shadow_lookup(in i_username text, out username text, out password text) RETURNS record AS $$
   BEGIN
       SELECT usename, passwd FROM pg_catalog.pg_shadow
       WHERE usename = i_username INTO username, password;
       RETURN;
   END;
   $$ LANGUAGE plpgsql SECURITY DEFINER;

   REVOKE ALL ON FUNCTION public.pg_shadow_lookup(text) FROM public, pgbouncer;
   GRANT EXECUTE ON FUNCTION public.pg_shadow_lookup(text) TO pgbouncer;
   ```

{{< /tab >}}

{{< /tabs >}}

##### Step 2. Configure the internal load balancer on the primary site

To avoid reconfiguring the Standby Leader on the secondary site whenever a new
Leader is elected on the primary site, you should set up a TCP internal load
balancer. This load balancer provides a single endpoint for connecting to the Patroni
cluster's Leader.

Linux packages do not include a Load Balancer. Here's how you could do it with
[HAProxy](https://www.haproxy.org/).

The following IPs and names are used as an example:

- `10.6.0.21`: Patroni 1 (`patroni1.internal`)
- `10.6.0.22`: Patroni 2 (`patroni2.internal`)
- `10.6.0.23`: Patroni 3 (`patroni3.internal`)

```plaintext
global
    log /dev/log local0
    log localhost local1 notice
    log stdout format raw local0

defaults
    log global
    default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions

frontend internal-postgresql-tcp-in
    bind *:5432
    mode tcp
    option tcplog

    default_backend postgresql

backend postgresql
    mode tcp
    option httpchk
    http-check expect status 200

    server patroni1.internal 10.6.0.21:5432 maxconn 100 check port 8008
    server patroni2.internal 10.6.0.22:5432 maxconn 100 check port 8008
    server patroni3.internal 10.6.0.23:5432 maxconn 100 check port 8008
```

For further guidance, refer to the documentation for your preferred load balancer.

##### Step 3. Configure PgBouncer nodes on the secondary site

A production-ready and highly available configuration requires at least
three Consul nodes and a minimum of one PgBouncer node. However, it is recommended to have
one PgBouncer node per database node. An internal load balancer (TCP) is required when there is
more than one PgBouncer service node. The internal load balancer provides a single
endpoint for connecting to the PgBouncer cluster. For more information,
see [the relevant documentation](../../postgresql/replication_and_failover.md).

On each node running a PgBouncer instance on the **secondary** site:

1. SSH into your PgBouncer node and sign in as root:

   ```shell
   sudo -i
   ```

1. Edit `/etc/gitlab/gitlab.rb` and add the following:

   ```ruby
   # Disable all components except Pgbouncer and Consul agent
   roles(['pgbouncer_role'])

   # PgBouncer configuration
   pgbouncer['admin_users'] = %w(pgbouncer gitlab-consul)
   pgbouncer['users'] = {
   'gitlab-consul': {
      # Generate it with: `gitlab-ctl pg-password-md5 gitlab-consul`
      password: 'GITLAB_CONSUL_PASSWORD_HASH'
    },
     'pgbouncer': {
       # Generate it with: `gitlab-ctl pg-password-md5 pgbouncer`
       password: 'PGBOUNCER_PASSWORD_HASH'
     }
   }

   # Consul configuration
   consul['watchers'] = %w(postgresql)
   consul['configuration'] = {
     retry_join: %w[CONSUL_SECONDARY1_IP CONSUL_SECONDARY2_IP CONSUL_SECONDARY3_IP]
   }
   consul['monitoring_service_discovery'] =  true
   ```

1. Reconfigure GitLab for the changes to take effect:

   ```shell
   gitlab-ctl reconfigure
   ```

1. Create a `.pgpass` file so Consul is able to reload PgBouncer. Enter the `PLAIN_TEXT_PGBOUNCER_PASSWORD` twice when asked:

   ```shell
   gitlab-ctl write-pgpass --host 127.0.0.1 --database pgbouncer --user pgbouncer --hostuser gitlab-consul
   ```

1. Reload the PgBouncer service:

   ```shell
   gitlab-ctl hup pgbouncer
   ```

##### Step 4. Configure a Standby cluster on the secondary site

{{< alert type="note" >}}

If you are converting a secondary site with a single PostgreSQL instance to a Patroni Cluster, you must start on the PostgreSQL instance. It becomes the Patroni Standby Leader instance,
and then you can switch over to another replica if you need to.

{{< /alert >}}

For each node running a Patroni instance on the secondary site:

1. SSH into your Patroni node and sign in as root:

   ```shell
   sudo -i
   ```

1. [Opt out of automatic PostgreSQL upgrades](https://docs.gitlab.com/omnibus/settings/database/#opt-out-of-automatic-postgresql-upgrades) to avoid unintended downtime when upgrading GitLab. Be aware of the known [caveats when upgrading PostgreSQL with Geo](https://docs.gitlab.com/omnibus/settings/database/#caveats-when-upgrading-postgresql-with-geo). Especially for larger environments, PostgreSQL upgrades must be planned and executed consciously. As a result and going forward, ensure PostgreSQL upgrades are part of the regular maintenance activities.

1. Edit `/etc/gitlab/gitlab.rb` and add the following:

   ```ruby
   roles(['consul_role', 'patroni_role'])

   consul['enable'] = true
   consul['configuration'] = {
     retry_join: %w[CONSUL_SECONDARY1_IP CONSUL_SECONDARY2_IP CONSUL_SECONDARY3_IP]
   }
   consul['services'] = %w(postgresql)

   postgresql['md5_auth_cidr_addresses'] = [
     'PATRONI_SECONDARY1_IP/32', 'PATRONI_SECONDARY2_IP/32', 'PATRONI_SECONDARY3_IP/32', 'PATRONI_SECONDARY_PGBOUNCER/32',
     # Any other instance that needs access to the database as per documentation
   ]


   # Add patroni nodes to the allowlist
   patroni['allowlist'] = %w[
     127.0.0.1/32
     PATRONI_SECONDARY1_IP/32 PATRONI_SECONDARY2_IP/32 PATRONI_SECONDARY3_IP/32
   ]

   patroni['standby_cluster']['enable'] = true
   patroni['standby_cluster']['host'] = 'INTERNAL_LOAD_BALANCER_PRIMARY_IP'
   patroni['standby_cluster']['port'] = INTERNAL_LOAD_BALANCER_PRIMARY_PORT
   patroni['standby_cluster']['primary_slot_name'] = 'geo_secondary' # Or the unique replication slot name you setup before
   patroni['username'] = 'PATRONI_API_USERNAME'
   patroni['password'] = 'PATRONI_API_PASSWORD'
   patroni['replication_password'] = 'PLAIN_TEXT_POSTGRESQL_REPLICATION_PASSWORD'
   patroni['use_pg_rewind'] = true
   patroni['postgresql']['max_wal_senders'] = 5 # A minimum of three for one replica, plus two for each additional replica
   patroni['postgresql']['max_replication_slots'] = 5 # A minimum of three for one replica, plus two for each additional replica

   postgresql['pgbouncer_user_password'] = 'PGBOUNCER_PASSWORD_HASH'
   postgresql['sql_replication_password'] = 'POSTGRESQL_REPLICATION_PASSWORD_HASH'
   postgresql['sql_user_password'] = 'POSTGRESQL_PASSWORD_HASH'
   postgresql['listen_address'] = '0.0.0.0' # You can use a public or VPC address here instead

   # GitLab Rails configuration is required for `gitlab-ctl geo-replication-pause`
   gitlab_rails['db_password'] = 'POSTGRESQL_PASSWORD'
   gitlab_rails['enable'] = true
   gitlab_rails['auto_migrate'] = false
   ```

   When configuring `patroni['standby_cluster']['host']` and `patroni['standby_cluster']['port']`:
   - `INTERNAL_LOAD_BALANCER_PRIMARY_IP` must point to the primary internal load balancer IP.
   - `INTERNAL_LOAD_BALANCER_PRIMARY_PORT` must point to the frontend port [configured for the primary Patroni cluster leader](#step-2-configure-the-internal-load-balancer-on-the-primary-site). **Do not** use the PgBouncer frontend port.

1. Reconfigure GitLab for the changes to take effect.
   This step is required to bootstrap PostgreSQL users and settings.

   - If this is a fresh installation of Patroni:

     ```shell
     gitlab-ctl reconfigure
     ```

   - If you are configuring a Patroni standby cluster on a site that previously had a working Patroni cluster:

     1. Stop Patroni on all nodes that are managed by Patroni, including cascade replicas:

        ```shell
        gitlab-ctl stop patroni
        ```

     1. Run the following on the leader Patroni node to recreate the standby cluster:

        ```shell
        rm -rf /var/opt/gitlab/postgresql/data
        /opt/gitlab/embedded/bin/patronictl -c /var/opt/gitlab/patroni/patroni.yaml remove postgresql-ha
        gitlab-ctl reconfigure
        ```

     1. Start Patroni on the leader Patroni node to initiate the replication process from the primary database:

        ```shell
        gitlab-ctl start patroni
        ```

     1. Check the status of the Patroni cluster:

        ```shell
        gitlab-ctl patroni members
        ```

        Verify that:

        - The current Patroni node appears in the output.
        - The role is `Standby Leader`. The role might initially show `Replica`.
        - The state is `Running`. The state might initially show `Creating replica`.

        Wait until the node's role stabilizes as `Standby Leader` and the state is `Running`. This might take a few minutes.

     1. When the leader Patroni node is the `Standby Leader` and is `Running`, start Patroni on the other Patroni nodes in the standby cluster:

        ```shell
        gitlab-ctl start patroni
        ```

        The other Patroni nodes should join the new standby cluster as replicas and begin replicating from the leader Patroni node automatically.

1. Verify the cluster status:

   ```shell
   gitlab-ctl patroni members
   ```

   Ensure all Patroni nodes are listed in the `Running` state. There should be one `Standby Leader` node and multiple `Replica` nodes.

### Migrating a single tracking database node to Patroni

Before the introduction of Patroni, Geo provided no support for Linux package installations for HA setups on
the secondary site.

With Patroni, it's now possible to support HA setups. However, some restrictions in Patroni
prevent the management of two different clusters on the same machine. You should set up a new
Patroni cluster for the tracking database by following the same instructions describing how to
[configure a Patroni cluster for a Geo secondary site](#configuring-patroni-cluster-for-a-geo-secondary-site).

The secondary nodes backfill the new tracking database, and no data
synchronization is required.

### Configuring Patroni cluster for the tracking PostgreSQL database

**Secondary** Geo sites use a separate PostgreSQL installation as a tracking database to
keep track of replication status and automatically recover from potential replication issues.

If you want to run the Geo tracking database on a single node, see
[Configure the Geo tracking database on the Geo secondary site](../replication/multiple_servers.md#step-2-configure-the-geo-tracking-database-on-the-geo-secondary-site).

The Linux package does not support running the Geo tracking database in a highly available configuration.
In particular, failover does not work properly. See the
[feature request issue](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7292).

If you want to run the Geo tracking database in a highly available configuration, you can connect the
secondary site to an external PostgreSQL database, such as a cloud-managed database, or a manually
configured [Patroni](https://patroni.readthedocs.io/en/latest/) cluster (not managed by the GitLab Linux package).
Follow [Geo with external PostgreSQL instances](external_database.md#configure-the-tracking-database).

## Troubleshooting

Read the [troubleshooting document](../replication/troubleshooting/_index.md).
