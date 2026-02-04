---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 3ステップのインポート
description: ダウンタイムを最小限に抑えて、コンテナレジストリメタデータデータベースを有効にします。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

既存のコンテナレジストリメタデータをインポートします。以下の手順は、大規模なレジストリ（200 GiB以上）の場合、またはインポートの完了時にダウンタイムを最小限に抑えたい場合に推奨されます。

## リポジトリの事前インポート（ステップ1） {#pre-import-repositories-step-one}

ステップ1のインポートが完了した速度は、[1時間あたり2 ～ 4 TB](https://gitlab.com/gitlab-org/gitlab/-/issues/423459)であると報告されています。速度が遅い場合、100TBを超えるデータを持つレジストリでは、48時間以上かかる可能性があります。

ステップ1の完了中も、通常どおりレジストリを使用し続けることができます。

{{< tabs >}}

{{< tab title="GitLab 18.3以降" >}}

1. `/etc/gitlab/gitlab.rb`ファイルの`database`セクションで、データベースが無効になっていることを確認します:

   ```ruby
   registry['database'] = {
     'enabled' => false, # Must be false!
   }
   ```

1. ファイルを保存して[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。
1. [データベースの移行を適用](container_registry_metadata_database.md#apply-database-migrations)します。
1. 最初の手順を実行して、インポートを開始します:

   ```shell
   sudo -u registry gitlab-ctl registry-database import --step-one --log-to-stdout
   ```

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

1. ファイルを保存して[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。
1. [データベースの移行を適用](container_registry_metadata_database.md#apply-database-migrations)します（まだ行っていない場合）。
1. 最初の手順を実行して、インポートを開始します:

   ```shell
   sudo gitlab-ctl registry-database import --step-one
   ```

{{< /tab >}}

{{< /tabs >}}

{{< alert type="note" >}}

必要なダウンタイムを削減するために、できるだけ早く次のステップをスケジュールしてください。理想的には、ステップ1の完了後1週間以内です。ステップ1とステップ2の間にレジストリに書き込まれた新しいデータは、ステップ2の時間を長くします。

{{< /alert >}}

## すべてのリポジトリデータをインポートする（ステップ2） {#import-all-repository-data-step-two}

このステップでは、レジストリをシャットダウンするか、`read-only`読み取り専用モードに設定する必要があります。ただし、このステップはステップ1よりも約90% 早く完了すると予想できます。ステップ2の実行中は、ダウンタイムのために十分な時間を確保してください。

{{< tabs >}}

{{< tab title="GitLab 18.3以降" >}}

1. レジストリが`read-only`読み取り専用モードに設定されていることを確認します。

   `/etc/gitlab/gitlab.rb`を編集し、`maintenance`セクションを`registry['storage']`設定に追加します。たとえば、`gcs`バックエンドレジストリで、`gs://my-company-container-registry`バケットを使用している場合、設定は次のようになります:

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
1. インポートのステップ2を実行します:

   ```shell
   sudo -u registry gitlab-ctl registry-database import --step-two --log-to-stdout
   ```

1. コマンドが正常に完了すると、すべてのイメージが完全にインポートされます。データベースを有効にし、設定で読み取り専用モードをオフにして、レジストリサービスを開始できるようになりました:

   ```ruby
   registry['database'] = {
     'enabled' => true, # Must be set to true!
   }

   ## Object Storage - Container Registry
   registry['storage'] = {
     'gcs' => {
       'bucket' => '<my-company-container-registry>',
       'chunksize' => 5242880
     },
     'maintenance' => { # This section can be removed.
       'readonly' => {
         'enabled' => false
       }
     }
   }
   ```

1. ファイルを保存して[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

{{< /tab >}}

{{< tab title="GitLab 17.5～18.2" >}}

1. レジストリが`read-only`読み取り専用モードに設定されていることを確認します。

   `/etc/gitlab/gitlab.rb`を編集し、`maintenance`セクションを`registry['storage']`設定に追加します。たとえば、`gs://my-company-container-registry`バケットを使用するバックエンド`gcs`レジストリの場合、設定は次のようになります:

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
1. インポートのステップ2を実行します:

   ```shell
   sudo gitlab-ctl registry-database import --step-two
   ```

1. コマンドが正常に完了すると、すべてのイメージが完全にインポートされます。データベースを有効にし、設定で読み取り専用モードをオフにして、レジストリサービスを開始できるようになりました:

   ```ruby
   registry['database'] = {
     'enabled' => true, # Must be set to true!
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
     'maintenance' => { # This section can be removed.
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

## 残りのデータをインポートする（ステップ3） {#import-remaining-data-step-three}

レジストリは現在、メタデータにデータベースを完全に使用していますが、オンラインガベージコレクターによってこれらのblobが削除されるのを防ぐ、潜在的に未使用のレイヤーblobにまだアクセスできません。

ステップ3の完了中も、通常どおりレジストリを使用し続けることができます。

プロセスを完了するには、移行の最終ステップを実行します:

{{< tabs >}}

{{< tab title="GitLab 18.3以降" >}}

```shell
sudo -u registry gitlab-ctl registry-database import --step-three --log-to-stdout
```

{{< /tab >}}

{{< tab title="GitLab 17.5～18.2" >}}

```shell
sudo gitlab-ctl registry-database import --step-three
```

{{< /tab >}}

{{< /tabs >}}

そのコマンドが正常に終了すると、レジストリメタデータがデータベースに完全にインポートされます。
