---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Linuxパッケージインストール用のスタンドアロンPostgreSQL
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabアプリケーションサーバーとは別にデータベースサービスをホストしたい場合は、PostgreSQLバイナリとLinuxパッケージを組み合わせて使用できます。これは、当社の[リファレンスアーキテクチャで最大40 RPSまたは2,000ユーザー向け](../reference_architectures/2k_users.md)の一部として推奨されています。

## セットアップ {#setting-it-up}

1. SSHでPostgreSQLサーバーに接続します。
1. GitLabダウンロードページの手順1と2を使用して、必要なLinuxパッケージを[ダウンロードしてインストール](https://about.gitlab.com/install/)します。ダウンロードページの他の手順は完了しないでください。
1. PostgreSQLのパスワードハッシュを生成します。これは、デフォルトのユーザー名である`gitlab`（推奨）を使用していることを前提としています。コマンドは、パスワードと確認を要求します。次の手順で、このコマンドによって出力された値を`POSTGRESQL_PASSWORD_HASH`の値として使用します。

   ```shell
   sudo gitlab-ctl pg-password-md5 gitlab
   ```

1. `/etc/gitlab/gitlab.rb`を編集し、以下の内容を追加して、プレースホルダーの値を適切に更新します。

   - `POSTGRESQL_PASSWORD_HASH` - 前の手順からの出力値
   - `APPLICATION_SERVER_IP_BLOCKS` - データベースに接続するGitLabアプリケーションサーバーのIPサブネットまたはIPアドレスのスペース区切りリスト。例: `%w(123.123.123.123/32 123.123.123.234/32)`

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
   postgresql['trust_auth_cidr_addresses'] = %w(APPLICATION_SERVER_IP_BLOCKS)

   # Disable automatic database migrations
   gitlab_rails['auto_migrate'] = false
   ```

1. 変更を有効にするため、[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。
1. PostgreSQLノードのIPアドレスまたはホスト名、ポート、およびプレーンテキストパスワードをメモしておきます。これらは、GitLabアプリケーションサーバーを後で設定する際に必要になります。
1. [モニタリングを有効にする](replication_and_failover.md#enable-monitoring)

高度な設定オプションがサポートされており、必要に応じて追加できます。
