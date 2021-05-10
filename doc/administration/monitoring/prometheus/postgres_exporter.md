---
stage: Monitor
group: Monitor
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# PostgreSQL Server Exporter **(FREE SELF)**

The [PostgreSQL Server Exporter](https://github.com/prometheus-community/postgres_exporter) allows you to export various PostgreSQL metrics.

For installations from source you must install and configure it yourself.

To enable the PostgreSQL Server Exporter:

1. [Enable Prometheus](index.md#configuring-prometheus).
1. Edit `/etc/gitlab/gitlab.rb` and enable `postgres_exporter`:

   ```ruby
   postgres_exporter['enable'] = true
   ```

   If PostgreSQL Server Exporter is configured on a separate node, make sure that the local
   address is [listed in `trust_auth_cidr_addresses`](../../postgresql/replication_and_failover.md#network-information) or the
   exporter can't connect to the database.

1. Save the file and [reconfigure GitLab](../../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to
   take effect.

Prometheus begins collecting performance data from
the PostgreSQL Server Exporter exposed under `localhost:9187`.

## Advanced configuration

In most cases, PostgreSQL Server Exporter works with the defaults and you should not
need to change anything. To further customize the PostgreSQL Server Exporter,
use the following configuration options:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   # The name of the database to connect to.
   postgres_exporter['dbname'] = 'pgbouncer'
   # The user to sign in as.
   postgres_exporter['user'] = 'gitlab-psql'
   # The user's password.
   postgres_exporter['password'] = ''
   # The host to connect to. Values that start with '/' are for unix domain sockets
   # (default is 'localhost').
   postgres_exporter['host'] = 'localhost'
   # The port to bind to (default is '5432').
   postgres_exporter['port'] = 5432
   # Whether or not to use SSL. Valid options are:
   #   'disable' (no SSL),
   #   'require' (always use SSL and skip verification, this is the default value),
   #   'verify-ca' (always use SSL and verify that the certificate presented by
   #   the server was signed by a trusted CA),
   #   'verify-full' (always use SSL and verify that the certification presented
   #   by the server was signed by a trusted CA and the server host name matches
   #   the one in the certificate).
   postgres_exporter['sslmode'] = 'require'
   # An application_name to fall back to if one isn't provided.
   postgres_exporter['fallback_application_name'] = ''
   # Maximum wait for connection, in seconds. Zero or not specified means wait indefinitely.
   postgres_exporter['connect_timeout'] = ''
   # Cert file location. The file must contain PEM encoded data.
   postgres_exporter['sslcert'] = 'ssl.crt'
   # Key file location. The file must contain PEM encoded data.
   postgres_exporter['sslkey'] = 'ssl.key'
   # The location of the root certificate file. The file must contain PEM encoded data.
   postgres_exporter['sslrootcert'] = 'ssl-root.crt'
   ```

1. Save the file and [reconfigure GitLab](../../restart_gitlab.md#omnibus-gitlab-reconfigure)
   for the changes to take effect.
