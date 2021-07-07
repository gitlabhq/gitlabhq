---
stage: Create
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Configure Gitaly Cluster **(FREE SELF)**

Configure Gitaly Cluster using either:

- Gitaly Cluster configuration instructions available as part of
  [reference architectures](../reference_architectures/index.md) for installations of up to:
  - [3000 users](../reference_architectures/3k_users.md#configure-gitaly-cluster).
  - [5000 users](../reference_architectures/5k_users.md#configure-gitaly-cluster).
  - [10,000 users](../reference_architectures/10k_users.md#configure-gitaly-cluster).
  - [25,000 users](../reference_architectures/25k_users.md#configure-gitaly-cluster).
  - [50,000 users](../reference_architectures/50k_users.md#configure-gitaly-cluster).
- The custom configuration instructions that follow on this page.

Smaller GitLab installations may need only [Gitaly itself](index.md).

NOTE:
Upgrade instructions for Omnibus GitLab installations
[are available](https://docs.gitlab.com/omnibus/update/#gitaly-cluster).

## Requirements for configuring a Gitaly Cluster

The minimum recommended configuration for a Gitaly Cluster requires:

- 1 load balancer
- 1 PostgreSQL server (PostgreSQL 11 or newer)
- 3 Praefect nodes
- 3 Gitaly nodes (1 primary, 2 secondary)

See the [design
document](https://gitlab.com/gitlab-org/gitaly/-/blob/master/doc/design_ha.md)
for implementation details.

NOTE:
If not set in GitLab, feature flags are read as false from the console and Praefect uses their
default value. The default value depends on the GitLab version.

## Setup Instructions

If you [installed](https://about.gitlab.com/install/) GitLab using the Omnibus GitLab package
(highly recommended), follow the steps below:

1. [Preparation](#preparation)
1. [Configuring the Praefect database](#postgresql)
1. [Configuring the Praefect proxy/router](#praefect)
1. [Configuring each Gitaly node](#gitaly) (once for each Gitaly node)
1. [Configure the load balancer](#load-balancer)
1. [Updating the GitLab server configuration](#gitlab)
1. [Configure Grafana](#grafana)

### Preparation

Before beginning, you should already have a working GitLab instance. [Learn how
to install GitLab](https://about.gitlab.com/install/).

Provision a PostgreSQL server. We recommend using the PostgreSQL that is shipped
with Omnibus GitLab and use it to configure the PostgreSQL database. You can use an
external PostgreSQL server (version 11 or newer) but you must set it up [manually](#manual-database-setup).

Prepare all your new nodes by [installing GitLab](https://about.gitlab.com/install/). You need:

- 1 PostgreSQL node
- 1 PgBouncer node (optional)
- At least 1 Praefect node (minimal storage required)
- 3 Gitaly nodes (high CPU, high memory, fast storage)
- 1 GitLab server

You also need the IP/host address for each node:

1. `PRAEFECT_LOADBALANCER_HOST`: the IP/host address of Praefect load balancer
1. `POSTGRESQL_HOST`: the IP/host address of the PostgreSQL server
1. `PGBOUNCER_HOST`: the IP/host address of the PostgreSQL server
1. `PRAEFECT_HOST`: the IP/host address of the Praefect server
1. `GITALY_HOST_*`: the IP or host address of each Gitaly server
1. `GITLAB_HOST`: the IP/host address of the GitLab server

If you are using Google Cloud Platform, SoftLayer, or any other vendor that provides a virtual private cloud (VPC) you can use the private addresses for each cloud instance (corresponds to "internal address" for Google Cloud Platform) for `PRAEFECT_HOST`, `GITALY_HOST_*`, and `GITLAB_HOST`.

#### Secrets

The communication between components is secured with different secrets, which
are described below. Before you begin, generate a unique secret for each, and
make note of it. This enables you to replace these placeholder tokens
with secure tokens as you complete the setup process.

1. `GITLAB_SHELL_SECRET_TOKEN`: this is used by Git hooks to make callback HTTP
   API requests to GitLab when accepting a Git push. This secret is shared with
   GitLab Shell for legacy reasons.
1. `PRAEFECT_EXTERNAL_TOKEN`: repositories hosted on your Praefect cluster can
   only be accessed by Gitaly clients that carry this token.
1. `PRAEFECT_INTERNAL_TOKEN`: this token is used for replication traffic inside
   your Praefect cluster. This is distinct from `PRAEFECT_EXTERNAL_TOKEN`
   because Gitaly clients must not be able to access internal nodes of the
   Praefect cluster directly; that could lead to data loss.
1. `PRAEFECT_SQL_PASSWORD`: this password is used by Praefect to connect to
   PostgreSQL.
1. `PRAEFECT_SQL_PASSWORD_HASH`: the hash of password of the Praefect user.
   Use `gitlab-ctl pg-password-md5 praefect` to generate the hash. The command
   asks for the password for `praefect` user. Enter `PRAEFECT_SQL_PASSWORD`
   plaintext password. By default, Praefect uses `praefect` user, but you can
   change it.
1. `PGBOUNCER_SQL_PASSWORD_HASH`: the hash of password of the PgBouncer user.
   PgBouncer uses this password to connect to PostgreSQL. For more details
   see [bundled PgBouncer](../postgresql/pgbouncer.md) documentation.

We note in the instructions below where these secrets are required.

NOTE:
Omnibus GitLab installations can use `gitlab-secrets.json` for `GITLAB_SHELL_SECRET_TOKEN`.

### PostgreSQL

NOTE:
Do not store the GitLab application database and the Praefect
database on the same PostgreSQL server if using [Geo](../geo/index.md).
The replication state is internal to each instance of GitLab and should
not be replicated.

These instructions help set up a single PostgreSQL database, which creates a single point of
failure. Alternatively, [you can use PostgreSQL replication and failover](../postgresql/replication_and_failover.md).

The following options are available:

- For non-Geo installations, either:
  - Use one of the documented [PostgreSQL setups](../postgresql/index.md).
  - Use your own third-party database setup. This will require [manual setup](#manual-database-setup).
- For Geo instances, either:
  - Set up a separate [PostgreSQL instance](https://www.postgresql.org/docs/11/high-availability.html).
  - Use a cloud-managed PostgreSQL service. AWS
     [Relational Database Service](https://aws.amazon.com/rds/) is recommended.

#### Manual database setup

To complete this section you need:

- One Praefect node
- One PostgreSQL node (version 11 or newer)
  - A PostgreSQL user with permissions to manage the database server

In this section, we configure the PostgreSQL database. This can be used for both external
and Omnibus-provided PostgreSQL server.

To run the following instructions, you can use the Praefect node, where `psql` is installed
by Omnibus GitLab (`/opt/gitlab/embedded/bin/psql`). If you are using the Omnibus-provided
PostgreSQL you can use `gitlab-psql` on the PostgreSQL node instead:

1. Create a new user `praefect` to be used by Praefect:

   ```sql
   CREATE ROLE praefect WITH LOGIN PASSWORD 'PRAEFECT_SQL_PASSWORD';
   ```

   Replace `PRAEFECT_SQL_PASSWORD` with the strong password you generated in the preparation step.

1. Create a new database `praefect_production` that is owned by `praefect` user.

   ```sql
   CREATE DATABASE praefect_production WITH OWNER praefect ENCODING UTF8;
   ```

For using Omnibus-provided PgBouncer you need to take the following additional steps. We strongly
recommend using the PostgreSQL that is shipped with Omnibus as the backend. The following
instructions only work on Omnibus-provided PostgreSQL:

1. For Omnibus-provided PgBouncer, you need to use the hash of `praefect` user instead the of the
   actual password:

   ```sql
   ALTER ROLE praefect WITH PASSWORD 'md5<PRAEFECT_SQL_PASSWORD_HASH>';
   ```

   Replace `<PRAEFECT_SQL_PASSWORD_HASH>` with the hash of the password you generated in the
   preparation step. Note that it is prefixed with `md5` literal.

1. The PgBouncer that is shipped with Omnibus is configured to use [`auth_query`](https://www.pgbouncer.org/config.html#generic-settings)
   and uses `pg_shadow_lookup` function. You need to create this function in `praefect_production`
   database:

   ```sql
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

The database used by Praefect is now configured.

If you see Praefect database errors after configuring PostgreSQL, see
[troubleshooting steps](troubleshooting.md#relation-does-not-exist-errors).

#### Use PgBouncer

To reduce PostgreSQL resource consumption, we recommend setting up and configuring
[PgBouncer](https://www.pgbouncer.org/) in front of the PostgreSQL instance. To do
this, you must point Praefect to PgBouncer by setting Praefect database parameters:

```ruby
praefect['database_host'] = PGBOUNCER_HOST
praefect['database_port'] = 6432
praefect['database_user'] = 'praefect'
praefect['database_password'] = PRAEFECT_SQL_PASSWORD
praefect['database_dbname'] = 'praefect_production'
#praefect['database_sslmode'] = '...'
#praefect['database_sslcert'] = '...'
#praefect['database_sslkey'] = '...'
#praefect['database_sslrootcert'] = '...'
```

Praefect requires an additional connection to the PostgreSQL that supports the
[LISTEN](https://www.postgresql.org/docs/11/sql-listen.html) feature. With PgBouncer
this feature is only available with `session` pool mode (`pool_mode = session`).
It is not supported in `transaction` pool mode (`pool_mode = transaction`).

For the additional connection, you must either:

- Connect Praefect directly to PostgreSQL and bypass PgBouncer.
- Configure a new PgBouncer database that uses to the same PostgreSQL database endpoint,
  but with different pool mode. That is, `pool_mode = session`.

Praefect can be configured to use different connection parameters for direct access
to PostgreSQL. This is the connection that supports the `LISTEN` feature.

Here is an example of Praefect that bypasses PgBouncer and directly connects to PostgreSQL:

```ruby
praefect['database_direct_host'] = POSTGRESQL_HOST
praefect['database_direct_port'] = 5432

# Use the following to override parameters of direct database connection.
# Comment out where the parameters are the same for both connections.

praefect['database_direct_user'] = 'praefect'
praefect['database_direct_password'] = PRAEFECT_SQL_PASSWORD
praefect['database_direct_dbname'] = 'praefect_production'
#praefect['database_direct_sslmode'] = '...'
#praefect['database_direct_sslcert'] = '...'
#praefect['database_direct_sslkey'] = '...'
#praefect['database_direct_sslrootcert'] = '...'
```

We recommend using PgBouncer with `session` pool mode instead. You can use the [bundled
PgBouncer](../postgresql/pgbouncer.md) or use an external PgBouncer and [configure it
manually](https://www.pgbouncer.org/config.html).

The following example uses the bundled PgBouncer and sets up two separate connection pools,
one in `session` pool mode and the other in `transaction` pool mode. For this example to work,
you need to prepare PostgreSQL server with [setup instruction](#manual-database-setup):

```ruby
pgbouncer['databases'] = {
  # Other database configuation including gitlabhq_production
  ...

  praefect_production: {
    host: POSTGRESQL_HOST,
    # Use `pgbouncer` user to connect to database backend.
    user: 'pgbouncer',
    password: PGBOUNCER_SQL_PASSWORD_HASH,
    pool_mode: 'transaction'
  }
  praefect_production_direct: {
    host: POSTGRESQL_HOST,
    # Use `pgbouncer` user to connect to database backend.
    user: 'pgbouncer',
    password: PGBOUNCER_SQL_PASSWORD_HASH,
    dbname: 'praefect_production',
    pool_mode: 'session'
  },

  ...
}
```

Both `praefect_production` and `praefect_production_direct` use the same database endpoint
(`praefect_production`), but with different pool modes. This translates to the following
`databases` section of PgBouncer:

```ini
[databases]
praefect_production = host=POSTGRESQL_HOST auth_user=pgbouncer pool_mode=transaction
praefect_production_direct = host=POSTGRESQL_HOST auth_user=pgbouncer dbname=praefect_production pool_mode=session
```

Now you can configure Praefect to use PgBouncer for both connections:

```ruby
praefect['database_host'] = PGBOUNCER_HOST
praefect['database_port'] = 6432
praefect['database_user'] = 'praefect'
# `PRAEFECT_SQL_PASSWORD` is the plain-text password of
# Praefect user. Not to be confused with `PRAEFECT_SQL_PASSWORD_HASH`.
praefect['database_password'] = PRAEFECT_SQL_PASSWORD

praefect['database_dbname'] = 'praefect_production'
praefect['database_direct_dbname'] = 'praefect_production_direct'

# There is no need to repeat the following. Parameters of direct
# database connection will fall back to the values above.

#praefect['database_direct_host'] = PGBOUNCER_HOST
#praefect['database_direct_port'] = 6432
#praefect['database_direct_user'] = 'praefect'
#praefect['database_direct_password'] = PRAEFECT_SQL_PASSWORD
```

With this configuration, Praefect uses PgBouncer for both connection types.

NOTE:
Omnibus GitLab handles the authentication requirements (using `auth_query`), but if you are preparing
your databases manually and configuring an external PgBouncer, you must include `praefect` user and
its password in the file used by PgBouncer. For example, `userlist.txt` if the [`auth_file`](https://www.pgbouncer.org/config.html#auth_file)
configuration option is set. For more details, consult the PgBouncer documentation.

### Praefect

> [Introduced](https://gitlab.com/gitlab-org/gitaly/-/issues/2634) in GitLab 13.4, Praefect nodes can no longer be designated as `primary`.

If there are multiple Praefect nodes:

- Complete the following steps for **each** node.
- Designate one node as the "deploy node", and configure it first.

To complete this section you need a [configured PostgreSQL server](#postgresql), including:

Praefect should be run on a dedicated node. Do not run Praefect on the
application server, or a Gitaly node.

On the **Praefect** node:

1. Disable all other services by editing `/etc/gitlab/gitlab.rb`:

   ```ruby
   # Disable all other services on the Praefect node
   postgresql['enable'] = false
   redis['enable'] = false
   nginx['enable'] = false
   alertmanager['enable'] = false
   prometheus['enable'] = false
   grafana['enable'] = false
   puma['enable'] = false
   sidekiq['enable'] = false
   gitlab_workhorse['enable'] = false
   gitaly['enable'] = false

   # Enable only the Praefect service
   praefect['enable'] = true

   # Prevent database connections during 'gitlab-ctl reconfigure'
   gitlab_rails['auto_migrate'] = false
   praefect['auto_migrate'] = false
   ```

1. Configure **Praefect** to listen on network interfaces by editing
   `/etc/gitlab/gitlab.rb`:

   ```ruby
   praefect['listen_addr'] = '0.0.0.0:2305'

   # Enable Prometheus metrics access to Praefect. You must use firewalls
   # to restrict access to this address/port.
   praefect['prometheus_listen_addr'] = '0.0.0.0:9652'
   ```

1. Configure a strong `auth_token` for **Praefect** by editing
   `/etc/gitlab/gitlab.rb`. This is needed by clients outside the cluster
   (like GitLab Shell) to communicate with the Praefect cluster:

   ```ruby
   praefect['auth_token'] = 'PRAEFECT_EXTERNAL_TOKEN'
   ```

1. Configure **Praefect** to [connect to the PostgreSQL database](#postgresql). We
   highly recommend using [PgBouncer](#use-pgbouncer) as well.

   If you want to use a TLS client certificate, the options below can be used:

   ```ruby
   # Connect to PostgreSQL using a TLS client certificate
   # praefect['database_sslcert'] = '/path/to/client-cert'
   # praefect['database_sslkey'] = '/path/to/client-key'

   # Trust a custom certificate authority
   # praefect['database_sslrootcert'] = '/path/to/rootcert'
   ```

   By default, Praefect refuses to make an unencrypted connection to
   PostgreSQL. You can override this by uncommenting the following line:

   ```ruby
   # praefect['database_sslmode'] = 'disable'
   ```

1. Configure the **Praefect** cluster to connect to each Gitaly node in the
   cluster by editing `/etc/gitlab/gitlab.rb`.

   The virtual storage's name must match the configured storage name in GitLab
   configuration. In a later step, we configure the storage name as `default`
   so we use `default` here as well. This cluster has three Gitaly nodes `gitaly-1`,
   `gitaly-2`, and `gitaly-3`, which are intended to be replicas of each other.

   WARNING:
   If you have data on an already existing storage called
   `default`, you should configure the virtual storage with another name and
   [migrate the data to the Gitaly Cluster storage](#migrate-to-gitaly-cluster)
   afterwards.

   Replace `PRAEFECT_INTERNAL_TOKEN` with a strong secret, which is used by
   Praefect when communicating with Gitaly nodes in the cluster. This token is
   distinct from the `PRAEFECT_EXTERNAL_TOKEN`.

   Replace `GITALY_HOST_*` with the IP or host address of the each Gitaly node.

   More Gitaly nodes can be added to the cluster to increase the number of
   replicas. More clusters can also be added for very large GitLab instances.

   NOTE:
   When adding additional Gitaly nodes to a virtual storage, all storage names
   within that virtual storage must be unique. Additionally, all Gitaly node
   addresses referenced in the Praefect configuration must be unique.

   ```ruby
   # Name of storage hash must match storage name in git_data_dirs on GitLab
   # server ('default') and in git_data_dirs on Gitaly nodes ('gitaly-1')
   praefect['virtual_storages'] = {
     'default' => {
       'nodes' => {
         'gitaly-1' => {
           'address' => 'tcp://GITALY_HOST_1:8075',
           'token'   => 'PRAEFECT_INTERNAL_TOKEN',
         },
         'gitaly-2' => {
           'address' => 'tcp://GITALY_HOST_2:8075',
           'token'   => 'PRAEFECT_INTERNAL_TOKEN'
         },
         'gitaly-3' => {
           'address' => 'tcp://GITALY_HOST_3:8075',
           'token'   => 'PRAEFECT_INTERNAL_TOKEN'
         }
       }
     }
   }
   ```

   NOTE:
   In [GitLab 13.8 and earlier](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/4988),
   Gitaly nodes were configured directly under the virtual storage, and not under the `nodes` key.

1. [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/2013) in GitLab 13.1 and later, enable [distribution of reads](#distributed-reads).

1. Save the changes to `/etc/gitlab/gitlab.rb` and [reconfigure
   Praefect](../restart_gitlab.md#omnibus-gitlab-reconfigure):

   ```shell
   gitlab-ctl reconfigure
   ```

1. For:

   - The "deploy node":
     1. Enable Praefect auto-migration again by setting `praefect['auto_migrate'] = true` in
        `/etc/gitlab/gitlab.rb`.
     1. To ensure database migrations are only run during reconfigure and not automatically on
        upgrade, run:

        ```shell
        sudo touch /etc/gitlab/skip-auto-reconfigure
        ```

   - The other nodes, you can leave the settings as they are. Though
     `/etc/gitlab/skip-auto-reconfigure` isn't required, you may want to set it to prevent GitLab
     running reconfigure automatically when running commands such as `apt-get update`. This way any
     additional configuration changes can be done and then reconfigure can be run manually.

1. Save the changes to `/etc/gitlab/gitlab.rb` and [reconfigure
   Praefect](../restart_gitlab.md#omnibus-gitlab-reconfigure):

   ```shell
   gitlab-ctl reconfigure
   ```

1. To ensure that Praefect [has updated its Prometheus listen
   address](https://gitlab.com/gitlab-org/gitaly/-/issues/2734), [restart
   Praefect](../restart_gitlab.md#omnibus-gitlab-restart):

   ```shell
   gitlab-ctl restart praefect
   ```

1. Verify that Praefect can reach PostgreSQL:

   ```shell
   sudo -u git /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml sql-ping
   ```

   If the check fails, make sure you have followed the steps correctly. If you
   edit `/etc/gitlab/gitlab.rb`, remember to run `sudo gitlab-ctl reconfigure`
   again before trying the `sql-ping` command.

**The steps above must be completed for each Praefect node!**

#### Enabling TLS support

> [Introduced](https://gitlab.com/gitlab-org/gitaly/-/issues/1698) in GitLab 13.2.

Praefect supports TLS encryption. To communicate with a Praefect instance that listens
for secure connections, you must:

- Use a `tls://` URL scheme in the `gitaly_address` of the corresponding storage entry
  in the GitLab configuration.
- Bring your own certificates because this isn't provided automatically. The certificate
  corresponding to each Praefect server must be installed on that Praefect server.

Additionally the certificate, or its certificate authority, must be installed on all Gitaly servers
and on all Praefect clients that communicate with it following the procedure described in
[GitLab custom certificate configuration](https://docs.gitlab.com/omnibus/settings/ssl.html#install-custom-public-certificates) (and repeated below).

Note the following:

- The certificate must specify the address you use to access the Praefect server. If
  addressing the Praefect server by:

  - Hostname, you can either use the Common Name field for this, or add it as a Subject
    Alternative Name.
  - IP address, you must add it as a Subject Alternative Name to the certificate.

- You can configure Praefect servers with both an unencrypted listening address
  `listen_addr` and an encrypted listening address `tls_listen_addr` at the same time.
  This allows you to do a gradual transition from unencrypted to encrypted traffic, if
  necessary.

To configure Praefect with TLS:

**For Omnibus GitLab**

1. Create certificates for Praefect servers.

1. On the Praefect servers, create the `/etc/gitlab/ssl` directory and copy your key
   and certificate there:

   ```shell
   sudo mkdir -p /etc/gitlab/ssl
   sudo chmod 755 /etc/gitlab/ssl
   sudo cp key.pem cert.pem /etc/gitlab/ssl/
   sudo chmod 644 key.pem cert.pem
   ```

1. Edit `/etc/gitlab/gitlab.rb` and add:

   ```ruby
   praefect['tls_listen_addr'] = "0.0.0.0:3305"
   praefect['certificate_path'] = "/etc/gitlab/ssl/cert.pem"
   praefect['key_path'] = "/etc/gitlab/ssl/key.pem"
   ```

1. Save the file and [reconfigure](../restart_gitlab.md#omnibus-gitlab-reconfigure).

1. On the Praefect clients (including each Gitaly server), copy the certificates,
   or their certificate authority, into `/etc/gitlab/trusted-certs`:

   ```shell
   sudo cp cert.pem /etc/gitlab/trusted-certs/
   ```

1. On the Praefect clients (except Gitaly servers), edit `git_data_dirs` in
   `/etc/gitlab/gitlab.rb` as follows:

   ```ruby
   git_data_dirs({
     "default" => {
       "gitaly_address" => 'tls://PRAEFECT_LOADBALANCER_HOST:2305',
       "gitaly_token" => 'PRAEFECT_EXTERNAL_TOKEN'
     }
   })
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure).

**For installations from source**

1. Create certificates for Praefect servers.
1. On the Praefect servers, create the `/etc/gitlab/ssl` directory and copy your key and certificate
   there:

   ```shell
   sudo mkdir -p /etc/gitlab/ssl
   sudo chmod 755 /etc/gitlab/ssl
   sudo cp key.pem cert.pem /etc/gitlab/ssl/
   sudo chmod 644 key.pem cert.pem
   ```

1. On the Praefect clients (including each Gitaly server), copy the certificates,
   or their certificate authority, into the system trusted certificates:

   ```shell
   sudo cp cert.pem /usr/local/share/ca-certificates/praefect.crt
   sudo update-ca-certificates
   ```

1. On the Praefect clients (except Gitaly servers), edit `storages` in
   `/home/git/gitlab/config/gitlab.yml` as follows:

   ```yaml
   gitlab:
     repositories:
       storages:
         default:
           gitaly_address: tls://PRAEFECT_LOADBALANCER_HOST:3305
           path: /some/local/path
   ```

   NOTE:
   `/some/local/path` should be set to a local folder that exists, however no
   data is stored in this folder. This requirement is scheduled to be removed when
   [this issue](https://gitlab.com/gitlab-org/gitaly/-/issues/1282) is resolved.

1. Save the file and [restart GitLab](../restart_gitlab.md#installations-from-source).
1. Copy all Praefect server certificates, or their certificate authority, to the system
   trusted certificates on each Gitaly server so the Praefect server trusts the
   certificate when called by Gitaly servers:

   ```shell
   sudo cp cert.pem /usr/local/share/ca-certificates/praefect.crt
   sudo update-ca-certificates
   ```

1. Edit `/home/git/praefect/config.toml` and add:

   ```toml
   tls_listen_addr = '0.0.0.0:3305'

   [tls]
   certificate_path = '/etc/gitlab/ssl/cert.pem'
   key_path = '/etc/gitlab/ssl/key.pem'
   ```

1. Save the file and [restart GitLab](../restart_gitlab.md#installations-from-source).

### Gitaly

NOTE:
Complete these steps for **each** Gitaly node.

To complete this section you need:

- [Configured Praefect node](#praefect)
- 3 (or more) servers, with GitLab installed, to be configured as Gitaly nodes.
  These should be dedicated nodes, do not run other services on these nodes.

Every Gitaly server assigned to the Praefect cluster needs to be configured. The
configuration is the same as a normal [standalone Gitaly server](index.md),
except:

- The storage names are exposed to Praefect, not GitLab
- The secret token is shared with Praefect, not GitLab

The configuration of all Gitaly nodes in the Praefect cluster can be identical,
because we rely on Praefect to route operations correctly.

Particular attention should be shown to:

- The `gitaly['auth_token']` configured in this section must match the `token`
  value under `praefect['virtual_storages']['nodes']` on the Praefect node. This was set
  in the [previous section](#praefect). This document uses the placeholder
  `PRAEFECT_INTERNAL_TOKEN` throughout.
- The storage names in `git_data_dirs` configured in this section must match the
  storage names under `praefect['virtual_storages']` on the Praefect node. This
  was set in the [previous section](#praefect). This document uses `gitaly-1`,
  `gitaly-2`, and `gitaly-3` as Gitaly storage names.

For more information on Gitaly server configuration, see our [Gitaly
documentation](configure_gitaly.md#configure-gitaly-servers).

1. SSH into the **Gitaly** node and login as root:

   ```shell
   sudo -i
   ```

1. Disable all other services by editing `/etc/gitlab/gitlab.rb`:

   ```ruby
   # Disable all other services on the Praefect node
   postgresql['enable'] = false
   redis['enable'] = false
   nginx['enable'] = false
   grafana['enable'] = false
   puma['enable'] = false
   sidekiq['enable'] = false
   gitlab_workhorse['enable'] = false
   prometheus_monitoring['enable'] = false

   # Enable only the Gitaly service
   gitaly['enable'] = true

   # Enable Prometheus if needed
   prometheus['enable'] = true

   # Prevent database connections during 'gitlab-ctl reconfigure'
   gitlab_rails['auto_migrate'] = false
   ```

1. Configure **Gitaly** to listen on network interfaces by editing
   `/etc/gitlab/gitlab.rb`:

   ```ruby
   # Make Gitaly accept connections on all network interfaces.
   # Use firewalls to restrict access to this address/port.
   gitaly['listen_addr'] = '0.0.0.0:8075'

   # Enable Prometheus metrics access to Gitaly. You must use firewalls
   # to restrict access to this address/port.
   gitaly['prometheus_listen_addr'] = '0.0.0.0:9236'
   ```

1. Configure a strong `auth_token` for **Gitaly** by editing
   `/etc/gitlab/gitlab.rb`. This is needed by clients to communicate with
   this Gitaly nodes. Typically, this token is the same for all Gitaly
   nodes.

   ```ruby
   gitaly['auth_token'] = 'PRAEFECT_INTERNAL_TOKEN'
   ```

1. Configure the GitLab Shell secret token, which is needed for `git push` operations. Either:

   - Method 1:

     1. Copy `/etc/gitlab/gitlab-secrets.json` from the Gitaly client to same path on the Gitaly
        servers and any other Gitaly clients.
     1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) on Gitaly servers.

   - Method 2:

     1. Edit `/etc/gitlab/gitlab.rb`.
     1. Replace `GITLAB_SHELL_SECRET_TOKEN` with the real secret.

        ```ruby
        gitlab_shell['secret_token'] = 'GITLAB_SHELL_SECRET_TOKEN'
        ```

1. Configure and `internal_api_url`, which is also needed for `git push` operations:

   ```ruby
   # Configure the gitlab-shell API callback URL. Without this, `git push` will
   # fail. This can be your front door GitLab URL or an internal load balancer.
   # Examples: 'https://gitlab.example.com', 'http://1.2.3.4'
   gitlab_rails['internal_api_url'] = 'http://GITLAB_HOST'
   ```

1. Configure the storage location for Git data by setting `git_data_dirs` in
   `/etc/gitlab/gitlab.rb`. Each Gitaly node should have a unique storage name
   (such as `gitaly-1`).

   Instead of configuring `git_data_dirs` uniquely for each Gitaly node, it is
   often easier to have include the configuration for all Gitaly nodes on every
   Gitaly node. This is supported because the Praefect `virtual_storages`
   configuration maps each storage name (such as `gitaly-1`) to a specific node, and
   requests are routed accordingly. This means every Gitaly node in your fleet
   can share the same configuration.

   ```ruby
   # You can include the data dirs for all nodes in the same config, because
   # Praefect will only route requests according to the addresses provided in the
   # prior step.
   git_data_dirs({
     "gitaly-1" => {
       "path" => "/var/opt/gitlab/git-data"
     },
     "gitaly-2" => {
       "path" => "/var/opt/gitlab/git-data"
     },
     "gitaly-3" => {
       "path" => "/var/opt/gitlab/git-data"
     }
   })
   ```

1. Save the changes to `/etc/gitlab/gitlab.rb` and [reconfigure
   Gitaly](../restart_gitlab.md#omnibus-gitlab-reconfigure):

   ```shell
   gitlab-ctl reconfigure
   ```

1. To ensure that Gitaly [has updated its Prometheus listen
   address](https://gitlab.com/gitlab-org/gitaly/-/issues/2734), [restart
   Gitaly](../restart_gitlab.md#omnibus-gitlab-restart):

   ```shell
   gitlab-ctl restart gitaly
   ```

**The steps above must be completed for each Gitaly node!**

After all Gitaly nodes are configured, run the Praefect connection
checker to verify Praefect can connect to all Gitaly servers in the Praefect
configuration.

1. SSH into each **Praefect** node and run the Praefect connection checker:

   ```shell
   sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml dial-nodes
   ```

### Load Balancer

In a fault-tolerant Gitaly configuration, a load balancer is needed to route
internal traffic from the GitLab application to the Praefect nodes. The
specifics on which load balancer to use or the exact configuration is beyond the
scope of the GitLab documentation.

NOTE:
The load balancer must be configured to accept traffic from the Gitaly nodes in
addition to the GitLab nodes. Some requests handled by
[`gitaly-ruby`](configure_gitaly.md#gitaly-ruby) sidecar processes call into the main Gitaly
process. `gitaly-ruby` uses the Gitaly address set in the GitLab server's
`git_data_dirs` setting to make this connection.

We hope that if you're managing fault-tolerant systems like GitLab, you have a load balancer
of choice already. Some examples include [HAProxy](https://www.haproxy.org/)
(open-source), [Google Internal Load Balancer](https://cloud.google.com/load-balancing/docs/internal/),
[AWS Elastic Load Balancer](https://aws.amazon.com/elasticloadbalancing/), F5
Big-IP LTM, and Citrix Net Scaler. This documentation outlines what ports
and protocols you need configure.

| LB Port | Backend Port | Protocol |
|:--------|:-------------|:---------|
| 2305    | 2305         | TCP      |

### GitLab

To complete this section you need:

- [Configured Praefect node](#praefect)
- [Configured Gitaly nodes](#gitaly)

The Praefect cluster needs to be exposed as a storage location to the GitLab
application. This is done by updating the `git_data_dirs`.

Particular attention should be shown to:

- the storage name added to `git_data_dirs` in this section must match the
  storage name under `praefect['virtual_storages']` on the Praefect node(s). This
  was set in the [Praefect](#praefect) section of this guide. This document uses
  `default` as the Praefect storage name.

1. SSH into the **GitLab** node and login as root:

   ```shell
   sudo -i
   ```

1. Configure the `external_url` so that files could be served by GitLab
   by proper endpoint access by editing `/etc/gitlab/gitlab.rb`:

   You need to replace `GITLAB_SERVER_URL` with the real external facing
   URL on which current GitLab instance is serving:

   ```ruby
   external_url 'GITLAB_SERVER_URL'
   ```

1. Disable the default Gitaly service running on the GitLab host. It isn't needed
   because GitLab connects to the configured cluster.

   WARNING:
   If you have existing data stored on the default Gitaly storage,
   you should [migrate the data your Gitaly Cluster storage](#migrate-to-gitaly-cluster)
   first.

   ```ruby
   gitaly['enable'] = false
   ```

1. Add the Praefect cluster as a storage location by editing
   `/etc/gitlab/gitlab.rb`.

   You need to replace:

   - `PRAEFECT_LOADBALANCER_HOST` with the IP address or hostname of the load
     balancer.
   - `PRAEFECT_EXTERNAL_TOKEN` with the real secret

   If you are using TLS, the `gitaly_address` should begin with `tls://`.

   ```ruby
   git_data_dirs({
     "default" => {
       "gitaly_address" => "tcp://PRAEFECT_LOADBALANCER_HOST:2305",
       "gitaly_token" => 'PRAEFECT_EXTERNAL_TOKEN'
     }
   })
   ```

1. Configure the GitLab Shell secret token so that callbacks from Gitaly nodes during a `git push`
   are properly authenticated. Either:

   - Method 1:

     1. Copy `/etc/gitlab/gitlab-secrets.json` from the Gitaly client to same path on the Gitaly
        servers and any other Gitaly clients.
     1. [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) on Gitaly servers.

   - Method 2:

     1. Edit `/etc/gitlab/gitlab.rb`.
     1. Replace `GITLAB_SHELL_SECRET_TOKEN` with the real secret.

        ```ruby
        gitlab_shell['secret_token'] = 'GITLAB_SHELL_SECRET_TOKEN'
        ```

1. Add Prometheus monitoring settings by editing `/etc/gitlab/gitlab.rb`. If Prometheus
   is enabled on a different node, make edits on that node instead.

   You need to replace:

   - `PRAEFECT_HOST` with the IP address or hostname of the Praefect node
   - `GITALY_HOST_*` with the IP address or hostname of each Gitaly node

   ```ruby
   prometheus['scrape_configs'] = [
     {
       'job_name' => 'praefect',
       'static_configs' => [
         'targets' => [
           'PRAEFECT_HOST:9652', # praefect-1
           'PRAEFECT_HOST:9652', # praefect-2
           'PRAEFECT_HOST:9652', # praefect-3
         ]
       ]
     },
     {
       'job_name' => 'praefect-gitaly',
       'static_configs' => [
         'targets' => [
           'GITALY_HOST_1:9236', # gitaly-1
           'GITALY_HOST_2:9236', # gitaly-2
           'GITALY_HOST_3:9236', # gitaly-3
         ]
       ]
     }
   ]
   ```

1. Save the changes to `/etc/gitlab/gitlab.rb` and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure):

   ```shell
   gitlab-ctl reconfigure
   ```

1. Verify on each Gitaly node the Git Hooks can reach GitLab. On each Gitaly node run:

   ```shell
   /opt/gitlab/embedded/bin/gitaly-hooks check /var/opt/gitlab/gitaly/config.toml
   ```

1. Verify that GitLab can reach Praefect:

   ```shell
   gitlab-rake gitlab:gitaly:check
   ```

1. Check that the Praefect storage is configured to store new repositories:

   1. On the top bar, select **Menu >** **{admin}** **Admin**.
   1. On the left sidebar, select **Settings > Repository**.
   1. Expand the **Repository storage** section.

   Following this guide, the `default` storage should have weight 100 to store all new repositories.

1. Verify everything is working by creating a new project. Check the
   "Initialize repository with a README" box so that there is content in the
   repository that viewed. If the project is created, and you can see the
   README file, it works!

#### Use TCP for existing GitLab instances

When adding Gitaly Cluster to an existing Gitaly instance, the existing Gitaly storage
must use a TCP address. If `gitaly_address` is not specified, then a Unix socket is used,
which prevents the communication with the cluster.

For example:

```ruby
git_data_dirs({
  'default' => { 'gitaly_address' => 'tcp://old-gitaly.internal:8075' },
  'cluster' => {
    'gitaly_address' => 'tcp://<PRAEFECT_LOADBALANCER_HOST>:2305',
    'gitaly_token' => '<praefect_external_token>'
  }
})
```

See [Mixed Configuration](configure_gitaly.md#mixed-configuration) for further information on
running multiple Gitaly storages.

### Grafana

Grafana is included with GitLab, and can be used to monitor your Praefect
cluster. See [Grafana Dashboard
Service](https://docs.gitlab.com/omnibus/settings/grafana.html)
for detailed documentation.

To get started quickly:

1. SSH into the **GitLab** node (or whichever node has Grafana enabled) and login as root:

   ```shell
   sudo -i
   ```

1. Enable the Grafana login form by editing `/etc/gitlab/gitlab.rb`.

   ```ruby
   grafana['disable_login_form'] = false
   ```

1. Save the changes to `/etc/gitlab/gitlab.rb` and [reconfigure
   GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure):

   ```shell
   gitlab-ctl reconfigure
   ```

1. Set the Grafana administrator password. This command prompts you to enter a new
   password:

   ```shell
   gitlab-ctl set-grafana-password
   ```

1. In your web browser, open `/-/grafana` (such as
   `https://gitlab.example.com/-/grafana`) on your GitLab server.

   Login using the password you set, and the username `admin`.

1. Go to **Explore** and query `gitlab_build_info` to verify that you are
   getting metrics from all your machines.

Congratulations! You've configured an observable fault-tolerant Praefect
cluster.

## Network connectivity requirements

Gitaly Cluster components need to communicate with each other over many routes.
Your firewall rules must allow the following for Gitaly Cluster to function properly:

| From                   | To                      | Default port / TLS port |
|:-----------------------|:------------------------|:------------------------|
| GitLab                 | Praefect load balancer  | `2305` / `3305`         |
| Praefect load balancer | Praefect                | `2305` / `3305`         |
| Praefect               | Gitaly                  | `8075` / `9999`         |
| Gitaly                 | GitLab (internal API)   | `80` / `443`            |
| Gitaly                 | Praefect load balancer  | `2305` / `3305`         |
| Gitaly                 | Praefect                | `2305` / `3305`         |
| Gitaly                 | Gitaly                  | `8075` / `9999`         |

NOTE:
Gitaly does not directly connect to Praefect. However, requests from Gitaly to the Praefect
load balancer may still be blocked unless firewalls on the Praefect nodes allow traffic from
the Gitaly nodes.

## Distributed reads

> - Introduced in GitLab 13.1 in [beta](https://about.gitlab.com/handbook/product/gitlab-the-product/#alpha-beta-ga) with feature flag `gitaly_distributed_reads` set to disabled.
> - [Made generally available and enabled by default](https://gitlab.com/gitlab-org/gitaly/-/issues/2951) in GitLab 13.3.
> - [Disabled by default](https://gitlab.com/gitlab-org/gitaly/-/issues/3178) in GitLab 13.5.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitaly/-/issues/3334) in GitLab 13.8.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitaly/-/issues/3383) in GitLab 13.11.

Praefect supports distribution of read operations across Gitaly nodes that are
configured for the virtual node.

All RPCs marked with `ACCESSOR` option like
[GetBlob](https://gitlab.com/gitlab-org/gitaly/-/blob/v12.10.6/proto/blob.proto#L16)
are redirected to an up to date and healthy Gitaly node.

_Up to date_ in this context means that:

- There is no replication operations scheduled for this node.
- The last replication operation is in _completed_ state.

If there is no such nodes, or any other error occurs during node selection, the primary
node is chosen to serve the request.

To track distribution of read operations, you can use the `gitaly_praefect_read_distribution`
Prometheus counter metric. It has two labels:

- `virtual_storage`.
- `storage`.

They reflect configuration defined for this instance of Praefect.

## Strong consistency

> - Introduced in GitLab 13.1 in [alpha](https://about.gitlab.com/handbook/product/gitlab-the-product/#alpha-beta-ga), disabled by default.
> - Entered [beta](https://about.gitlab.com/handbook/product/gitlab-the-product/#alpha-beta-ga) in GitLab 13.2, disabled by default.
> - In GitLab 13.3, disabled unless primary-wins voting strategy is disabled.
> - From GitLab 13.4, enabled by default.
> - From GitLab 13.5, you must use Git v2.28.0 or higher on Gitaly nodes to enable strong consistency.
> - From GitLab 13.6, primary-wins voting strategy and `gitaly_reference_transactions_primary_wins` feature flag were removed from the source code.

Praefect guarantees eventual consistency by replicating all writes to secondary nodes
after the write to the primary Gitaly node has happened.

Praefect can instead provide strong consistency by creating a transaction and writing
changes to all Gitaly nodes at once.
If enabled, transactions are only available for a subset of RPCs. For more
information, see the [strong consistency epic](https://gitlab.com/groups/gitlab-org/-/epics/1189).

To enable strong consistency:

- In GitLab 13.5, you must use Git v2.28.0 or higher on Gitaly nodes to enable strong consistency.
- In GitLab 13.4 and later, the strong consistency voting strategy has been improved and enabled by default.
  Instead of requiring all nodes to agree, only the primary and half of the secondaries need to agree.
- In GitLab 13.3, reference transactions are enabled by default with a primary-wins strategy.
  This strategy causes all transactions to succeed for the primary and thus does not ensure strong consistency.
  To enable strong consistency, disable the `:gitaly_reference_transactions_primary_wins` feature flag.
- In GitLab 13.2, enable the `:gitaly_reference_transactions` feature flag.
- In GitLab 13.1, enable the `:gitaly_reference_transactions` and `:gitaly_hooks_rpc`
  feature flags.

Changing feature flags requires [access to the Rails console](../feature_flags.md#start-the-gitlab-rails-console).
In the Rails console, enable or disable the flags as required. For example:

```ruby
Feature.enable(:gitaly_reference_transactions)
Feature.disable(:gitaly_reference_transactions_primary_wins)
```

To monitor strong consistency, you can use the following Prometheus metrics:

- `gitaly_praefect_transactions_total`: Number of transactions created and
  voted on.
- `gitaly_praefect_subtransactions_per_transaction_total`: Number of times
  nodes cast a vote for a single transaction. This can happen multiple times if
  multiple references are getting updated in a single transaction.
- `gitaly_praefect_voters_per_transaction_total`: Number of Gitaly nodes taking
  part in a transaction.
- `gitaly_praefect_transactions_delay_seconds`: Server-side delay introduced by
  waiting for the transaction to be committed.
- `gitaly_hook_transaction_voting_delay_seconds`: Client-side delay introduced
  by waiting for the transaction to be committed.

## Replication factor

Replication factor is the number of copies Praefect maintains of a given repository. A higher
replication factor offers better redundancy and distribution of read workload, but also results
in a higher storage cost. By default, Praefect replicates repositories to every storage in a
virtual storage.

### Configure replication factor

WARNING:
Configurable replication factors require [repository-specific primary nodes](#repository-specific-primary-nodes) to be used.

Praefect supports configuring a replication factor on a per-repository basis, by assigning
specific storage nodes to host a repository.

Praefect does not store the actual replication factor, but assigns enough storages to host the repository
so the desired replication factor is met. If a storage node is later removed from the virtual storage,
the replication factor of repositories assigned to the storage is decreased accordingly.

You can configure:

- A default replication factor for each virtual storage that is applied to newly-created repositories.
  The configuration is added to the `/etc/gitlab/gitlab.rb` file:

  ```ruby
  praefect['virtual_storages'] = {
    'default' => {
      'default_replication_factor' => 1,
      # ...
    }
  }
  ```

- A replication factor for an existing repository using the `set-replication-factor` sub-command.
  `set-replication-factor` automatically assigns or unassigns random storage nodes as
  necessary to reach the desired replication factor. The repository's primary node is
  always assigned first and is never unassigned.

  ```shell
  sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml set-replication-factor -virtual-storage <virtual-storage> -repository <relative-path> -replication-factor <replication-factor>
  ```

  - `-virtual-storage` is the virtual storage the repository is located in.
  - `-repository` is the repository's relative path in the storage.
  - `-replication-factor` is the desired replication factor of the repository. The minimum value is
    `1`, as the primary needs a copy of the repository. The maximum replication factor is the number of
    storages in the virtual storage.

  On success, the assigned host storages are printed. For example:

  ```shell
  $ sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml set-replication-factor -virtual-storage default -repository @hashed/3f/db/3fdba35f04dc8c462986c992bcf875546257113072a909c162f7e470e581e278.git -replication-factor 2

  current assignments: gitaly-1, gitaly-2
  ```

## Automatic failover and primary election strategies

Praefect regularly checks the health of each Gitaly node. This is used to automatically fail over
to a newly-elected primary Gitaly node if the current primary node is found to be unhealthy.

We recommend using [repository-specific primary nodes](#repository-specific-primary-nodes). This is
[planned to be the only available election strategy](https://gitlab.com/gitlab-org/gitaly/-/issues/3574)
from GitLab 14.0.

### Repository-specific primary nodes

> [Introduced](https://gitlab.com/gitlab-org/gitaly/-/issues/3492) in GitLab 13.12.

Gitaly Cluster supports electing repository-specific primary Gitaly nodes. Repository-specific
Gitaly primary nodes are enabled in `/etc/gitlab/gitlab.rb` by setting
`praefect['failover_election_strategy'] = 'per_repository'`.

Praefect's [deprecated election strategies](#deprecated-election-strategies):

- Elected a primary Gitaly node for each virtual storage, which was used as the primary node for
  each repository in the virtual storage.
- Prevented horizontal scaling of a virtual storage. The primary Gitaly node needed a replica of
  each repository and thus became the bottleneck.

The `per_repository` election strategy solves this problem by electing a primary Gitaly node separately for each
repository. Combined with [configurable replication factors](#configure-replication-factor), you can
horizontally scale storage capacity and distribute write load across Gitaly nodes.

Primary elections are run when:

- Praefect starts up.
- The cluster's consensus of a Gitaly node's health changes.

A Gitaly node is considered:

- Healthy if `>=50%` Praefect nodes have successfully health checked the Gitaly node in the
  previous ten seconds.
- Unhealthy otherwise.

During an election run, Praefect elects a new primary Gitaly node for each repository that has
an unhealthy primary Gitaly node. The election is made:

- Randomly from healthy secondary Gitaly nodes that are the most up to date.
- Only from Gitaly nodes assigned to the host repository.

If there are no healthy secondary nodes for a repository:

- The unhealthy primary node is demoted and the repository is left without a primary node.
- Operations that require a primary node fail until a primary is successfully elected.

#### Migrate to repository-specific primary Gitaly nodes

New Gitaly Clusters can start using the `per_repository` election strategy immediately.

To migrate existing clusters:

1. Praefect nodes didn't historically keep database records of every repository stored on the cluster. When
   the `per_repository` election strategy is configured, Praefect expects to have database records of
   each repository. A [background migration](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/2749) is
   included in GitLab 13.6 and later to create any missing database records for repositories. Before migrating
   you should verify the migration has run by checking Praefect's logs:

   Check Praefect's logs for `repository importer finished` message. The `virtual_storages` field contains
   the names of virtual storages and whether they've had any missing database records created.

   For example, the `default` virtual storage has been successfully migrated:

   ```json
   {"level":"info","msg":"repository importer finished","pid":19752,"time":"2021-04-28T11:41:36.743Z","virtual_storages":{"default":true}}
   ```

   If a virtual storage has not been successfully migrated, it would have `false` next to it:

   ```json
   {"level":"info","msg":"repository importer finished","pid":19752,"time":"2021-04-28T11:41:36.743Z","virtual_storages":{"default":false}}
   ```

   The migration is ran when Praefect starts up. If the migration is unsuccessful, you can restart
   a Praefect node to reattempt it. The migration only runs with `sql` election strategy configured.

1. Running two different election strategies side by side can cause a split brain, where different
   Praefect nodes consider repositories to have different primaries. This can be avoided either:

   - If a short downtime is acceptable:

      1. Shut down all Praefect nodes before changing the election strategy. Do this by running `gitlab-ctl stop praefect` on the Praefect nodes.

      1. On the Praefect nodes, configure the election strategy in `/etc/gitlab/gitlab.rb` with `praefect['failover_election_strategy'] = 'per_repository'`.

      1. Run `gitlab-ctl reconfigure && gitlab-ctl start` to reconfigure and start the Praefects.

   - If downtime is unacceptable:

      1. Determine which Gitaly node is [the current primary](troubleshooting.md#determine-primary-gitaly-node).

      1. Comment out the secondary Gitaly nodes from the virtual storage's configuration in `/etc/gitlab/gitlab.rb`
      on all Praefect nodes. This ensures there's only one Gitaly node configured, causing both of the election
      strategies to elect the same Gitaly node as the primary.

      1. Run `gitlab-ctl reconfigure` on all Praefect nodes. Wait until all Praefect processes have restarted and
      the old processes have exited. This can take up to one minute.

      1. On all Praefect nodes, configure the election strategy in `/etc/gitlab/gitlab.rb` with
      `praefect['failover_election_strategy'] = 'per_repository'`.

      1. Run `gitlab-ctl reconfigure` on all Praefect nodes. Wait until all of the Praefect processes have restarted and
      the old processes have exited. This can take up to one minute.

      1. Uncomment the secondary Gitaly node configuration commented out in the earlier step on all Praefect nodes.

      1. Run `gitlab-ctl reconfigure` on all Praefect nodes to reconfigure and restart the Praefect processes.

### Deprecated election strategies

WARNING:
The below election strategies are deprecated and are scheduled for removal in GitLab 14.0.
Migrate to [repository-specific primary nodes](#repository-specific-primary-nodes).

- **PostgreSQL:** Enabled by default until GitLab 14.0, and equivalent to:
  `praefect['failover_election_strategy'] = 'sql'`.

  This configuration option:

  - Allows multiple Praefect nodes to coordinate via the PostgreSQL database to elect a primary
    Gitaly node.
  - Causes Praefect nodes to elect a new primary Gitaly node, monitor its health, and elect a new primary
    Gitaly node if the current one is not reached within 10 seconds by a majority of the Praefect
    nodes.
- **Memory:** Enabled by setting `praefect['failover_election_strategy'] = 'local'`
  in `/etc/gitlab/gitlab.rb` on the Praefect node.

  If a sufficient number of health checks fail for the current primary Gitaly node, a new primary is
  elected. **Do not use with multiple Praefect nodes!** Using with multiple Praefect nodes is
  likely to result in a split brain.

## Primary Node Failure

Gitaly Cluster recovers from a failing primary Gitaly node by promoting a healthy secondary as the
new primary.

To minimize data loss, Gitaly Cluster:

- Switches repositories that are outdated on the new primary to [read-only mode](#read-only-mode).
- Elects the secondary with the least unreplicated writes from the primary to be the new primary.
  Because there can still be some unreplicated writes, [data loss can occur](#check-for-data-loss).

### Read-only mode

> - Introduced in GitLab 13.0 as [generally available](https://about.gitlab.com/handbook/product/gitlab-the-product/#generally-available-ga).
> - Between GitLab 13.0 and GitLab 13.2, read-only mode applied to the whole virtual storage and occurred whenever failover occurred.
> - [In GitLab 13.3 and later](https://gitlab.com/gitlab-org/gitaly/-/issues/2862), read-only mode applies on a per-repository basis and only occurs if a new primary is out of date.

When Gitaly Cluster switches to a new primary, repositories enter read-only mode if they are out of
date. This can happen after failing over to an outdated secondary. Read-only mode eases data
recovery efforts by preventing writes that may conflict with the unreplicated writes on other nodes.

To enable writes again, an administrator can:

1. [Check](#check-for-data-loss) for data loss.
1. Attempt to [recover](#data-recovery) missing data.
1. Either [enable writes](#enable-writes-or-accept-data-loss) in the virtual storage or
   [accept data loss](#enable-writes-or-accept-data-loss) if necessary, depending on the version of
   GitLab.

### Check for data loss

The Praefect `dataloss` sub-command identifies replicas that are likely to be outdated. This can help
identify potential data loss after a failover. The following parameters are
available:

- `-virtual-storage` that specifies which virtual storage to check. The default behavior is to
  display outdated replicas of read-only repositories as they might require administrator action.
- In GitLab 13.3 and later, `-partially-replicated` that specifies whether to display a list of
  [outdated replicas of writable repositories](#outdated-replicas-of-writable-repositories).

NOTE:
`dataloss` is still in beta and the output format is subject to change.

To check for repositories with outdated primaries, run:

```shell
sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml dataloss [-virtual-storage <virtual-storage>]
```

Every configured virtual storage is checked if none is specified:

```shell
sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml dataloss
```

Repositories which have assigned storage nodes that contain an outdated copy of the repository are listed
in the output. This information is printed for each repository:

- A repository's relative path to the storage directory identifies each repository and groups the related
  information.
- The repository's current status is printed in parentheses next to the disk path. If the repository's primary
  is outdated, the repository is in `read-only` mode and can't accept writes. Otherwise, the mode is `writable`.
- The primary field lists the repository's current primary. If the repository has no primary, the field shows
  `No Primary`.
- The In-Sync Storages lists replicas which have replicated the latest successful write and all writes
  preceding it.
- The Outdated Storages lists replicas which contain an outdated copy of the repository. Replicas which have no copy
  of the repository but should contain it are also listed here. The maximum number of changes the replica is missing
  is listed next to replica. It's important to notice that the outdated replicas may be fully up to date or contain
  later changes but Praefect can't guarantee it.

Whether a replica is assigned to host the repository is listed with each replica's status. `assigned host` is printed
next to replicas which are assigned to store the repository. The text is omitted if the replica contains a copy of
the repository but is not assigned to store the repository. Such replicas aren't kept in-sync by Praefect, but may
act as replication sources to bring assigned replicas up to date.

Example output:

```shell
Virtual storage: default
  Outdated repositories:
    @hashed/3f/db/3fdba35f04dc8c462986c992bcf875546257113072a909c162f7e470e581e278.git (read-only):
      Primary: gitaly-1
      In-Sync Storages:
        gitaly-2, assigned host
      Outdated Storages:
        gitaly-1 is behind by 3 changes or less, assigned host
        gitaly-3 is behind by 3 changes or less
```

A confirmation is printed out when every repository is writable. For example:

```shell
Virtual storage: default
  All repositories are writable!
```

#### Outdated replicas of writable repositories

> [Introduced](https://gitlab.com/gitlab-org/gitaly/-/issues/3019) in GitLab 13.3.

To also list information of repositories whose primary is up to date but one or more assigned
replicas are outdated, use the `-partially-replicated` flag.

A repository is writable if the primary has the latest changes. Secondaries might be temporarily
outdated while they are waiting to replicate the latest changes.

```shell
sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml dataloss [-virtual-storage <virtual-storage>] [-partially-replicated]
```

Example output:

```shell
Virtual storage: default
  Outdated repositories:
    @hashed/3f/db/3fdba35f04dc8c462986c992bcf875546257113072a909c162f7e470e581e278.git (writable):
      Primary: gitaly-1
      In-Sync Storages:
        gitaly-1, assigned host
      Outdated Storages:
        gitaly-2 is behind by 3 changes or less, assigned host
        gitaly-3 is behind by 3 changes or less
```

With the `-partially-replicated` flag set, a confirmation is printed out if every assigned replica is fully up to
date.

For example:

```shell
Virtual storage: default
  All repositories are up to date!
```

### Check repository checksums

To check a project's repository checksums across on all Gitaly nodes, run the
[replicas Rake task](../raketasks/praefect.md#replica-checksums) on the main GitLab node.

### Enable writes or accept data loss

Praefect provides the following sub-commands to re-enable writes:

- In GitLab 13.2 and earlier, `enable-writes` to re-enable virtual storage for writes after data
  recovery attempts.

   ```shell
   sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml enable-writes -virtual-storage <virtual-storage>
   ```

- [In GitLab 13.3](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/2415) and later,
  `accept-dataloss` to accept data loss and re-enable writes for repositories after data recovery
  attempts have failed. Accepting data loss causes current version of the repository on the
  authoritative storage to be considered latest. Other storages are brought up to date with the
  authoritative storage by scheduling replication jobs.

  ```shell
  sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml accept-dataloss -virtual-storage <virtual-storage> -repository <relative-path> -authoritative-storage <storage-name>
  ```

WARNING:
`accept-dataloss` causes permanent data loss by overwriting other versions of the repository. Data
[recovery efforts](#data-recovery) must be performed before using it.

## Data recovery

If a Gitaly node fails replication jobs for any reason, it ends up hosting outdated versions of the
affected repositories. Praefect provides tools for:

- [Automatic](#automatic-reconciliation) reconciliation, for GitLab 13.4 and later.
- [Manual](#manual-reconciliation) reconciliation, for:
  - GitLab 13.3 and earlier.
  - Repositories upgraded to GitLab 13.4 and later without entries in the `repositories` table. In
    GitLab 13.6 and later, [a migration is run](https://gitlab.com/gitlab-org/gitaly/-/issues/3033)
    when Praefect starts for these repositories.

These tools reconcile the outdated repositories to bring them fully up to date again.

### Automatic reconciliation

> [Introduced](https://gitlab.com/gitlab-org/gitaly/-/issues/2717) in GitLab 13.4.

Praefect automatically reconciles repositories that are not up to date. By default, this is done every
five minutes. For each outdated repository on a healthy Gitaly node, the Praefect picks a
random, fully up-to-date replica of the repository on another healthy Gitaly node to replicate from. A
replication job is scheduled only if there are no other replication jobs pending for the target
repository.

The reconciliation frequency can be changed via the configuration. The value can be any valid
[Go duration value](https://golang.org/pkg/time/#ParseDuration). Values below 0 disable the feature.

Examples:

```ruby
praefect['reconciliation_scheduling_interval'] = '5m' # the default value
```

```ruby
praefect['reconciliation_scheduling_interval'] = '30s' # reconcile every 30 seconds
```

```ruby
praefect['reconciliation_scheduling_interval'] = '0' # disable the feature
```

### Manual reconciliation

WARNING:
The `reconcile` sub-command is deprecated and scheduled for removal in GitLab 14.0. Use
[automatic reconciliation](#automatic-reconciliation) instead. Manual reconciliation may
produce excess replication jobs and is limited in functionality. Manual reconciliation does
not work when [repository-specific primary nodes](#repository-specific-primary-nodes) are
enabled.

The Praefect `reconcile` sub-command allows for the manual reconciliation between two Gitaly nodes. The
command replicates every repository on a later version on the reference storage to the target storage.

```shell
sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml reconcile -virtual <virtual-storage> -reference <up-to-date-storage> -target <outdated-storage> -f
```

- Replace the placeholder `<virtual-storage>` with the virtual storage containing the Gitaly node storage to be checked.
- Replace the placeholder `<up-to-date-storage>` with the Gitaly storage name containing up to date repositories.
- Replace the placeholder `<outdated-storage>` with the Gitaly storage name containing outdated repositories.

## Migrate to Gitaly Cluster

Whether migrating to Gitaly Cluster because of [NFS support deprecation](index.md#nfs-deprecation-notice)
or to move from single Gitaly nodes, the basic process involves:

1. Create the required storage.
1. Create and configure Gitaly Cluster.
1. [Move the repositories](#move-repositories).

When creating the storage, see some
[repository storage recommendations](faq.md#what-are-some-repository-storage-recommendations).

### Move Repositories

To migrate to Gitaly Cluster, existing repositories stored outside Gitaly Cluster must be
moved. There is no automatic migration but the moves can be scheduled with the GitLab API.

GitLab repositories can be associated with projects, groups, and snippets. Each of these types
have a separate API to schedule the respective repositories to move. To move all repositories
on a GitLab instance, each of these types must be scheduled to move for each storage.

Each repository is made read-only for the duration of the move. The repository is not writable
until the move has completed.

After creating and configuring Gitaly Cluster:

1. Ensure all storages are accessible to the GitLab instance. In this example, these are
   `<original_storage_name>` and `<cluster_storage_name>`.
1. [Configure repository storage weights](../repository_storage_paths.md#configure-where-new-repositories-are-stored)
   so that the Gitaly Cluster receives all new projects. This stops new projects from being created
   on existing Gitaly nodes while the migration is in progress.
1. Schedule repository moves for:
   - [Projects](#bulk-schedule-project-moves).
   - [Snippets](#bulk-schedule-snippet-moves).
   - [Groups](#bulk-schedule-group-moves). **(PREMIUM SELF)**

#### Bulk schedule project moves

1. [Schedule repository storage moves for all projects on a storage shard](../../api/project_repository_storage_moves.md#schedule-repository-storage-moves-for-all-projects-on-a-storage-shard) using the API. For example:

   ```shell
   curl --request POST --header "Private-Token: <your_access_token>" \
        --header "Content-Type: application/json" \
        --data '{"source_storage_name":"<original_storage_name>","destination_storage_name":"<cluster_storage_name>"}' \
        "https://gitlab.example.com/api/v4/project_repository_storage_moves"
   ```

1. [Query the most recent repository moves](../../api/project_repository_storage_moves.md#retrieve-all-project-repository-storage-moves)
   using the API. The query indicates either:
   - The moves have completed successfully. The `state` field is `finished`.
   - The moves are in progress. Re-query the repository move until it completes successfully.
   - The moves have failed. Most failures are temporary and are solved by rescheduling the move.

1. After the moves are complete, [query projects](../../api/projects.md#list-all-projects)
   using the API to confirm that all projects have moved. No projects should be returned
   with `repository_storage` field set to the old storage.

   ```shell
   curl --header "Private-Token: <your_access_token>" --header "Content-Type: application/json" \
   "https://gitlab.example.com/api/v4/projects?repository_storage=<original_storage_name>"
   ```

   Alternatively use [the rails console](../operations/rails_console.md) to
   confirm that all projects have moved. Run the following in the rails console:

   ```ruby
   ProjectRepository.for_repository_storage('<original_storage_name>')
   ```

1. Repeat for each storage as required.

#### Bulk schedule snippet moves

1. [Schedule repository storage moves for all snippets on a storage shard](../../api/snippet_repository_storage_moves.md#schedule-repository-storage-moves-for-all-snippets-on-a-storage-shard) using the API. For example:

   ```shell
   curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
        --header "Content-Type: application/json" \
        --data '{"source_storage_name":"<original_storage_name>","destination_storage_name":"<cluster_storage_name>"}' \
        "https://gitlab.example.com/api/v4/snippet_repository_storage_moves"
   ```

1. [Query the most recent repository moves](../../api/snippet_repository_storage_moves.md#retrieve-all-snippet-repository-storage-moves)
   using the API. The query indicates either:
   - The moves have completed successfully. The `state` field is `finished`.
   - The moves are in progress. Re-query the repository move until it completes successfully.
   - The moves have failed. Most failures are temporary and are solved by rescheduling the move.

1. After the moves are complete, use [the rails console](../operations/rails_console.md) to
   confirm that all snippets have moved. No snippets should be returned for the original
   storage. Run the following in the rails console:

   ```ruby
   SnippetRepository.for_repository_storage('<original_storage_name>')
   ```

1. Repeat for each storage as required.

#### Bulk schedule group moves **(PREMIUM SELF)**

1. [Schedule repository storage moves for all groups on a storage shard](../../api/group_repository_storage_moves.md#schedule-repository-storage-moves-for-all-groups-on-a-storage-shard) using the API.

    ```shell
    curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
         --header "Content-Type: application/json" \
         --data '{"source_storage_name":"<original_storage_name>","destination_storage_name":"<cluster_storage_name>"}' \
         "https://gitlab.example.com/api/v4/group_repository_storage_moves"
    ```

1. [Query the most recent repository moves](../../api/group_repository_storage_moves.md#retrieve-all-group-repository-storage-moves)
   using the API. The query indicates either:
   - The moves have completed successfully. The `state` field is `finished`.
   - The moves are in progress. Re-query the repository move until it completes successfully.
   - The moves have failed. Most failures are temporary and are solved by rescheduling the move.

1. After the moves are complete, use [the rails console](../operations/rails_console.md) to
   confirm that all groups have moved. No groups should be returned for the original
   storage. Run the following in the rails console:

   ```ruby
   GroupWikiRepository.for_repository_storage('<original_storage_name>')
   ```

1. Repeat for each storage as required.
