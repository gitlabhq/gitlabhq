---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: アップロード管理
description: アップロードストレージを管理します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

アップロードは、単一のファイルとしてGitLabに送信される可能性のあるすべてのユーザーデータを表します。たとえば、アバターやノートの添付ファイルはアップロードです。アップロードはGitLabの機能に不可欠であるため、無効にすることはできません。

{{< alert type="note" >}}

コメントまたは説明に追加された添付ファイルは、親プロジェクトまたはグループが削除された**場合のみ**削除されます。添付ファイルは、イシュー、マージリクエスト、エピックなど、アップロードされたコメントまたはリソースが削除されても、ファイルストレージに残ります。

{{< /alert >}}

## ローカルストレージを使用する {#using-local-storage}

これはデフォルト設定です。アップロードがローカルに保存されている場所を変更するには、インストール方法に基づいて、このセクションの手順に従ってください:

{{< alert type="note" >}}

歴史的な理由により、インスタンス全体のアップロード（たとえば、[favicon](appearance.md#customize-the-favicon)）は、デフォルトでは`uploads/-/system`であるベースディレクトリに保存されます。既存のGitLabインスタンスへのベースディレクトリの変更は、強く推奨されません。

{{< /alert >}}

Linuxパッケージインストールの場合:

_デフォルトでは、アップロードは`/var/opt/gitlab/gitlab-rails/uploads`に保存されます。_

1. ストレージパスを`/mnt/storage/uploads`に変更するには、`/etc/gitlab/gitlab.rb`を編集し、次の行を追加します:

   ```ruby
   gitlab_rails['uploads_directory'] = "/mnt/storage/uploads"
   ```

   この設定は、`gitlab_rails['uploads_storage_path']`ディレクトリを変更していない場合にのみ適用されます。

1. ファイルを保存して、[GitLabを再設定](restart_gitlab.md#reconfigure-a-linux-package-installation)し、変更を有効にします。

自己コンパイルによるインストールの場合: 

_デフォルトでは、アップロードは`/home/git/gitlab/public/uploads`に保存されます。_

1. たとえば、ストレージパスを`/mnt/storage/uploads`に変更するには、`/home/git/gitlab/config/gitlab.yml`を編集し、次の行を追加または修正します:

   ```yaml
   uploads:
     storage_path: /mnt/storage
     base_dir: uploads
   ```

1. ファイルを保存して、[GitLabを再起動](restart_gitlab.md#self-compiled-installations)し、変更を有効にします。

## オブジェクトストレージを使用する {#using-object-storage}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabがインストールされているローカルディスクにアップロードを保存したくない場合は、代わりにAWS S3などのオブジェクトストレージプロバイダーを使用できます。この設定は、有効なAWS認証情報がすでに設定されていることを前提としています。

[GitLabにおけるオブジェクトストレージの使用の詳細については、こちらをご覧ください](object_storage.md)。

### オブジェクトストレージ設定 {#object-storage-settings}

このセクションでは、ストレージ固有の設定形式について説明します。代わりに、[オブジェクトストレージの統合された設定](object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form)を使用する必要があります。

セルフコンパイルインストールの場合、次の設定は`uploads:`、次に`object_store:`の下にネストされます。Linuxパッケージインストールでは、`uploads_object_store_`がプレフィックスとして付きます。

| 設定 | 説明 | デフォルト |
|---------|-------------|---------|
| `enabled` | オブジェクトストレージを有効または無効にします。 | `false` |
| `remote_directory` | アップロードが保存されているバケット名| |
| `proxy_download` | `true`に設定すると、提供されるすべてのファイルに対してプロキシ処理を有効にします。このオプションを使用すると、クライアントがすべてのデータをプロキシ処理する代わりに、リモートストレージから直接ダウンロードできるようになるため、エグレストラフィックを削減できます。 | `false` |
| `connection` | さまざまな接続オプション（以降のセクションで説明します）。 | |

#### 接続設定 {#connection-settings}

[プロバイダーごとの使用可能な接続設定](object_storage.md#configure-the-connection-settings)を参照してください。

Linuxパッケージインストールの場合:

_デフォルトでは、アップロードは`/var/opt/gitlab/gitlab-rails/uploads`に保存されます。_

1. `/etc/gitlab/gitlab.rb`を編集し、必要な値に置き換えて、次の行を追加します:

   ```ruby
   gitlab_rails['uploads_object_store_enabled'] = true
   gitlab_rails['uploads_object_store_remote_directory'] = "uploads"
   gitlab_rails['uploads_object_store_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'aws_access_key_id' => 'AWS_ACCESS_KEY_ID',
     'aws_secret_access_key' => 'AWS_SECRET_ACCESS_KEY'
   }
   ```

   AWS IAMプロファイルを使用している場合は、AWSアクセスキーとシークレットアクセスキー/キー/バリューペアを省略してください。

   ```ruby
   gitlab_rails['uploads_object_store_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'use_iam_profile' => true
   }
   ```

1. ファイルを保存して、[GitLabを再設定](restart_gitlab.md#reconfigure-a-linux-package-installation)し、変更を有効にします。
1. [`gitlab:uploads:migrate:all` Rakeタスク](raketasks/uploads/migrate.md)を使用して、既存のローカルアップロードをオブジェクトストレージに移行する。

自己コンパイルによるインストールの場合: 

_デフォルトでは、アップロードは`/home/git/gitlab/public/uploads`に保存されます。_

1. `/home/git/gitlab/config/gitlab.yml`を編集し、次の行を追加または修正して、[プロバイダーに適したものを必ず使用してください](object_storage.md#configure-the-connection-settings):

   ```yaml
   uploads:
     object_store:
       enabled: true
       remote_directory: "uploads" # The bucket name
       connection: # The lines in this block depend on your provider
         provider: AWS
         aws_access_key_id: AWS_ACCESS_KEY_ID
         aws_secret_access_key: AWS_SECRET_ACCESS_KEY
         region: eu-central-1
   ```

1. ファイルを保存して、[GitLabを再起動](restart_gitlab.md#self-compiled-installations)し、変更を有効にします。
1. [`gitlab:uploads:migrate:all` Rakeタスク](raketasks/uploads/migrate.md)を使用して、既存のローカルアップロードをオブジェクトストレージに移行する。
