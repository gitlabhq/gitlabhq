---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLab Self-Managed用にGit LFSを設定します。
title: GitLab Git Large File Storage (LFS) の管理
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Gitリポジトリのサイズを大きくしたり、パフォーマンスに影響を与えたりすることなく、大きなファイルを保存するには、Git Large File Storage (LFS) を使用します。LFSを有効または無効にしたり、LFSオブジェクトのローカルまたはリモートストレージを設定したり、ストレージタイプ間でオブジェクトを移行することができます。

Git LFSに関するユーザー向けドキュメントは、[Git Large File Storage](../../topics/git/lfs/_index.md)を参照してください。

前提要件:

- ユーザーは、[Git LFS client](https://git-lfs.com/)バージョン1.1.0以降、または1.0.2をインストールする必要があります。

## LFSを有効または無効にする {#enable-or-disable-lfs}

LFSはデフォルトで有効になっています。無効にするには、次の手順に従います: 

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   # Change to true to enable lfs - enabled by default if not defined
   gitlab_rails['lfs_enabled'] = false
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
       lfs:
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
           gitlab_rails['lfs_enabled'] = false
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
     lfs:
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

## ローカルストレージパスの変更 {#change-local-storage-path}

Git LFSオブジェクトはサイズが大きくなる可能性があります。デフォルトでは、GitLabがインストールされているサーバーに保存されます。

{{< alert type="note" >}}

Dockerインストールの場合、データがマウントされるパスを変更できます。Helmチャートの場合は、[オブジェクトストレージ](https://docs.gitlab.com/charts/advanced/external-object-storage/)を使用します。

{{< /alert >}}

デフォルトのローカルストレージパスの場所を変更するには、次の手順に従います:  

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   # /var/opt/gitlab/gitlab-rails/shared/lfs-objects by default.
   gitlab_rails['lfs_storage_path'] = "/mnt/storage/lfs-objects"
   ```

1. ファイルを保存して、GitLabを再設定します:  

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitlab/config/gitlab.yml`を編集します:  

   ```yaml
   # /home/git/gitlab/shared/lfs-objects by default.
   production: &base
     lfs:
       storage_path: /mnt/storage/lfs-objects
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

## リモートオブジェクトストレージへのLFSオブジェクトの格納 {#storing-lfs-objects-in-remote-object-storage}

LFSオブジェクトをオブジェクトストレージに格納できます。これにより、ローカルディスクへの読み取りと書き込みを削減し、ディスク容量を大幅に解放できます。

[統合されたオブジェクトストレージ設定](../object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form)を使用する必要があります。

### オブジェクトストレージに移行する {#migrating-to-object-storage}

LFSオブジェクトをローカルストレージからオブジェクトストレージに移行できます。この処理はバックグラウンドで実行され、ダウンタイムは不要です。

1. [オブジェクトストレージを設定](../object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form)します。
1. LFSオブジェクトを移行します:  

   {{< tabs >}}

   {{< tab title="Linuxパッケージ（Omnibus）" >}}

   ```shell
   sudo gitlab-rake gitlab:lfs:migrate
   ```

   {{< /tab >}}

   {{< tab title="Docker" >}}

   ```shell
   sudo docker exec -t <container name> gitlab-rake gitlab:lfs:migrate
   ```

   {{< /tab >}}

   {{< tab title="自己コンパイル（ソース）" >}}

   ```shell
   sudo -u git -H bundle exec rake gitlab:lfs:migrate RAILS_ENV=production
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. オプション。SQLコンソールを使用して、進行状況を追跡し、すべてのLFSオブジェクトが正常に移行したことを確認します。
   1. PostgreSQLコンソールを開きます:  

      {{< tabs >}}

      {{< tab title="Linuxパッケージ（Omnibus）" >}}

      ```shell
      sudo gitlab-psql
      ```

      {{< /tab >}}

      {{< tab title="Docker" >}}

      ```shell
      sudo docker exec -it <container_name> /bin/bash
      gitlab-psql
      ```

      {{< /tab >}}

      {{< tab title="自己コンパイル（ソース）" >}}

      ```shell
      sudo -u git -H psql -d gitlabhq_production
      ```

      {{< /tab >}}

      {{< /tabs >}}

   1. 次のSQLクエリを使用して、すべてのLFSファイルをオブジェクトストレージに移行したことを確認します。`objectstg`の数が`total`と同じである必要があります:  

      ```shell
      gitlabhq_production=# SELECT count(*) AS total, sum(case when file_store = '1' then 1 else 0 end) AS filesystem, sum(case when file_store = '2' then 1 else 0 end) AS objectstg FROM lfs_objects;

      total | filesystem | objectstg
      ------+------------+-----------
       2409 |          0 |      2409
      ```

1. ディスク上の`lfs-objects`ディレクトリにファイルがないことを確認します:  

   {{< tabs >}}

   {{< tab title="Linuxパッケージ（Omnibus）" >}}

   ```shell
   sudo find /var/opt/gitlab/gitlab-rails/shared/lfs-objects -type f | grep -v tmp | wc -l
   ```

   {{< /tab >}}

   {{< tab title="Docker" >}}

   `/var/opt/gitlab`を`/srv/gitlab`にマウントしている場合は、次のようになります:  

   ```shell
   sudo find /srv/gitlab/gitlab-rails/shared/lfs-objects -type f | grep -v tmp | wc -l
   ```

   {{< /tab >}}

   {{< tab title="自己コンパイル（ソース）" >}}

   ```shell
   sudo find /home/git/gitlab/shared/lfs-objects -type f | grep -v tmp | wc -l
   ```

   {{< /tab >}}

   {{< /tabs >}}

### ローカルストレージへの移行の復元 {#migrating-back-to-local-storage}

{{< alert type="note" >}}

Helmチャートの場合は、[オブジェクトストレージ](https://docs.gitlab.com/charts/advanced/external-object-storage/)を使用する必要があります。

{{< /alert >}}

ローカルストレージに移行して戻すには、次の手順に従います:  

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. LFSオブジェクトを移行します:  

   ```shell
   sudo gitlab-rake gitlab:lfs:migrate_to_local
   ```

1. `/etc/gitlab/gitlab.rb`を編集し、LFSオブジェクトの[オブジェクトストレージを無効](../object_storage.md#disable-object-storage-for-specific-features)にします:  

   ```ruby
   gitlab_rails['object_store']['objects']['lfs']['enabled'] = false
   ```

1. ファイルを保存して、GitLabを再設定します:  

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. LFSオブジェクトを移行します:  

   ```shell
   sudo docker exec -t <container name> gitlab-rake gitlab:lfs:migrate_to_local
   ```

1. `docker-compose.yml`を編集し、LFSオブジェクトのオブジェクトストレージを無効にします:  

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['object_store']['objects']['lfs']['enabled'] = false
   ```

1. ファイルを保存して、GitLabを再起動します:  

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. LFSオブジェクトを移行します:  

   ```shell
   sudo -u git -H bundle exec rake gitlab:lfs:migrate_to_local RAILS_ENV=production
   ```

1. `/home/git/gitlab/config/gitlab.yml`を編集し、LFSオブジェクトのオブジェクトストレージを無効にします:  

   ```yaml
   production: &base
     object_store:
       objects:
         lfs:
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

## ピュアSSH転送プロトコル {#pure-ssh-transfer-protocol}

{{< history >}}

- GitLab 17.2で[導入](https://gitlab.com/groups/gitlab-org/-/epics/11872)されました。
- GitLab 17.3のHelmチャート (Kubernetes) に[導入](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/3845)。

{{< /history >}}

{{< alert type="warning" >}}

この機能は、[既知の問題](https://github.com/git-lfs/git-lfs/issues/5880) ([Git LFS 3.6.0](https://github.com/git-lfs/git-lfs/blob/main/CHANGELOG.md#360-20-november-2024)で解決済) の影響を受けます。ピュアSSHプロトコルを使用して複数のGit LFSオブジェクトを含むリポジトリをクローン作成すると、クライアントが`nil`ポインター参照によってクラッシュする可能性があります。

{{< /alert >}}

[`git-lfs` 3.0.0](https://github.com/git-lfs/git-lfs/blob/main/CHANGELOG.md#300-24-sep-2021)は、HTTPの代わりにSSHを転送プロトコルとして使用するためのサポートをリリースしました。SSHは、`git-lfs`コマンドラインツールによって透過的に処理されます。

ピュアSSHプロトコルのサポートが有効になっていて、`git`がSSHを使用するように設定されている場合、すべてのLFS操作はSSH経由で行われます。たとえば、Git originが`git@gitlab.com:gitlab-org/gitlab.git`の場合などです。`git`と`git-lfs`が異なるプロトコルを使用するように設定することはできません。バージョン3.0以降、`git-lfs`は最初にピュアSSHプロトコルの使用を試み、サポートが有効になっていないか利用できない場合は、HTTPの使用にフォールバックします。

前提要件: 

- `git-lfs`バージョンは、[v3.5.1](https://github.com/git-lfs/git-lfs/releases/tag/v3.5.1)以降である必要があります。

Git LFSがピュアSSHプロトコルを使用するように切り替えるには、次の手順に従います:  

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します:  

   ```ruby
   gitlab_shell['lfs_pure_ssh_protocol'] = true
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
   gitlab:
     gitlab-shell:
       config:
         lfs:
           pureSSHProtocol: true
   ```

1. ファイルを保存して、新しい値を適用します:  

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`を編集します:  

   ```yaml
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_shell['lfs_pure_ssh_protocol'] = true
   ```

1. ファイルを保存して、GitLabとそのサービスを再起動します:  

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

1. `/home/git/gitlab-shell/config.yml`を編集します:  

   ```yaml
   lfs:
      pure_ssh_protocol: true
   ```

1. ファイルを保存して、GitLab Shellを再起動します:  

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab-shell.target

   # For systems running SysV init
   sudo service gitlab-shell restart
   ```

{{< /tab >}}

{{< /tabs >}}

## ストレージ統計 {#storage-statistics}

グループおよびプロジェクトごとのLFSオブジェクトの合計ストレージ使用量は、次の手段で確認できます:  

- **管理者**エリア
- [グループ](../../api/groups.md) APIおよび[プロジェクト](../../api/projects.md) API

{{< alert type="note" >}}

ストレージ統計では、リンクしているすべてのプロジェクトについて、各LFSオブジェクトがカウントされます。

{{< /alert >}}

## 関連トピック {#related-topics}

- ブログ投稿: [Git LFS入門](https://about.gitlab.com/blog/2017/01/30/getting-started-with-git-lfs-tutorial/)
- ユーザードキュメント: [Git Large File Storage（LFS）](../../topics/git/lfs/_index.md)

## トラブルシューティング {#troubleshooting}

### 見つからないLFSオブジェクト {#missing-lfs-objects}

見つからないLFSオブジェクトに関するエラーは、次のいずれかの状況で発生する可能性があります:  

- ディスクからオブジェクトストレージにLFSオブジェクトを移行するときに、次のようなエラーメッセージが表示される:  

  ```plaintext
  ERROR -- : Failed to transfer LFS object
  006622269c61b41bf14a22bbe0e43be3acf86a4a446afb4250c3794ea47541a7
  with error: No such file or directory @ rb_sysopen -
  /var/opt/gitlab/gitlab-rails/shared/lfs-objects/00/66/22269c61b41bf14a22bbe0e43be3acf86a4a446afb4250c3794ea47541a7
  ```

   （読みやすくするために改行を追加しました）。

- `VERBOSE=1`パラメータを指定してLFSオブジェクトの[整合性チェック](../raketasks/check.md#uploaded-files-integrity)を実行する場合。

データベースには、ディスク上にないLFSオブジェクトのレコードが含まれている可能性があります。データベースエントリは、[オブジェクトの新しいコピーがプッシュされるのを防ぐ](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/49241)可能性があります。これらの参照を削除するには、次の手順に従います:  

1. [Railsコンソール](../operations/rails_console.md)を起動します。
1. Railsコンソールで見つからないとレポートされているオブジェクトをクエリして、ファイルパスを返します:  

   ```ruby
   lfs_object = LfsObject.find_by(oid: '006622269c61b41bf14a22bbe0e43be3acf86a4a446afb4250c3794ea47541a7')
   lfs_object.file.path
   ```

1. ディスクまたはオブジェクトストレージに存在するかどうかを確認します: 

   ```shell
   ls -al /var/opt/gitlab/gitlab-rails/shared/lfs-objects/00/66/22269c61b41bf14a22bbe0e43be3acf86a4a446afb4250c3794ea47541a7
   ```

1. ファイルが存在しない場合は、Railsコンソールを使用してデータベースレコードを削除します:  

   ```ruby
   # First delete the parent records and then destroy the record itself
   lfs_object.lfs_objects_projects.destroy_all
   lfs_object.destroy
   ```

#### 複数の見つからないLFSオブジェクトを削除する {#remove-multiple-missing-lfs-objects}

複数の見つからないLFSオブジェクトへの参照を一度に削除するには、次の手順に従います:  

1. [GitLab Railsコンソール](../operations/rails_console.md#starting-a-rails-console-session)を使用します。
1. 次のスクリプトを実行します:  

   ```ruby
   lfs_files_deleted = 0
   LfsObject.find_each do |lfs_file|
     next if lfs_file.file.file.exists?
     lfs_files_deleted += 1
     p "LFS file with ID #{lfs_file.id} and path #{lfs_file.file.path} is missing."
     # lfs_file.lfs_objects_projects.destroy_all     # Uncomment to delete parent records
     # lfs_file.destroy                              # Uncomment to destroy the LFS object reference
   end
   p "Count of identified/destroyed invalid references: #{lfs_files_deleted}"
   ```

このスクリプトは、データベース内の見つからないすべてのLFSオブジェクトを識別します。レコードを削除する前に: 

- 最初に、検証のため​​に見つからないファイルに関する情報を出力します。
- コメント化された行は、誤った削除を防ぎます。コメントを解除すると、スクリプトは識別されたレコードを削除します。
- スクリプトは、比較のために削除されたレコードの最終カウントを自動的に出力します。

### TLS v1.3サーバーでLFSコマンドが失敗する {#lfs-commands-fail-on-tls-v13-server}

GitLabを構成して[TLS v1.2を無効](https://docs.gitlab.com/omnibus/settings/nginx.html)にし、TLS v1.3接続のみを有効にする場合、LFS操作には[Git LFSクライアント](https://git-lfs.com/)バージョン2.11.0以降が必要です。バージョン2.11.0以前のGit LFSクライアントを使用すると、GitLabに次のエラーが表示されます:  

```plaintext
batch response: Post https://username:***@gitlab.example.com/tool/releases.git/info/lfs/objects/batch: remote error: tls: protocol version not supported
error: failed to fetch some objects from 'https://username:[MASKED]@gitlab.example.com/tool/releases.git/info/lfs'
```

TLS v1.3で構成されたGitLabサーバー上でGitLab CIを使用する場合、含まれている[GitLab Runner Helper image](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#helper-image)で更新されたGit LFSクライアントバージョンを受信するには、13.2.0以降に[GitLab Runnerにアップグレード](https://docs.gitlab.com/runner/install/)する必要があります。

インストールされているGit LFSクライアントのバージョンを確認するには、次のコマンドを実行します:  

```shell
git lfs version
```

### \`Connection refused\` `Connection refused`エラー {#connection-refused-errors}

LFSオブジェクトをプッシュまたはミラーすると、次のようなエラーが表示される場合: 

- `dial tcp <IP>:443: connect: connection refused`
- `Connection refused - connect(2) for \"<target-or-proxy-IP>\" port 443`

ファイアウォールまたはプロキシルールが接続を終了している可能性があります。

標準のUnixツールまたは手動のGitプッシュを使用した接続チェックが成功した場合、ルールはリクエストのサイズに関連している可能性があります。

### PDFファイルの表示エラー {#error-viewing-a-pdf-file}

LFSがオブジェクトストレージで構成され、`proxy_download`が`false`に設定されている場合、[WebブラウザーからPDFファイルをプレビューすると、エラーが表示されることがあります](https://gitlab.com/gitlab-org/gitlab/-/issues/248100):  

```plaintext
An error occurred while loading the file. Please try again later.
```

これは、クロスオリジンリソース共有 (CORS) の制限が原因で発生します: ブラウザがオブジェクトストレージからPDFファイルを読み込むことを試みますが、オブジェクトストレージプロバイダーは、GitLabドメインがオブジェクトストレージドメインと異なるため、リクエストを拒否します。

この問題を解決するには、オブジェクトストレージプロバイダーのCORS設定を構成して、GitLabドメインを許可します。詳細については、次のドキュメントを参照してください:  

1. [AWS S3](https://repost.aws/knowledge-center/s3-configure-cors)
1. [Google Cloud Storage](https://cloud.google.com/storage/docs/using-cors)
1. [Azureストレージ](https://learn.microsoft.com/en-us/rest/api/storageservices/cross-origin-resource-sharing--cors--support-for-the-azure-storage-services)。

### `Forking in progress`メッセージでフォーク操作が停止する {#fork-operation-stuck-on-forking-in-progress-message}

複数のLFSファイルを含むプロジェクトをフォークしている場合、操作が`Forking in progress`メッセージで停止する可能性があります。これが発生した場合は、次の手順に従って問題を診断し、解決してください: 

1. 次のエラーメッセージについて、[exceptions_json.log](../logs/_index.md#exceptions_jsonlog)ファイルを確認してください: 

   ```plaintext
   "error_message": "Unable to fork project 12345 for repository
   @hashed/11/22/encoded-path -> @hashed/33/44/encoded-new-path:
   Source project has too many LFS objects"
   ```

   このエラーは、イシュー[\#476693](https://gitlab.com/gitlab-org/gitlab/-/issues/476693)で説明されているように、LFSファイルのデフォルト制限である100,000に達したことを示しています。

1. `GITLAB_LFS_MAX_OID_TO_FETCH`変数の値を大きくします: 

   1. 設定ファイル`/etc/gitlab/gitlab.rb`を開きます。
   1. 変数を追加または更新します: 

      ```ruby
      gitlab_rails['env'] = {
         "GITLAB_LFS_MAX_OID_TO_FETCH" => "NEW_VALUE"
      }
      ```

      要件に基づいて`NEW_VALUE`を数値に置き換えます。

1. 変更を適用します。以下を実行します: 

   ```shell
   sudo gitlab-ctl reconfigure
   ```

   詳細については、[Linuxパッケージインストールの再構成](../restart_gitlab.md#reconfigure-a-linux-package-installation)を参照してください。

1. フォーク操作を繰り返します。

{{< alert type="note" >}}

GitLab Helmチャートの場合、[`extraEnv`](https://docs.gitlab.com/charts/charts/globals.html#extraenv)を使用して環境変数`GITLAB_LFS_MAX_OID_TO_FETCH`を設定します。

{{< /alert >}}
