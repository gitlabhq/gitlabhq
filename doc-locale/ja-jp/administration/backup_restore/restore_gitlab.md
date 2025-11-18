---
stage: Data Access
group: Durability
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabを復元する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabの復元操作により、バックアップからデータを復元してシステムの継続性を維持し、データ損失から回復できます。この操作では、以下のデータを復元します。

- データベースレコードと設定
- Gitリポジトリ、コンテナレジストリイメージ、アップロードされたコンテンツ
- パッケージレジストリのデータとCI/CDアーティファクト
- アカウントとグループの設定
- プロジェクトとグループのWiki
- プロジェクトレベルの安全なファイル
- 外部マージリクエストの差分

復元プロセスでは、バックアップと同じバージョンの既存のGitLabインストールが必要です。本番環境で使用する前に、[前提要件](#restore-prerequisites)に従い、復元プロセス全体をテストしてください。

## 復元の前提要件 {#restore-prerequisites}

### 復元先のGitLabインスタンスがすでに動作している必要がある {#the-destination-gitlab-instance-must-already-be-working}

復元を実行するには、正常に動作しているGitLabインストールが必要です。これは、復元操作を実行するシステムユーザー（`git`）には、通常、データをインポートするために必要なSQLデータベース（`gitlabhq_production`）の作成や削除を行う権限がないためです。既存のデータはすべて消去される（SQL）か、別のディレクトリに移動されます（リポジトリやアップロードファイルなど）。SQLデータの復元では、PostgreSQL拡張機能が所有しているビューはスキップされます。

### 復元先のGitLabインスタンスがまったく同じバージョンである必要がある {#the-destination-gitlab-instance-must-have-the-exact-same-version}

バックアップは、作成時とまったく同じバージョンおよびタイプ（CEまたはEE）のGitLabにのみ復元できます。たとえば、CE 15.1.4などです。

バックアップのバージョンが現在のインストールと異なる場合は、バックアップを復元する前に、GitLabインストールを[ダウングレード](../../update/package/downgrade.md)または[アップグレード](../../update/package/_index.md#upgrade-to-a-specific-version)する必要があります。

### GitLabシークレットを復元する必要がある {#gitlab-secrets-must-be-restored}

バックアップを復元するには、GitLabシークレットも復元する必要があります。新しいGitLabインスタンスに移行する場合は、旧サーバーからGitLabのシークレットファイルをコピーしなくてはなりません。これには、データベースの暗号化キー、[CI/CD変数](../../ci/variables/_index.md)、および[2要素認証](../../user/profile/account/two_factor_authentication.md)に使用される変数などが含まれます。キーがないと、[複数の問題が発生](troubleshooting_backup_gitlab.md#when-the-secrets-file-is-lost)します。たとえば、[2要素認証が有効](../../user/profile/account/two_factor_authentication.md)になっているユーザーがアクセスできなくなったり、GitLab Runnerがサインインできなくなったりします。

以下を復元します。

- `/etc/gitlab/gitlab-secrets.json`（Linuxパッケージインストール）
- `/home/git/gitlab/.secret`（自己コンパイルによるインストール）
- [シークレットを復元する](https://docs.gitlab.com/charts/backup-restore/restore.html#restoring-the-secrets)を参照（クラウドネイティブGitLab）
  - 必要に応じて、[GitLab HelmチャートのシークレットをLinuxパッケージ形式に変換](https://docs.gitlab.com/charts/installation/migration/helm_to_package.html)できます。

### 特定のGitLabの設定がバックアップ元の環境と一致している必要がある {#certain-gitlab-configuration-must-match-the-original-backed-up-environment}

復元する際は、以前の`/etc/gitlab/gitlab.rb`（Linuxパッケージインストールの場合）または`/home/git/gitlab/config/gitlab.yml`（自己コンパイルによるインストールの場合）、および[TLSキーまたはSSHキーと証明書](backup_gitlab.md#data-not-included-in-a-backup)を個別に復元することがあります。

特定の設定は、PostgreSQLのデータに結び付いています。次に例を示します。

- 元の環境に3つのリポジトリのストレージ（例: `default`、`my-storage-1`、`my-storage-2`）がある場合、復元先の環境にも、それらのストレージ名が設定で定義されている必要があります。
- 元の環境がローカルストレージを使用している場合、バックアップを復元するとローカルストレージに復元されます。たとえ復元先の環境がオブジェクトストレージを使用している場合でも同様です。オブジェクトストレージへの移行は、復元前または復元後に行う必要があります。

### マウントポイントであるディレクトリを復元する {#restoring-directories-that-are-mount-points}

マウントポイントであるディレクトリに復元する場合は、復元を試みる前に、これらのディレクトリが空であることを確認する必要があります。確認しない場合、GitLabは新しいデータを復元する前にこれらのディレクトリを移動しようとするため、エラーが発生します。

[NFSマウントの設定](../nfs.md)の詳細を参照してください。

## LinuxパッケージインストールのGitLabを復元する {#restore-for-linux-package-installations}

この手順では、以下を前提としています。

- バックアップを作成した際とまったく同じバージョンおよびタイプ（CE/EE）のGitLabをインストールしている。
- `sudo gitlab-ctl reconfigure`を少なくとも1回実行している。
- GitLabが起動している。起動していない場合は、`sudo gitlab-ctl start`を実行して起動します。

まず、バックアップのtarファイルが、`gitlab.rb`の設定項目`gitlab_rails['backup_path']`で指定されたバックアップディレクトリにあることを確認します。デフォルトは`/var/opt/gitlab/backups`です。バックアップファイルは、`git`ユーザーが所有している必要があります。

```shell
sudo cp 11493107454_2018_04_25_10.6.4-ce_gitlab_backup.tar /var/opt/gitlab/backups/
sudo chown git:git /var/opt/gitlab/backups/11493107454_2018_04_25_10.6.4-ce_gitlab_backup.tar
```

データベースに接続しているプロセスを停止します。その他のGitLabのプロセスは実行したままにします。

```shell
sudo gitlab-ctl stop puma
sudo gitlab-ctl stop sidekiq
# Verify
sudo gitlab-ctl status
```

次に、[復元の前提要件](#restore-prerequisites)の手順を完了し、元のインストールからGitLabのシークレットファイルをコピーした後、`gitlab-ctl reconfigure`を実行したことを確認します。

続いて、復元するバックアップのIDを指定してバックアップを復元します。

{{< alert type="warning" >}}

次のコマンドは、GitLabデータベースの内容を上書きします！

{{< /alert >}}

```shell
# NOTE: "_gitlab_backup.tar" is omitted from the name
sudo gitlab-backup restore BACKUP=11493107454_2018_04_25_10.6.4-ce
```

バックアップのtarファイルと現在インストールされているGitLabのバージョンが一致しない場合、復元コマンドは中止され、次のエラーメッセージが表示されます。

```plaintext
GitLab version mismatch:
  Your current GitLab version (16.5.0-ee) differs from the GitLab version in the backup!
  Please switch to the following version and try again:
  version: 16.4.3-ee
```

[正しいバージョンのGitLab](https://packages.gitlab.com/gitlab/)をインストールしてから、再度試してください。

{{< alert type="warning" >}}

インストール環境でPgBouncerを使用している場合（パフォーマンス上の理由や、Patroniクラスターとの併用による場合）、復元コマンドに[追加のパラメータ](backup_gitlab.md#back-up-and-restore-for-installations-using-pgbouncer)が必要です。

{{< /alert >}}

PostgreSQLノードでreconfigureを実行します。

```shell
sudo gitlab-ctl reconfigure
```

次に、GitLabを起動して[確認](../raketasks/maintenance.md#check-gitlab-configuration)します。

```shell
sudo gitlab-ctl start
sudo gitlab-rake gitlab:check SANITIZE=true
```

特に`/etc/gitlab/gitlab-secrets.json`が復元された場合、または別のサーバーが復元先である場合は、[データベースの値を復号化できる](../raketasks/check.md#verify-database-values-can-be-decrypted-using-the-current-secrets)ことを確認します。

```shell
sudo gitlab-rake gitlab:doctor:secrets
```

さらに確実性を高めるため、[アップロードされたファイルの整合性チェック](../raketasks/check.md#uploaded-files-integrity)を実行できます。

```shell
sudo gitlab-rake gitlab:artifacts:check
sudo gitlab-rake gitlab:lfs:check
sudo gitlab-rake gitlab:uploads:check
```

復元が完了したら、データベース統計を生成することが推奨されます。これにより、データベースのパフォーマンスが向上し、UIの不整合を防ぐことができます。

1. [データベースコンソール](https://docs.gitlab.com/omnibus/settings/database.html#connecting-to-the-postgresql-database)に入ります。
1. 次を実行します。

   ```sql
   SET STATEMENT_TIMEOUT=0 ; ANALYZE VERBOSE;
   ```

このコマンドを復元コマンドに統合することについて、現在も議論が続いています。詳細については、[イシュー276184](https://gitlab.com/gitlab-org/gitlab/-/issues/276184)を参照してください。

## DockerイメージインストールおよびGitLab HelmチャートインストールのGitLabを復元する {#restore-for-docker-image-and-gitlab-helm-chart-installations}

DockerイメージまたはKubernetesクラスター上のGitLab Helmチャートを使用してGitLabをインストールしている場合、復元タスクは復元先ディレクトリが空であることを前提としています。しかし、DockerおよびKubernetesのボリュームマウントでは、Linuxオペレーティングシステムに見られる`lost+found`ディレクトリなど、一部のシステムレベルのディレクトリがボリュームルートに作成される場合があります。これらのディレクトリは通常`root`が所有しており、復元のRakeタスクは`git`ユーザーとして実行されるため、アクセス権限エラーが発生する可能性があります。GitLabインストールを復元するには、復元先ディレクトリが空であることを確認する必要があります。

これらのインストールタイプの場合、バックアップのtarballがバックアップの配置場所で使用可能である必要があります（デフォルトの場所は`/var/opt/gitlab/backups`です）。

### HelmチャートインストールのGitLabを復元する {#restore-for-helm-chart-installations}

GitLab Helmチャートでは、[GitLab Helmチャートインストールを復元する](https://docs.gitlab.com/charts/backup-restore/restore.html#restoring-a-gitlab-installation)に記載された手順に従います。

### DockerイメージインストールのGitLabを復元する {#restore-for-docker-image-installations}

[Docker Swarm](../../install/docker/installation.md#install-gitlab-by-using-docker-swarm-mode)を使用している場合、復元プロセス中にPumaがシャットダウンされるため、コンテナのヘルスチェックに失敗し、コンテナが再起動する可能性があります。この問題を回避するには、ヘルスチェックメカニズムを一時的に無効にします。

1. `docker-compose.yml`を編集します。

   ```yaml
   healthcheck:
     disable: true
   ```

1. スタックをデプロイします。

   ```shell
   docker stack deploy --compose-file docker-compose.yml mystack
   ```

詳細については、[イシュー6846](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6846 "GitLabの復元がgitlab-healthcheckのために失敗する可能性がある")を参照してください。

ホストから復元タスクを実行できます。

```shell
# Stop the processes that are connected to the database
docker exec -it <name of container> gitlab-ctl stop puma
docker exec -it <name of container> gitlab-ctl stop sidekiq

# Verify that the processes are all down before continuing
docker exec -it <name of container> gitlab-ctl status

# Run the restore. NOTE: "_gitlab_backup.tar" is omitted from the name
docker exec -it <name of container> gitlab-backup restore BACKUP=11493107454_2018_04_25_10.6.4-ce

# Restart the GitLab container
docker restart <name of container>

# Check GitLab
docker exec -it <name of container> gitlab-rake gitlab:check SANITIZE=true
```

## 自己コンパイルによるインストールのGitLabを復元する {#restore-for-self-compiled-installations}

まず、バックアップのtarファイルが、`gitlab.yml`設定で指定されたバックアップディレクトリにあることを確認します。

```yaml
## Backup settings
backup:
  path: "tmp/backups"   # Relative paths are relative to Rails.root (default: tmp/backups/)
```

デフォルトは`/home/git/gitlab/tmp/backups`で、`git`ユーザーが所有している必要があります。これで、バックアップ手順を開始できます。

```shell
# Stop processes that are connected to the database
sudo service gitlab stop

sudo -u git -H bundle exec rake gitlab:backup:restore RAILS_ENV=production
```

出力例:

```plaintext
Unpacking backup... [DONE]
Restoring database tables:
-- create_table("events", {:force=>true})
   -> 0.2231s
[...]
- Loading fixture events...[DONE]
- Loading fixture issues...[DONE]
- Loading fixture keys...[SKIPPING]
- Loading fixture merge_requests...[DONE]
- Loading fixture milestones...[DONE]
- Loading fixture namespaces...[DONE]
- Loading fixture notes...[DONE]
- Loading fixture projects...[DONE]
- Loading fixture protected_branches...[SKIPPING]
- Loading fixture schema_migrations...[DONE]
- Loading fixture services...[SKIPPING]
- Loading fixture snippets...[SKIPPING]
- Loading fixture taggings...[SKIPPING]
- Loading fixture tags...[SKIPPING]
- Loading fixture users...[DONE]
- Loading fixture users_projects...[DONE]
- Loading fixture web_hooks...[SKIPPING]
- Loading fixture wikis...[SKIPPING]
Restoring repositories:
- Restoring repository abcd... [DONE]
- Object pool 1 ...
Deleting tmp directories...[DONE]
```

次に、[前述のように](#restore-prerequisites)、必要に応じて`/home/git/gitlab/.secret`を復元します。

GitLabを再起動します。

```shell
sudo service gitlab restart
```

## バックアップから1つまたは少数のプロジェクトまたはグループのみを復元する {#restoring-only-one-or-a-few-projects-or-groups-from-a-backup}

GitLabインスタンスの復元に使用するRakeタスクは、単一のプロジェクトまたはグループの復元をサポートしていません。しかし回避策として、バックアップを別の一時的なGitLabインスタンスに復元し、そこからプロジェクトまたはグループをエクスポートすることが可能です。

1. 復元対象のバックアップされたインスタンスと同じバージョンの[GitLabを新たにインストール](../../install/_index.md)します。
1. この新しいインスタンスにバックアップを復元し、そこから[プロジェクト](../../user/project/settings/import_export.md)または[グループ](../../user/project/settings/import_export.md#migrate-groups-by-uploading-an-export-file-deprecated)をエクスポートします。エクスポートされる項目とされない項目の詳細については、エクスポート機能のドキュメントを参照してください。
1. エクスポートが完了したら、元のインスタンスに移動してインポートします。
1. 目的のプロジェクトまたはグループのインポートが完了したら、新しい一時的なGitLabインスタンスは削除してもかまいません。

個々のプロジェクトやグループを直接復元できるようにする機能リクエストについては、[イシュー17517](https://gitlab.com/gitlab-org/gitlab/-/issues/17517)で議論されています。

## 増分リポジトリバックアップを復元する {#restoring-an-incremental-repository-backup}

各バックアップアーカイブには、[増分リポジトリバックアップ手順](backup_gitlab.md#incremental-repository-backups)で作成されたものを含め、完全な自己完結型バックアップが含まれています。増分リポジトリバックアップを復元するには、他の通常のバックアップアーカイブを復元する場合と同じ手順を使用します。

## 復元オプション {#restore-options}

バックアップからの復元に使用するGitLabのコマンドラインツールには、他にも多くのオプションを指定できます。

### 複数のバックアップがある場合に復元するバックアップを指定する {#specify-backup-to-restore-when-there-are-more-than-one}

バックアップファイルは、[バックアップIDで始まる](backup_archive_process.md#backup-id)命名スキームを使用します。バックアップが複数存在する場合は、環境変数`BACKUP=<backup-id>`を設定して、復元する`<backup-id>_gitlab_backup.tar`ファイルを指定する必要があります。

### 復元中にプロンプトを無効にする {#disable-prompts-during-restore}

バックアップからの復元中、復元スクリプトは次のタイミングで確認のプロンプトを表示します。

- **authorized_keysへの書き込み**設定が有効になっている場合は、復元スクリプトが`authorized_keys`ファイルを削除して再構築する前。
- データベースの復元時、復元スクリプトが既存のテーブルをすべて削除する前。
- データベースの復元後、スキーマの復元でエラーが発生し、続行するとさらに問題が発生する可能性がある場合。

これらのプロンプトを無効にするには、`GITLAB_ASSUME_YES`環境変数を`1`に設定します。

- Linuxパッケージインストール:

  ```shell
  sudo GITLAB_ASSUME_YES=1 gitlab-backup restore
  ```

- 自己コンパイルによるインストール:

  ```shell
  sudo -u git -H GITLAB_ASSUME_YES=1 bundle exec rake gitlab:backup:restore RAILS_ENV=production
  ```

`force=yes`環境変数もこれらのプロンプトを無効にします。

### 復元時にタスクを除外する {#excluding-tasks-on-restore}

環境変数`SKIP`を追加して、復元時に特定のタスクを除外できます。この変数の値には、次のオプションのカンマ区切りリストを指定します。

- `db`（データベース）
- `uploads`（添付ファイル）
- `builds`（CIジョブの出力ログ）
- `artifacts`（CIジョブのアーティファクト）
- `lfs`（LFSオブジェクト）
- `terraform_state`（Terraformステート）
- `registry`（コンテナレジストリイメージ）
- `pages`（Pagesコンテンツ）
- `repositories`（Gitリポジトリデータ）
- `packages`（パッケージ）

特定のタスクを除外するには、次の手順に従います。

- Linuxパッケージインストール:

  ```shell
  sudo gitlab-backup restore BACKUP=<backup-id> SKIP=db,uploads
  ```

- 自己コンパイルによるインストール:

  ```shell
  sudo -u git -H bundle exec rake gitlab:backup:restore BACKUP=<backup-id> SKIP=db,uploads RAILS_ENV=production
  ```

### 特定のリポジトリのストレージを復元する {#restore-specific-repository-storages}

{{< history >}}

- GitLab 15.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86896)されました。

{{< /history >}}

{{< alert type="warning" >}}

GitLab 17.1以前は、データ損失を引き起こす可能性のある[競合状態の影響](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/158412)を受けます。この問題は、GitLabの[オブジェクトプール](../repository_storage_paths.md#hashed-object-pools)を使用しており、フォークされているリポジトリに影響します。データ損失を回避するには、GitLab 17.2以降のみを使用してバックアップを復元してください。

{{< /alert >}}

[複数のリポジトリのストレージ](../repository_storage_paths.md)を使用している場合、`REPOSITORIES_STORAGES`オプションを使用することで、特定のリポジトリのストレージにあるリポジトリを個別に復元できます。このオプションは、カンマ区切りのストレージ名のリストを受け入れます。

次に例を示します。

- Linuxパッケージインストール:

  ```shell
  sudo gitlab-backup restore BACKUP=<backup-id> REPOSITORIES_STORAGES=storage1,storage2
  ```

- 自己コンパイルによるインストール:

  ```shell
  sudo -u git -H bundle exec rake gitlab:backup:restore BACKUP=<backup-id> REPOSITORIES_STORAGES=storage1,storage2
  ```

### 特定のリポジトリを復元する {#restore-specific-repositories}

{{< history >}}

- GitLab 15.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88094)されました。

{{< /history >}}

{{< alert type="warning" >}}

GitLab 17.1以前は、データ損失を引き起こす可能性のある[競合状態の影響](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/158412)を受けます。この問題は、GitLabの[オブジェクトプール](../repository_storage_paths.md#hashed-object-pools)を使用しており、フォークされているリポジトリに影響します。データ損失を回避するには、GitLab 17.2以降のみを使用してバックアップを復元してください。

{{< /alert >}}

`REPOSITORIES_PATHS`および`SKIP_REPOSITORIES_PATHS`オプションを使用して、特定のリポジトリを復元できます。これらのオプションには、プロジェクトまたはグループのパスをカンマ区切りリストで指定します。グループのパスを指定した場合、使用するオプションに応じて、そのグループおよび下位グループ内のすべてのプロジェクトに含まれるすべてのリポジトリが、バックアップ対象に含まれるかスキップされます。グループおよびプロジェクトは、指定したバックアップ内または復元先インスタンス上に存在する必要があります。

{{< alert type="note" >}}

`REPOSITORIES_PATHS`オプションと`SKIP_REPOSITORIES_PATHS`オプションは、Gitリポジトリにのみ適用されます。プロジェクトまたはグループのデータベースエントリには適用されません。`SKIP=db`を指定して作成されたリポジトリのバックアップだけでは、新しいインスタンスに特定のリポジトリを復元することはできません。

{{< /alert >}}

たとえば、グループA（`group-a`）内のすべてのプロジェクトのすべてのリポジトリと、グループB（`group-b/project-c`）内のプロジェクトCのリポジトリを復元し、グループA（`group-a/project-d`）内のプロジェクトDをスキップする場合、次のように指定します。

- Linuxパッケージインストール:

  ```shell
  sudo gitlab-backup restore BACKUP=<backup-id> REPOSITORIES_PATHS=group-a,group-b/project-c SKIP_REPOSITORIES_PATHS=group-a/project-d
  ```

- 自己コンパイルによるインストール:

  ```shell
  sudo -u git -H bundle exec rake gitlab:backup:restore BACKUP=<backup-id> REPOSITORIES_PATHS=group-a,group-b/project-c SKIP_REPOSITORIES_PATHS=group-a/project-d
  ```

### 展開済みバックアップを復元する {#restore-untarred-backups}

[展開済みバックアップ](backup_gitlab.md#skipping-tar-creation)（`SKIP=tar`を使用して作成）が見つかり、`BACKUP=<backup-id>`で特定のバックアップが指定されていない場合は、その展開済みバックアップが使用されます。

次に例を示します。

- Linuxパッケージインストール:

  ```shell
  sudo gitlab-backup restore
  ```

- 自己コンパイルによるインストール:

  ```shell
  sudo -u git -H bundle exec rake gitlab:backup:restore
  ```

### サーバー側のリポジトリバックアップを使用した復元 {#restoring-using-server-side-repository-backups}

{{< history >}}

- GitLab 16.3で、`gitlab-backup`に[導入](https://gitlab.com/gitlab-org/gitaly/-/issues/4941)されました。
- GitLab 16.6で、最新のバックアップではなく指定したバックアップを復元するためのサーバー側のサポートが`gitlab-backup`に[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132188)されました。
- GitLab 16.6で、増分バックアップを作成するためのサーバー側のサポートが`gitlab-backup`に[導入](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6475)されました。
- GitLab 17.0で、サーバー側のサポートが`backup-utility`に[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/438393)されました。

{{< /history >}}

サーバー側のバックアップを収集すると、復元プロセスは、[サーバー側のリポジトリのバックアップを作成する](backup_gitlab.md#create-server-side-repository-backups)に示されているサーバー側の復元メカニズムをデフォルトで使用します。各リポジトリをホストするGitalyノードが、必要なバックアップデータをオブジェクトストレージから直接プルできるように、バックアップの復元を設定できます。

1. [Gitalyでサーバー側のバックアップ先を設定](../gitaly/configure_gitaly.md#configure-server-side-backups)します。
1. サーバー側のバックアップ復元プロセスを開始し、復元する[バックアップのID](backup_archive_process.md#backup-id)を指定します。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
sudo gitlab-backup restore BACKUP=11493107454_2018_04_25_10.6.4-ce
```

{{< /tab >}}

{{< tab title="自己コンパイル" >}}

```shell
sudo -u git -H bundle exec rake gitlab:backup:restore BACKUP=11493107454_2018_04_25_10.6.4-ce
```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

```shell
kubectl exec <Toolbox pod name> -it -- backup-utility --restore -t <backup_ID> --repositories-server-side
```

[cronベースのバックアップ](https://docs.gitlab.com/charts/backup-restore/backup.html#cron-based-backup)を使用している場合は、追加の引数として`--repositories-server-side`フラグを指定します。

{{< /tab >}}

{{< /tabs >}}

## トラブルシューティング {#troubleshooting}

起こり得る問題と考えられる解決策を次に示します。

### Linuxパッケージインストール環境でデータベースバックアップの復元時に出力される警告 {#restoring-database-backup-using-output-warnings-from-a-linux-package-installation}

バックアップの復元手順を使用している場合、次のような警告メッセージが表示されることがあります。

```plaintext
ERROR: must be owner of extension pg_trgm
ERROR: must be owner of extension btree_gist
ERROR: must be owner of extension plpgsql
WARNING:  no privileges could be revoked for "public" (two occurrences)
WARNING:  no privileges were granted for "public" (two occurrences)
```

このような警告メッセージが表示されても、バックアップは正常に復元されていることに注意してください。

Rakeタスクは`gitlab`ユーザーとして実行されますが、このユーザーにはデータベースに対するスーパーユーザーアクセス権がありません。復元が開始される際も同様に`gitlab`ユーザーとして実行されますが、アクセス権のないオブジェクトを変更しようとします。これらのオブジェクトは、データベースのバックアップや復元には影響しませんが、警告メッセージが表示されます。

詳細については、以下を参照してください。

- PostgreSQLイシュートラッカー:
  - [スーパーユーザーではない](https://www.postgresql.org/message-id/201110220712.30886.adrian.klaver@gmail.com)。
  - [オーナーが異なる](https://www.postgresql.org/message-id/2039.1177339749@sss.pgh.pa.us)。

- スタックオーバーフロー: [発生するエラー](https://stackoverflow.com/questions/4368789/error-must-be-owner-of-language-plpgsql)。

### Gitサーバーフックが原因で復元が失敗する {#restoring-fails-due-to-git-server-hook}

バックアップから復元する際に次の条件に当てはまる場合、エラーが発生することがあります。

- Gitサーバーフック（`custom_hook`）が、[GitLabバージョン15.10以前](../server_hooks.md)の方法で設定されている
- 使用しているGitLabバージョンが15.11以降である
- GitLabの管理下にないディレクトリへのシンボリックリンクを作成している

次のようなエラーが出力されます。

```plaintext
{"level":"fatal","msg":"restore: pipeline: 1 failures encountered:\n - @hashed/path/to/hashed_repository.git (path/to_project): manager: restore custom hooks, \"@hashed/path/to/hashed_repository/<BackupID>_<GitLabVersion>-ee/001.custom_hooks.tar\": rpc error: code = Internal desc = setting custom hooks: generating prepared vote: walking directory: copying file to hash: read /mnt/gitlab-app/git-data/repositories/+gitaly/tmp/default-repositories.old.<timestamp>.<temporaryfolder>/custom_hooks/compliance-triggers.d: is a directory\n","pid":3256017,"time":"2023-08-10T20:09:44.395Z"}
```

この問題を解決するには、GitLabバージョン15.11以降向けにGit[サーバーフック](../server_hooks.md)を更新し、新しいバックアップを作成してください。

### `fapolicyd`を使用している場合に、復元は成功するがリポジトリが空と表示される {#successful-restore-with-repositories-showing-as-empty-when-using-fapolicyd}

セキュリティを強化するために`fapolicyd`を使用すると、GitLabは復元に成功したと報告していても、リポジトリが空と表示されることがあります。その他のトラブルシューティングのヘルプについては、[Gitalyのトラブルシューティングのドキュメント](../gitaly/troubleshooting.md#repositories-are-shown-as-empty-after-a-gitlab-restore)を参照してください。
