---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 新しいインストール用のコンテナレジストリメタデータデータベース
description: 新しいインストール用にコンテナレジストリメタデータデータベースを有効にします。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

インスタンスのコンテナレジストリメタデータデータベースを有効にします。

## メタデータデータベースを有効にする {#enable-the-metadata-database}

新しいコンテナレジストリのメタデータデータベースを有効にします。

{{< tabs >}}

{{< tab title="GitLab 18.3以降" >}}

前提条件: 

- イメージがレジストリにプッシュされていない新しいコンテナレジストリが必要です。

データベースを有効にするには、次の手順を実行します:

1. `/etc/gitlab/gitlab.rb`を編集し、`enabled`を`true`に設定して、データベースを有効にします:

   ```ruby
   registry['database'] = {
     'enabled' => true,
   }
   ```

1. ファイルを保存して[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

{{< /tab >}}

{{< tab title="GitLab 17.5～18.2" >}}

前提条件: 

- イメージがレジストリにプッシュされていない新しいコンテナレジストリが必要です。
- [外部データベース](../postgresql/external.md#container-registry-metadata-database)を作成します。

データベースを有効にするには、次の手順を実行します:

1. データベース接続の詳細を追加して`/etc/gitlab/gitlab.rb`を編集しますが、まずメタデータデータベースを無効にして起動します:

   ```ruby
   registry['database'] = {
     'enabled' => false,
     'host' => '<registry_database_host_placeholder_change_me>',
     'port' => 5432, # Default, but set to the port of your database instance if it differs.
     'user' => '<registry_database_username_placeholder_change_me>',
     'password' => '<registry_database_placeholder_change_me>',
     'dbname' => '<registry_database_name_placeholder_change_me>',
     'sslmode' => 'require', # See the PostgreSQL documentation for additional information https://www.postgresql.org/docs/16/libpq-ssl.html.
     'sslcert' => '</path/to/cert.pem>',
     'sslkey' => '</path/to/private.key>',
     'sslrootcert' => '</path/to/ca.pem>'
   }
   ```

1. ファイルを保存して[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。
1. [データベース移行を適用する](container_registry_metadata_database.md#apply-database-migrations)。
1. `/etc/gitlab/gitlab.rb`を編集し、`enabled`を`true`に設定して、データベースを有効にします:

   ```ruby
   registry['database'] = {
     'enabled' => true,
     'host' => '<registry_database_host_placeholder_change_me>',
     'port' => 5432, # Default, but set to the port of your database instance if it differs.
     'user' => '<registry_database_username_placeholder_change_me>',
     'password' => '<registry_database_placeholder_change_me>',
     'dbname' => '<registry_database_name_placeholder_change_me>',
     'sslmode' => 'require', # See the PostgreSQL documentation for additional information https://www.postgresql.org/docs/16/libpq-ssl.html.
     'sslcert' => '</path/to/cert.pem>',
     'sslkey' => '</path/to/private.key>',
     'sslrootcert' => '</path/to/ca.pem>'
   }
   ```

{{< /tab >}}

{{< /tabs >}}

これで、すべての操作にメタデータデータベースを使用できるようになりました。
