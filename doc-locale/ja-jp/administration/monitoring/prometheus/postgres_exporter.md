---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: PostgreSQL Server exporter
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

この[PostgreSQL Server exporter](https://github.com/prometheus-community/postgres_exporter)を使用すると、様々なPostgreSQLメトリクスをエクスポートできます。

自己コンパイルによるインストール環境では、ユーザー自身がPrometheusをインストールして設定する必要があります。

PostgreSQL Server exporterを有効にするには:

1. [Prometheusを有効にする](_index.md#configuring-prometheus)。
1. `/etc/gitlab/gitlab.rb`を編集し、`postgres_exporter`を有効にします:

   ```ruby
   postgres_exporter['enable'] = true
   ```

   PostgreSQL Server exporterが別のノードで設定されている場合、ローカルアドレスが[`trust_auth_cidr_addresses`にリストされている](../../postgresql/replication_and_failover.md#network-information)ことを確認してください。そうでないと、exporterがデータベースに接続できません。

1. ファイルを保存して、[GitLabを再設定](../../restart_gitlab.md#reconfigure-a-linux-package-installation)し、変更を有効にします。

Prometheusは、`localhost:9187`で公開されているPostgreSQL Server exporterからパフォーマンスデータの収集を開始します。

## 高度な設定 {#advanced-configuration}

ほとんどの場合、PostgreSQL Server exporterはデフォルトで動作するため、何も変更する必要はありません。PostgreSQL Server exporterをさらにカスタマイズするには、次の設定オプションを使用します:

1. `/etc/gitlab/gitlab.rb`を編集します:

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

1. ファイルを保存して、[GitLabを再設定](../../restart_gitlab.md#reconfigure-a-linux-package-installation)し、変更を有効にします。
