---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: PostgreSQL Server Exporter
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Le [PostgreSQL Server Exporter](https://github.com/prometheus-community/postgres_exporter) vous permet d'exporter diverses métriques PostgreSQL.

Pour les installations auto-compilées, vous devez l'installer et le configurer vous-même.

Pour activer le PostgreSQL Server Exporter :

1. [Activer Prometheus](_index.md#configuring-prometheus).
1. Modifiez `/etc/gitlab/gitlab.rb` et activez `postgres_exporter` :

   ```ruby
   postgres_exporter['enable'] = true
   ```

   Si le PostgreSQL Server Exporter est configuré sur un nœud distinct, assurez-vous que l'adresse locale est [répertoriée dans `trust_auth_cidr_addresses`](../../postgresql/replication_and_failover.md#network-information) ou l'exportateur ne pourra pas se connecter à la base de données.

1. Enregistrez le fichier et [reconfigurez GitLab](../../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

Prometheus commence à collecter des données de performance depuis le PostgreSQL Server Exporter exposé sous `localhost:9187`.

## Configuration avancée {#advanced-configuration}

Dans la plupart des cas, le PostgreSQL Server Exporter fonctionne avec les paramètres par défaut et vous ne devriez pas avoir besoin de modifier quoi que ce soit. Pour personnaliser davantage le PostgreSQL Server Exporter, utilisez les options de configuration suivantes :

1. Modifiez `/etc/gitlab/gitlab.rb` :

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

1. Enregistrez le fichier et [reconfigurez GitLab](../../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.
