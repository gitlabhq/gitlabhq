---
stage: Verify
group: Mobile DevOps
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: セキュアファイルの管理
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 15.7で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/350748)になり、機能フラグ`ci_secure_files`は削除されました。

{{< /history >}}

CI/CDパイプラインで使用するために最大100個のファイルをセキュアファイルとして安全に保存できます。これらのファイルは、プロジェクトのリポジトリの外部に安全に保存され、バージョン管理は行われません。これらのファイルに機密情報を安全に保存できます。セキュアファイルは、プレーンテキストとバイナリの両方のファイル形式をサポートしていますが、5 MB以下である必要があります。

これらのファイルのストレージの場所は、以下に説明するオプションを使用して構成できますが、デフォルトの場所は次のとおりです:

- `/var/opt/gitlab/gitlab-rails/shared/ci_secure_files`は、Linuxパッケージを使用するインストールの場合です。
- 自己コンパイルによるインストールの場合: `/home/git/gitlab/shared/ci_secure_files`。

[GitLab Helmチャート](https://docs.gitlab.com/charts/)インストールでは、[外部オブジェクトストレージ](https://docs.gitlab.com/charts/advanced/external-object-storage/#lfs-artifacts-uploads-packages-external-diffs-terraform-state-dependency-proxy)の設定を使用します。

## セキュアファイルを無効にする {#disabling-secure-files}

GitLabインスタンス全体でセキュアファイルを無効にできます。ディスク容量を削減したり、機能へのアクセスを削除したりするために、セキュアファイルを無効にする場合があります。

セキュアファイルを無効にするには、インストールに応じて以下の手順に従ってください。

前提要件: 

- 管理者である必要があります。

**Linuxパッケージインストールの場合**:

1. `/etc/gitlab/gitlab.rb`を編集して、次の行を追加します:

   ```ruby
   gitlab_rails['ci_secure_files_enabled'] = false
   ```

1. ファイルを保存して[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

**セルフコンパイルインストール**の場合:

1. `/home/git/gitlab/config/gitlab.yml`を編集し、次の行を追加または修正します:

   ```yaml
   ci_secure_files:
     enabled: false
   ```

1. ファイルを保存して、[GitLabを再起動](../restart_gitlab.md#self-compiled-installations)し、変更を有効にします。

## ローカルストレージの使用 {#using-local-storage}

デフォルトの設定ではローカルストレージが使用されます。セキュアファイルがローカルに保存される場所を変更するには、以下の手順に従ってください。

**Linuxパッケージインストールの場合**:

1. ストレージパスを`/mnt/storage/ci_secure_files`に変更するには、`/etc/gitlab/gitlab.rb`を編集し、次の行を追加します:

   ```ruby
   gitlab_rails['ci_secure_files_storage_path'] = "/mnt/storage/ci_secure_files"
   ```

1. ファイルを保存して[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

**セルフコンパイルインストール**の場合:

1. ストレージパスを`/mnt/storage/ci_secure_files`に変更するには、`/home/git/gitlab/config/gitlab.yml`を編集し、次の行を追加または修正します:

   ```yaml
   ci_secure_files:
     enabled: true
     storage_path: /mnt/storage/ci_secure_files
   ```

1. ファイルを保存して、[GitLabを再起動](../restart_gitlab.md#self-compiled-installations)し、変更を有効にします。

## オブジェクトストレージの使用 {#using-object-storage}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

セキュアファイルをディスクに保存する代わりに、[サポートされているオブジェクトストレージオプション](../object_storage.md#supported-object-storage-providers)のいずれかを使用する必要があります。この設定は、有効な認証情報がすでに設定されていることを前提としています。

### 統合された形式のオブジェクトストレージ {#consolidated-object-storage}

{{< history >}}

- 統合されたオブジェクトストレージのサポートがGitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149873)されました。

{{< /history >}}

オブジェクトストレージの[統合された形式](../object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form)を使用することをお勧めします。

### ストレージ固有のオブジェクトストレージ {#storage-specific-object-storage}

次の設定があります:

- 自己コンパイルによるインストールでは、設定は`ci_secure_files:`の下の`object_store:`にネストされます。
- Linuxパッケージインストールでは、プレフィックスとして`ci_secure_files_object_store_`が付きます。

| 設定 | 説明 | デフォルト |
|---------|-------------|---------|
| `enabled` | オブジェクトストレージを有効または無効にします。 | `false` |
| `remote_directory` | セキュアファイルが保存されているバケット名 | |
| `connection` | 以下に、さまざまな接続オプションを示します。 | |

### S3互換設定 {#s3-compatible-connection-settings}

[プロバイダーごとの使用可能な接続設定](../object_storage.md#configure-the-connection-settings)を参照してください。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集し、必要な値に置き換えて次の行を追加します:

   ```ruby
   gitlab_rails['ci_secure_files_object_store_enabled'] = true
   gitlab_rails['ci_secure_files_object_store_remote_directory'] = "ci_secure_files"
   gitlab_rails['ci_secure_files_object_store_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'aws_access_key_id' => 'AWS_ACCESS_KEY_ID',
     'aws_secret_access_key' => 'AWS_SECRET_ACCESS_KEY'
   }
   ```

  {{< alert type="note" >}}

  AWS IAMプロファイルを使用している場合は、AWSアクセスキーおよびシークレットアクセスキー/キー/バリューペアを省略してください:

  {{< /alert >}}

   ```ruby
   gitlab_rails['ci_secure_files_object_store_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'use_iam_profile' => true
   }
   ```

1. ファイルを保存して、GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. [オブジェクトストレージに既存のローカル状態を移行する](#migrate-to-object-storage)。

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitlab/config/gitlab.yml`を編集し、次の行を追加または修正します:

   ```yaml
   ci_secure_files:
     enabled: true
     object_store:
       enabled: true
       remote_directory: "ci_secure_files"  # The bucket name
       connection:
         provider: AWS  # Only AWS supported at the moment
         aws_access_key_id: AWS_ACCESS_KEY_ID
         aws_secret_access_key: AWS_SECRET_ACCESS_KEY
         region: eu-central-1
   ```

1. ファイルを保存して、GitLabを再起動します:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

1. [オブジェクトストレージに既存のローカル状態を移行する](#migrate-to-object-storage)。

{{< /tab >}}

{{< /tabs >}}

### オブジェクトストレージへの移行 {#migrate-to-object-storage}

{{< history >}}

- GitLab 16.1で[導入](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/readme/-/issues/125)されました。

{{< /history >}}

{{< alert type="warning" >}}

オブジェクトストレージからローカルストレージにセキュアファイルを移行して戻すことはできません。そのため、注意して進めてください。

{{< /alert >}}

オブジェクトストレージにセキュアファイルを移行するには、以下の手順に従ってください。

- Linuxパッケージインストールの場合:

  ```shell
  sudo gitlab-rake gitlab:ci_secure_files:migrate
  ```

- 自己コンパイルによるインストールの場合: 

  ```shell
  sudo -u git -H bundle exec rake gitlab:ci_secure_files:migrate RAILS_ENV=production
  ```
