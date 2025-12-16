---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabパッケージレジストリの管理
description: パッケージレジストリを管理します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabをさまざまな一般的なパッケージマネージャーのプライベートリポジトリとして使用するには、パッケージレジストリを使用します。パッケージをビルドして公開すると、ダウンストリームプロジェクトで依存関係として使用できます。

## サポートされている形式 {#supported-formats}

パッケージレジストリは、次の形式をサポートしています:

| パッケージの種類                                                       | GitLabバージョン |
|--------------------------------------------------------------------|----------------|
| [Composer](../../user/packages/composer_repository/_index.md)      | 13.2+          |
| [Conan 1](../../user/packages/conan_1_repository/_index.md)        | 12.6+          |
| [Conan 2](../../user/packages/conan_2_repository/_index.md)        | 18.1+          |
| [Go](../../user/packages/go_proxy/_index.md)                       | 13.1+          |
| [Maven](../../user/packages/maven_repository/_index.md)            | 11.3+          |
| [npm](../../user/packages/npm_registry/_index.md)                  | 11.7+          |
| [NuGet](../../user/packages/nuget_repository/_index.md)            | 12.8+          |
| [PyPI](../../user/packages/pypi_repository/_index.md)              | 12.10+         |
| [汎用パッケージ](../../user/packages/generic_packages/_index.md) | 13.5+          |
| [Helmチャート](../../user/packages/helm_repository/_index.md)       | 14.1+          |

パッケージレジストリは、[モデルレジストリデータ](../../user/project/ml/model_registry/_index.md)の保存にも使用されます。

## コントリビュートを受け入れる {#accepting-contributions}

次の表に、サポートされていないパッケージ形式を示します。これらの形式のサポートを追加するために、GitLabにコントリビュートすることを検討してください。

<!-- vale gitlab_base.Spelling = NO -->

| 形式 | 状態 |
| ------ | ------ |
| Chef      | [\#36889](https://gitlab.com/gitlab-org/gitlab/-/issues/36889) |
| CocoaPods | [\#36890](https://gitlab.com/gitlab-org/gitlab/-/issues/36890) |
| Conda     | [\#36891](https://gitlab.com/gitlab-org/gitlab/-/issues/36891) |
| CRAN      | [\#36892](https://gitlab.com/gitlab-org/gitlab/-/issues/36892) |
| Debian    | [ドラフト: マージリクエスト](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/50438) |
| Opkg      | [\#36894](https://gitlab.com/gitlab-org/gitlab/-/issues/36894) |
| P2        | [\#36895](https://gitlab.com/gitlab-org/gitlab/-/issues/36895) |
| Puppet    | [\#36897](https://gitlab.com/gitlab-org/gitlab/-/issues/36897) |
| RPM       | [\#5932](https://gitlab.com/gitlab-org/gitlab/-/issues/5932) |
| RubyGems  | [\#803](https://gitlab.com/gitlab-org/gitlab/-/issues/803) |
| SBT       | [\#36898](https://gitlab.com/gitlab-org/gitlab/-/issues/36898) |
| Terraform | [ドラフト: マージリクエスト](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/18834) |
| Vagrant   | [\#36899](https://gitlab.com/gitlab-org/gitlab/-/issues/36899) |

<!-- vale gitlab_base.Spelling = YES -->

## レート制限 {#rate-limits}

ダウンストリームプロジェクトで依存関係としてパッケージをダウンロードする際、Packages APIを介して多くのリクエストが行われます。そのため、強制されたユーザーおよびIPレート制限に達する可能性があります。この問題に対処するには、Packages APIに特定のレート制限を定義できます。詳細については、[パッケージレジストリのレート制限](../settings/package_registry_rate_limits.md)を参照してください。

## パッケージレジストリの有効化または無効化 {#enable-or-disable-the-package-registry}

パッケージレジストリはデフォルトで有効になっています。無効にするには、次の手順に従います: 

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   # Change to true to enable packages - enabled by default if not defined
   gitlab_rails['packages_enabled'] = false
   ```

1. ファイルを保存して、GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

1. Helmの値をエクスポートします: 

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`を編集します: 

   ```yaml
   global:
     appConfig:
       packages:
         enabled: false
   ```

1. ファイルを保存して、新しい値を適用します: 

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`を編集します: 

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['packages_enabled'] = false
   ```

1. ファイルを保存して、GitLabを再起動します: 

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitlab/config/gitlab.yml`を編集します: 

   ```yaml
   production: &base
     packages:
       enabled: false
   ```

1. ファイルを保存して、GitLabを再起動します: 

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

## ストレージパスの変更 {#change-the-storage-path}

デフォルトでは、パッケージはローカルに保存されますが、デフォルトのローカルの場所を変更したり、オブジェクトストレージを使用したりすることもできます。

### ローカルストレージパスの変更 {#change-the-local-storage-path}

デフォルトでは、パッケージはGitLabインストールからの相対的なローカルパスに保存されます:

- Linuxパッケージ（Omnibus）: `/var/opt/gitlab/gitlab-rails/shared/packages/`
- 自己コンパイル（ソース）: `/home/git/gitlab/shared/packages/`

ローカルストレージパスを変更するには:

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集し、次の行を追加します:

   ```ruby
   gitlab_rails['packages_storage_path'] = "/mnt/packages"
   ```

1. ファイルを保存して、GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitlab/config/gitlab.yml`を編集します: 

   ```yaml
   production: &base
     packages:
       enabled: true
       storage_path: /mnt/packages
   ```

1. ファイルを保存して、GitLabを再起動します: 

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

古いストレージパスにパッケージが既に保存されている場合は、既存のパッケージに引き続きアクセスできるように、古い場所から新しい場所にすべて移動します:

```shell
mv /var/opt/gitlab/gitlab-rails/shared/packages/* /mnt/packages/
```

DockerとKubernetesはローカルストレージを使用しません。

- Helmチャート（Kubernetes）の場合: 代わりにオブジェクトストレージを使用してください。
- Dockerの場合: `/var/opt/gitlab/`ディレクトリは、ホスト上のディレクトリにすでにマウントされています。コンテナ内でローカルストレージパスを変更する必要はありません。

### オブジェクトストレージを使用する {#use-object-storage}

ローカルストレージに依存する代わりに、オブジェクトストレージを使用してパッケージを保存できます。

詳細については、[統合されたオブジェクトストレージの設定](../object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form)の使用方法を参照してください。

### オブジェクトストレージとローカルストレージ間でパッケージを移行する {#migrate-packages-between-object-storage-and-local-storage}

オブジェクトストレージを構成した後、次のタスクを使用して、ローカルストレージとリモートストレージ間でパッケージを移行できます。この処理はバックグラウンドワーカーで実行され、ダウンタイムは不要です。

#### オブジェクトストレージに移行する {#migrate-to-object-storage}

1. パッケージをオブジェクトストレージに移行します:

   {{< tabs >}}{{< tab title="Linuxパッケージ（Omnibus）" >}}

   ```shell
   sudo gitlab-rake "gitlab:packages:migrate"
   ```

   {{< /tab >}}{{< tab title="自己コンパイル（ソース）" >}}

   ```shell
   RAILS_ENV=production sudo -u git -H bundle exec rake gitlab:packages:migrate
   ```

   {{< /tab >}}{{< /tabs >}}

1. PostgreSQLコンソールを使用して、進行状況を追跡し、すべてのパッケージを正常に移行したことを確認します:

   {{< tabs >}} {{< tab title="Linuxパッケージ（Omnibus）14.1以前" >}}

   ```shell
   sudo gitlab-rails dbconsole
   ```

   {{< /tab >}} {{< tab title="Linuxパッケージ（Omnibus）14.2以降" >}}

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

   {{< /tab >}}{{< tab title="自己コンパイル（ソース）" >}}

   ```shell
   RAILS_ENV=production sudo -u git -H psql -d gitlabhq_production
   ```

   {{< /tab >}}{{< /tabs >}}

1. 次のSQLクエリを使用して、すべてのパッケージをオブジェクトストレージに移行したことを確認します。`objectstg`の数が`total`と同じである必要があります: 

   ```sql
   SELECT count(*) AS total,
          sum(case when file_store = '1' then 1 else 0 end) AS filesystem,
          sum(case when file_store = '2' then 1 else 0 end) AS objectstg
   FROM packages_package_files;
   ```

   出力例: 

   ```plaintext
   total | filesystem | objectstg
   ------+------------+-----------
    34   |          0 |        34
   ```

1. 最後に、ディスク上の`packages`ディレクトリにファイルがないことを確認します:

   {{< tabs >}}{{< tab title="Linuxパッケージ（Omnibus）" >}}

   ```shell
   sudo find /var/opt/gitlab/gitlab-rails/shared/packages -type f | grep -v tmp | wc -l
   ```

   {{< /tab >}}{{< tab title="自己コンパイル（ソース）" >}}

   ```shell
   sudo -u git find /home/git/gitlab/shared/packages -type f | grep -v tmp | wc -l
   ```

   {{< /tab >}}{{< /tabs >}}

#### オブジェクトストレージからローカルストレージに移行する {#migrate-from-object-storage-to-local-storage}

1. パッケージをオブジェクトストレージからローカルストレージに移行します:

   {{< tabs >}}{{< tab title="Linuxパッケージ（Omnibus）" >}}

   ```shell
   sudo gitlab-rake "gitlab:packages:migrate[local]"
   ```

   {{< /tab >}}{{< tab title="自己コンパイル（ソース）" >}}

   ```shell
   RAILS_ENV=production sudo -u git -H bundle exec rake "gitlab:packages:migrate[local]"
   ```

   {{< /tab >}}{{< /tabs >}}

1. PostgreSQLコンソールを使用して、進行状況を追跡し、すべてのパッケージを正常に移行したことを確認します:

   {{< tabs >}} {{< tab title="Linuxパッケージ（Omnibus）14.1以前" >}}

   ```shell
   sudo gitlab-rails dbconsole
   ```

   {{< /tab >}} {{< tab title="Linuxパッケージ（Omnibus）14.2以降" >}}

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

   {{< /tab >}}{{< tab title="自己コンパイル（ソース）" >}}

   ```shell
   RAILS_ENV=production sudo -u git -H psql -d gitlabhq_production
   ```

   {{< /tab >}}{{< /tabs >}}

1. 次のSQLクエリを使用して、すべてのパッケージがローカルストレージに移行されたことを確認します。`filesystem`の数が`total`と同じである必要があります: 

   ```sql
   SELECT count(*) AS total,
          sum(case when file_store = '1' then 1 else 0 end) AS filesystem,
          sum(case when file_store = '2' then 1 else 0 end) AS objectstg
   FROM packages_package_files;
   ```

   出力例: 

   ```plaintext
   total | filesystem | objectstg
   ------+------------+-----------
    34   |         34 |         0
   ```

1. 最後に、`packages`ディレクトリにファイルが存在することを確認します:

   {{< tabs >}}{{< tab title="Linuxパッケージ（Omnibus）" >}}

   ```shell
   sudo find /var/opt/gitlab/gitlab-rails/shared/packages -type f | grep -v tmp | wc -l
   ```

   {{< /tab >}}{{< tab title="自己コンパイル（ソース）" >}}

   ```shell
   sudo -u git find /home/git/gitlab/shared/packages -type f | grep -v tmp | wc -l
   ```

   {{< /tab >}}{{< /tabs >}}
