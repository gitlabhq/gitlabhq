---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 1ステップのインポート
description: コンテナレジストリメタデータデータベースをワンステップで有効にします。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

[オフラインガベージコレクション](container_registry.md#container-registry-garbage-collection)を定期的に実行する場合は、ワンステップインポート方式を使用してください。この方法は、3段階のインポート方法よりも簡単な操作です。

## ワンステップインポート {#one-step-import}

> [!warning]レジストリは、インポート中はシャットダウンするか、`read-only`モードのままにする必要があります。そうしないと、インポート中に書き込まれたデータにアクセスできなくなったり、不整合が発生したりする可能性があります。

{{< tabs >}}

{{< tab title="GitLab 18.3以降" >}}

1. `/etc/gitlab/gitlab.rb`ファイルの`registry['database']`セクションで、データベースが無効になっていることを確認します:

   ```ruby
   registry['database'] = {
     'enabled' => false, # Must be false!
   }
   ```

1. レジストリが`read-only`読み取り専用モードに設定されていることを確認します。

   `/etc/gitlab/gitlab.rb`を編集し、`maintenance`セクションを`registry['storage']`設定に追加します。たとえば、`gcs`バックエンドレジストリで`gs://my-company-container-registry`バケットを使用する場合、設定は次のようになります:

   ```ruby
   ## Object Storage - Container Registry
   registry['storage'] = {
     'gcs' => {
       'bucket' => '<my-company-container-registry>',
       'chunksize' => 5242880
     },
     'maintenance' => {
       'readonly' => {
         'enabled' => true # Must be set to true.
       }
     }
   }
   ```

1. ファイルを保存して[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。
1. [データベースの移行を適用](container_registry_metadata_database.md#apply-database-migrations)。
1. 次のコマンドを実行します:

   ```shell
   sudo -u registry gitlab-ctl registry-database import --log-to-stdout
   ```

1. コマンドが正常に完了すると、レジストリは完全にインポートされます。データベースを有効にし、設定で読み取り専用モードをオフにして、レジストリサービスを開始できます:

   ```ruby
   registry['database'] = {
     'enabled' => true, # Must be enabled now!
   }

   ## Object Storage - Container Registry
   registry['storage'] = {
     'gcs' => {
       'bucket' => '<my-company-container-registry>',
       'chunksize' => 5242880
     },
     'maintenance' => {
       'readonly' => {
         'enabled' => false
       }
     }
   }
   ```

1. ファイルを保存して[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

{{< /tab >}}

{{< tab title="GitLab 17.5～18.2" >}}

前提条件: 

- [外部データベース](../postgresql/external.md#container-registry-metadata-database)を作成します。

1. `/etc/gitlab/gitlab.rb`ファイルに`database`セクションを追加しますが、最初にメタデータデータベースを無効にして開始します:

   ```ruby
   registry['database'] = {
     'enabled' => false, # Must be false!
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

1. レジストリが`read-only`読み取り専用モードに設定されていることを確認します。

   `/etc/gitlab/gitlab.rb`を編集し、`maintenance`セクションを`registry['storage']`設定に追加します。たとえば、`gcs`バックのレジストリで`gs://my-company-container-registry`バケットを使用する場合、設定は次のようになります:

   ```ruby
   ## Object Storage - Container Registry
   registry['storage'] = {
     'gcs' => {
       'bucket' => '<my-company-container-registry>',
       'chunksize' => 5242880
     },
     'maintenance' => {
       'readonly' => {
         'enabled' => true # Must be set to true.
       }
     }
   }
   ```

1. ファイルを保存して[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。
1. まだ[データベースの移行を適用](container_registry_metadata_database.md#apply-database-migrations)していない場合。
1. 次のコマンドを実行します:

   ```shell
   sudo gitlab-ctl registry-database import
   ```

1. コマンドが正常に完了すると、レジストリは完全にインポートされます。データベースを有効にし、設定で読み取り専用モードをオフにして、レジストリサービスを開始できるようになりました:

   ```ruby
   registry['database'] = {
     'enabled' => true, # Must be enabled now!
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

   ## Object Storage - Container Registry
   registry['storage'] = {
     'gcs' => {
       'bucket' => '<my-company-container-registry>',
       'chunksize' => 5242880
     },
     'maintenance' => {
       'readonly' => {
         'enabled' => false
       }
     }
   }
   ```

1. ファイルを保存して[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

{{< /tab >}}

{{< /tabs >}}

すべての操作でメタデータデータベースを使用できるようになりました。
