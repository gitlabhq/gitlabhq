---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Terraformステート管理
description: Terraformステートストレージを管理します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabは、[Terraform](../user/infrastructure/_index.md)のステートファイルのバックエンドとして使用できます。ファイルは保存前に暗号化されたます。この機能はデフォルトで有効になっています。

これらのファイルの保存場所は、デフォルトで次のようになります:

- Linuxパッケージインストールの場合: `/var/opt/gitlab/gitlab-rails/shared/terraform_state`。
- 自己コンパイルによるインストールの場合: `/home/git/gitlab/shared/terraform_state`。

これらの場所は、以下で説明するオプションを使用して設定できます。

[GitLab Helmチャート](https://docs.gitlab.com/charts/)インストールには、[外部オブジェクトストレージ](https://docs.gitlab.com/charts/advanced/external-object-storage/#lfs-artifacts-uploads-packages-external-diffs-terraform-state-dependency-proxy)の設定を使用してください。

## Terraformステートの無効化 {#disabling-terraform-state}

インスタンス全体でTerraformステートを無効にできます。ディスク容量を削減するために、またはインスタンスがTerraformを使用していないために、Terraformを無効にする場合があります。

Terraformステート管理が無効になっている場合:

- 左側のサイドバーで、**操作** > **Terraformステート**を選択することはできません。
- TerraformステートにアクセスするCI/CDジョブは、次のエラーで失敗します:

  ```shell
  Error refreshing state: HTTP remote state endpoint invalid auth
  ```

Terraform管理を無効にするには、インストールに応じて以下の手順に従ってください。

前提要件: 

- 管理者である必要があります。

Linuxパッケージインストールの場合:

1. `/etc/gitlab/gitlab.rb`を編集して、次の行を追加します:

   ```ruby
   gitlab_rails['terraform_state_enabled'] = false
   ```

1. ファイルを保存して、[GitLabを再設定](restart_gitlab.md#reconfigure-a-linux-package-installation)し、変更を有効にします。

自己コンパイルによるインストールの場合: 

1. `/home/git/gitlab/config/gitlab.yml`を編集し、次の行を追加または修正します:

   ```yaml
   terraform_state:
     enabled: false
   ```

1. ファイルを保存して、[GitLabを再起動](restart_gitlab.md#self-compiled-installations)し、変更を有効にします。

## ローカルストレージを使用する {#using-local-storage}

デフォルトの設定ではローカルストレージを使用します。Terraformのステートファイルがローカルに保存されている場所を変更するには、以下の手順に従ってください。

Linuxパッケージインストールの場合:

1. たとえば、ストレージパスを`/mnt/storage/terraform_state`に変更するには、`/etc/gitlab/gitlab.rb`を編集し、次の行を追加します:

   ```ruby
   gitlab_rails['terraform_state_storage_path'] = "/mnt/storage/terraform_state"
   ```

1. ファイルを保存して、[GitLabを再設定](restart_gitlab.md#reconfigure-a-linux-package-installation)し、変更を有効にします。

自己コンパイルによるインストールの場合: 

1. たとえば、ストレージパスを`/mnt/storage/terraform_state`に変更するには、`/home/git/gitlab/config/gitlab.yml`を編集し、次の行を追加または修正します:

   ```yaml
   terraform_state:
     enabled: true
     storage_path: /mnt/storage/terraform_state
   ```

1. ファイルを保存して、[GitLabを再起動](restart_gitlab.md#self-compiled-installations)し、変更を有効にします。

## オブジェクトストレージを使用する {#using-object-storage}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Terraformのステートファイルをディスクに保存する代わりに、[サポートされているオブジェクトストレージオプションのいずれか](object_storage.md#supported-object-storage-providers)を使用することをお勧めします。この設定は、有効な認証情報がすでに設定されていることを前提としています。

[GitLabにおけるオブジェクトストレージの使用の詳細については、こちらをご覧ください](object_storage.md)。

### オブジェクトストレージ設定 {#object-storage-settings}

次の設定があります:

- Linuxパッケージインストールでは、プレフィックスとして`terraform_state_object_store_`が付きます。
- 自己コンパイルによるインストールでは、設定は`terraform_state:`の下の`object_store:`にネストされます。

| 設定 | 説明 | デフォルト |
|---------|-------------|---------|
| `enabled` | オブジェクトストレージを有効または無効にします。 | `false` |
| `remote_directory` | Terraformのステートファイルが保存されているバケット名 | |
| `connection` | さまざまな接続オプション（以降のセクションで説明します）。 | |

### オブジェクトストレージに移行する {#migrate-to-object-storage}

{{< alert type="warning" >}}

Terraformのステートファイルをオブジェクトストレージからローカルストレージに復元することはできないため、注意して進めてください。この動作を変更するための[イシューが存在します](https://gitlab.com/gitlab-org/gitlab/-/issues/350187)。

{{< /alert >}}

Terraformのステートファイルをオブジェクトストレージに移行するには:

- Linuxパッケージインストールの場合:

  ```shell
  gitlab-rake gitlab:terraform_states:migrate
  ```

- 自己コンパイルによるインストールの場合: 

  ```shell
  sudo -u git -H bundle exec rake gitlab:terraform_states:migrate RAILS_ENV=production
  ```

オプションで、[PostgreSQLコンソール](https://docs.gitlab.com/omnibus/settings/database.html#connecting-to-the-bundled-postgresql-database)を使用して、すべてのTerraformのステートファイルが正常に移行されたことを追跡し、確認できます:

- Linuxパッケージインストールの場合: `sudo gitlab-rails dbconsole --database main`。
- 自己コンパイルによるインストールの場合: `sudo -u git -H psql -d gitlabhq_production`。

以下の`objectstg`（`file_store=2`の場合）にすべてのステートの数があることを確認します:

```shell
gitlabhq_production=# SELECT count(*) AS total, sum(case when file_store = '1' then 1 else 0 end) AS filesystem, sum(case when file_store = '2' then 1 else 0 end) AS objectstg FROM terraform_state_versions;

total | filesystem | objectstg
------+------------+-----------
   15 |          0 |      15
```

ディスク上の`terraform_state`フォルダーにファイルがないことを確認します:

```shell
sudo find /var/opt/gitlab/gitlab-rails/shared/terraform_state -type f | grep -v tmp | wc -l
```

### S3互換接続設定 {#s3-compatible-connection-settings}

[統合されたオブジェクトストレージ設定](object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form)を使用する必要があります。このセクションでは、以前の設定形式について説明します。

[プロバイダーごとの使用可能な接続設定](object_storage.md#configure-the-connection-settings)を参照してください。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集し、次の行を追加して、必要な値に置き換えます:

   ```ruby
   gitlab_rails['terraform_state_object_store_enabled'] = true
   gitlab_rails['terraform_state_object_store_remote_directory'] = "terraform"
   gitlab_rails['terraform_state_object_store_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'aws_access_key_id' => 'AWS_ACCESS_KEY_ID',
     'aws_secret_access_key' => 'AWS_SECRET_ACCESS_KEY'
   }
   ```

  {{< alert type="note" >}}

  AWS IAMプロファイルを使用している場合は、AWSアクセスキーおよびシークレットアクセスキー/バリューペアを省略してください。

  {{< /alert >}}

   ```ruby
   gitlab_rails['terraform_state_object_store_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'use_iam_profile' => true
   }
   ```

1. ファイルを保存して、[GitLabを再設定](restart_gitlab.md#reconfigure-a-linux-package-installation)し、変更を有効にします。
1. [オブジェクトストレージに既存のローカルステートを移行する](#migrate-to-object-storage)

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitlab/config/gitlab.yml`を編集し、次の行を追加または修正します:

   ```yaml
   terraform_state:
     enabled: true
     object_store:
       enabled: true
       remote_directory: "terraform" # The bucket name
       connection:
         provider: AWS # Only AWS supported at the moment
         aws_access_key_id: AWS_ACCESS_KEY_ID
         aws_secret_access_key: AWS_SECRET_ACCESS_KEY
         region: eu-central-1
   ```

1. ファイルを保存して、[GitLabを再起動](restart_gitlab.md#self-compiled-installations)し、変更を有効にします。
1. [オブジェクトストレージに既存のローカルステートを移行する](#migrate-to-object-storage)

{{< /tab >}}

{{< /tabs >}}

### Terraformステートファイルのパスを検索 {#find-a-terraform-state-file-path}

Terraformのステートファイルは、関連するプロジェクトのハッシュされたディレクトリパスに保存されます。

パスの形式は`/var/opt/gitlab/gitlab-rails/shared/terraform_state/<path>/<to>/<projectHashDirectory>/<UUID>/0.tfstate`です。ここで、[UUID](https://gitlab.com/gitlab-org/gitlab/-/blob/dcc47a95c7e1664cb15bef9a70f2a4eefa9bd99a/app/models/terraform/state.rb#L33)はランダムに定義されます。

ステートファイルのパスを見つけるには:

1. `get-terraform-path`をShellに追加します:

   ```shell
   get-terraform-path() {
       PROJECT_HASH=$(echo -n $1 | openssl dgst -sha256 | sed 's/^.* //')
       echo "${PROJECT_HASH:0:2}/${PROJECT_HASH:2:2}/${PROJECT_HASH}"
   }
   ```

1. `get-terraform-path <project_id>`を実行します。

   ```shell
   $ get-terraform-path 650
   20/99/2099a9b5f777e242d1f9e19d27e232cc71e2fa7964fc988a319fce5671ca7f73
   ```

相対パスが表示されます。

## バックアップからTerraformのステートファイルを復元する {#restoring-terraform-state-files-from-backups}

バックアップからTerraformのステートファイルを復元するには、暗号化されたステートファイルとGitLabデータベースへのアクセス権が必要です。

### データベーステーブル {#database-tables}

次のデータベーステーブルは、S3パスを特定のプロジェクトに追跡するのに役立ちます:

- `terraform_states`: 各ステートのユニバーサル一意識別子（UUID）を含む、基本ステート情報が含まれています。

### ファイル構造とパスの構成 {#file-structure-and-path-composition}

ステートファイルは特定のディレクトリ構造に保存されます。ここで:

- パスの最初の3つのセグメントは、プロジェクトIDのSHA-2ハッシュ値から派生しています。
- 各ステートには、`terraform_states`データベーステーブルに保存されているUUIDがあり、パスの一部を形成します。

たとえば、次のようなプロジェクトの場合:

- プロジェクトIDは`12345`です
- ステートUUIDは`example-uuid`です

`12345`のSHA-2ハッシュ値が`5994471abb01112afcc18159f6cc74b4f511b99806da59b3caf5a9c173cacfc5`の場合、フォルダー構造は次のようになります:

```plaintext
terraform/                                                                 <- configured Terraform storage directory
├─ 59/                                                                     <- first and second character of project ID hash
|  ├─ 94/                                                                  <- third and fourth character of project ID hash
|  |  ├─ 5994471abb01112afcc18159f6cc74b4f511b99806da59b3caf5a9c173cacfc5/ <- full project ID hash
|  |  |  ├─ example-uuid/                                                  <- state UUID
|  |  |  |  ├─ 1.tf                                                        <- individual state versions
|  |  |  |  ├─ 2.tf
|  |  |  |  ├─ 3.tf
```

### 復号化プロセス {#decryption-process}

ステートファイルはLockboxを使用して暗号化されたおり、復号化には次の情報が必要です:

- `db_key_base`アプリケーションシークレット
- プロジェクトID

暗号化キーは、`db_key_base`とプロジェクトIDの両方から派生します。`db_key_base`にアクセスできない場合、復号化はできません。

ファイルを手動で復号化する方法については、[Lockbox](https://github.com/ankane/lockbox)のドキュメントを参照してください。

暗号化キーの生成プロセスを表示するには、[ステートアップローダーコード](https://gitlab.com/gitlab-org/gitlab/-/blob/e0137111fbbd28316f38da30075aba641e702b98/app/uploaders/terraform/state_uploader.rb#L43)を参照してください。
