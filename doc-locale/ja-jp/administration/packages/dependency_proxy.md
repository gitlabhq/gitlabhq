---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab依存プロキシの管理
description: 頻繁にアクセスされるアップストリームアーティファクト（コンテナイメージやパッケージなど）のGitLab依存プロキシを管理するための管理者ガイド。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/gitlab/-/issues/7934)されたのは、[GitLab Premium](https://about.gitlab.com/pricing/) 11.11です。
- [移行](https://gitlab.com/gitlab-org/gitlab/-/issues/273655)されたのは、GitLab PremiumからGitLab Freeへの13.6です。

{{< /history >}}

GitLabを、コンテナイメージやパッケージなど、頻繁にアクセスされるアップストリームアーティファクトの依存プロキシとして使用できます。

これは管理者向けのドキュメントです。依存プロキシの使用方法については、以下を参照してください:

- [コンテナイメージ](../../user/packages/dependency_proxy/_index.md)の依存プロキシのユーザーガイド
- [仮想レジストリ](../../user/packages/virtual_registry/_index.md)ユーザーガイド

GitLab依存プロキシ:

- デフォルトでオンになっています。
- 管理者がオフにすることができます。

## 依存プロキシをオフにする {#turn-off-the-dependency-proxy}

依存プロキシはデフォルトで有効になっています。管理者の場合、依存プロキシをオフにすることができます。依存プロキシをオフにするには、GitLabインスタンスに対応する手順に従ってください。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集して、次の行を追加します:

   ```ruby
   gitlab_rails['dependency_proxy_enabled'] = false
   ```

1. ファイルを保存して、[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)し、変更を有効にします。

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

インストールが完了したら、グローバルの`appConfig`を更新して、依存プロキシをオフにします:

```yaml
global:
  appConfig:
    dependencyProxy:
      enabled: false
      bucket: gitlab-dependency-proxy
      connection:
        secret:
        key:
```

詳細については、[グローバルを使用したチャートの設定](https://docs.gitlab.com/charts/charts/globals.html#configure-appconfig-settings)を参照してください。

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. インストールが完了したら、`config/gitlab.yml`の`dependency_proxy`セクションを設定します。依存プロキシをオフにするには、`enabled`を`false`に設定します:

   ```yaml
   dependency_proxy:
     enabled: false
   ```

1. 変更を反映させるため、[GitLabを再起動](../restart_gitlab.md#self-compiled-installations)します。

{{< /tab >}}

{{< /tabs >}}

### マルチノードGitLabインストール {#multi-node-gitlab-installations}

各ウェブとSidekiqノードのLinuxパッケージインストールの手順に従ってください。

## 依存プロキシをオンにする {#turn-on-the-dependency-proxy}

依存プロキシはデフォルトでオンになっていますが、管理者がオフにすることができます。手動でオフにするには、[Dependency Proxyをオフにする](#turn-off-the-dependency-proxy)の手順に従ってください。

## ストレージパスの変更 {#changing-the-storage-path}

デフォルトでは、依存プロキシファイルはローカルに保存されますが、デフォルトのローカルの場所を変更したり、オブジェクトストレージを使用したりすることもできます。

### ローカルストレージパスの変更 {#changing-the-local-storage-path}

Linuxパッケージインストールの依存プロキシファイルは`/var/opt/gitlab/gitlab-rails/shared/dependency_proxy/`に、ソースインストールの場合は`shared/dependency_proxy/`（Gitホームディレクトリからの相対パス）に保存されます。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集して、次の行を追加します:

   ```ruby
   gitlab_rails['dependency_proxy_storage_path'] = "/mnt/dependency_proxy"
   ```

1. ファイルを保存して、[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)し、変更を有効にします。

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `config/gitlab.yml`の`dependency_proxy`セクションを編集します:

   ```yaml
   dependency_proxy:
     enabled: true
     storage_path: shared/dependency_proxy
   ```

1. 変更を反映させるため、[GitLabを再起動](../restart_gitlab.md#self-compiled-installations)します。

{{< /tab >}}

{{< /tabs >}}

### オブジェクトストレージを使用する {#using-object-storage}

ローカルストレージに頼る代わりに、[統合されたオブジェクトストレージ設定](../object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form)を使用できます。このセクションでは、以前の設定形式について説明します。[移行手順は引き続き適用されます](#migrate-local-dependency-proxy-blobs-and-manifests-to-object-storage)。

[GitLabにおけるオブジェクトストレージの使用の詳細については、こちらをご覧ください](../object_storage.md)。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集し、次の行を追加します（必要に応じてコメントを解除）:

   ```ruby
   gitlab_rails['dependency_proxy_enabled'] = true
   gitlab_rails['dependency_proxy_storage_path'] = "/var/opt/gitlab/gitlab-rails/shared/dependency_proxy"
   gitlab_rails['dependency_proxy_object_store_enabled'] = true
   gitlab_rails['dependency_proxy_object_store_remote_directory'] = "dependency_proxy" # The bucket name.
   gitlab_rails['dependency_proxy_object_store_proxy_download'] = false        # Passthrough all downloads via GitLab instead of using Redirects to Object Storage.
   gitlab_rails['dependency_proxy_object_store_connection'] = {
     ##
     ## If the provider is AWS S3, uncomment the following
     ##
     #'provider' => 'AWS',
     #'region' => 'eu-west-1',
     #'aws_access_key_id' => 'AWS_ACCESS_KEY_ID',
     #'aws_secret_access_key' => 'AWS_SECRET_ACCESS_KEY',
     ##
     ## If the provider is other than AWS (an S3-compatible one), uncomment the following
     ##
     #'host' => 's3.amazonaws.com',
     #'aws_signature_version' => 4             # For creation of signed URLs. Set to 2 if provider does not support v4.
     #'endpoint' => 'https://s3.amazonaws.com' # Useful for S3-compliant services such as DigitalOcean Spaces.
     #'path_style' => false                    # If true, use 'host/bucket_name/object' instead of 'bucket_name.host/object'.
   }
   ```

1. ファイルを保存して、[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)し、変更を有効にします。

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `config/gitlab.yml`の`dependency_proxy`セクションを編集します（必要に応じてコメントを解除）:

   ```yaml
   dependency_proxy:
     enabled: true
     ##
     ## The location where build dependency_proxy are stored (default: shared/dependency_proxy).
     ##
     # storage_path: shared/dependency_proxy
     object_store:
       enabled: false
       remote_directory: dependency_proxy  # The bucket name.
       #  proxy_download: false     # Passthrough all downloads via GitLab instead of using Redirects to Object Storage.
       connection:
       ##
       ## If the provider is AWS S3, use the following
       ##
         provider: AWS
         region: us-east-1
         aws_access_key_id: AWS_ACCESS_KEY_ID
         aws_secret_access_key: AWS_SECRET_ACCESS_KEY
         ##
         ## If the provider is other than AWS (an S3-compatible one), comment out the previous 4 lines and use the following instead:
         ##
         #  host: 's3.amazonaws.com'             # default: s3.amazonaws.com.
         #  aws_signature_version: 4             # For creation of signed URLs. Set to 2 if provider does not support v4.
         #  endpoint: 'https://s3.amazonaws.com' # Useful for S3-compliant services such as DigitalOcean Spaces.
         #  path_style: false                    # If true, use 'host/bucket_name/object' instead of 'bucket_name.host/object'.
   ```

1. 変更を反映させるため、[GitLabを再起動](../restart_gitlab.md#self-compiled-installations)します。

{{< /tab >}}

{{< /tabs >}}

#### ローカル依存プロキシのblobとマニフェストをオブジェクトストレージに移行する {#migrate-local-dependency-proxy-blobs-and-manifests-to-object-storage}

[オブジェクトストレージを設定した後](#using-object-storage)、次のタスクを使用して、既存の依存プロキシのblobとマニフェストをローカルストレージからリモートストレージに移行します。この処理はバックグラウンドワーカーで実行され、ダウンタイムは不要です。

- Linuxパッケージインストールの場合:

  ```shell
  sudo gitlab-rake "gitlab:dependency_proxy:migrate"
  ```

- 自己コンパイルによるインストールの場合: 

  ```shell
  RAILS_ENV=production sudo -u git -H bundle exec rake gitlab:dependency_proxy:migrate
  ```

オプションで、[PostgreSQLコンソール](https://docs.gitlab.com/omnibus/settings/database.html#connecting-to-the-bundled-postgresql-database)を使用して、すべての依存プロキシのblobとマニフェストが正常に移行されたことを追跡し、検証できます:

- バージョン14.1以前のLinuxパッケージインストールを実行している場合は`sudo gitlab-rails dbconsole`。
- バージョン14.2以降のLinuxパッケージインストールを実行している場合は`sudo gitlab-rails dbconsole --database main`。
- 自己コンパイルインスタンスの場合は`sudo -u git -H psql -d gitlabhq_production`。

`objectstg`（`file_store = '2'`の場合）に、それぞれのクエリに対するすべての依存プロキシのblobとマニフェストのカウントがあることを確認します:

```shell
gitlabhq_production=# SELECT count(*) AS total, sum(case when file_store = '1' then 1 else 0 end) AS filesystem, sum(case when file_store = '2' then 1 else 0 end) AS objectstg FROM dependency_proxy_blobs;

total | filesystem | objectstg
------+------------+-----------
 22   |          0 |        22

gitlabhq_production=# SELECT count(*) AS total, sum(case when file_store = '1' then 1 else 0 end) AS filesystem, sum(case when file_store = '2' then 1 else 0 end) AS objectstg FROM dependency_proxy_manifests;

total | filesystem | objectstg
------+------------+-----------
 10   |          0 |        10
```

ディスク上の`dependency_proxy`フォルダーにファイルがないことを確認します:

```shell
sudo find /var/opt/gitlab/gitlab-rails/shared/dependency_proxy -type f | grep -v tmp | wc -l
```

## JWT有効期限の変更 {#changing-the-jwt-expiration}

依存プロキシは[Docker v2トークン認証フロー](https://distribution.github.io/distribution/spec/auth/token/)に従い、プルリクエストに使用するJSON Webトークンをクライアントに発行します。トークン有効期限は、アプリケーション設定`container_registry_token_expire_delay`を使用して設定可能です。これは、Railsコンソールから変更できます:

```ruby
# update the JWT expiration to 30 minutes
ApplicationSetting.update(container_registry_token_expire_delay: 30)
```

デフォルトの有効期限とGitLab.comの有効期限は15分です。

## プロキシの背後で依存プロキシを使用する {#using-the-dependency-proxy-behind-a-proxy}

1. `/etc/gitlab/gitlab.rb`を編集し、次の行を追加します:

   ```ruby
   gitlab_workhorse['env'] = {
     "http_proxy" => "http://USERNAME:PASSWORD@example.com:8080",
     "https_proxy" => "http://USERNAME:PASSWORD@example.com:8080"
   }
   ```

1. ファイルを保存して、[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)し、変更を有効にします。
