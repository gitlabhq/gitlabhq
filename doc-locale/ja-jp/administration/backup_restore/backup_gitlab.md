---
stage: Data Access
group: Durability
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabをバックアップする
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabのバックアップは、データを保護し、ディザスターリカバリーに役立ちます。

最適なバックアップ戦略は、GitLabのデプロイ設定、データ量、ストレージの場所によって異なります。これらの要因によって、使用するバックアップ方法、バックアップの保存場所、バックアップスケジュールの構成方法が決まります。

大規模なGitLabインスタンスの場合、代替バックアップ戦略には次のようなものがあります。

- 増分バックアップ。
- 特定のリポジトリのバックアップ。
- 複数のストレージの場所にわたるバックアップ。

## バックアップに含まれるデータ {#data-included-in-a-backup}

GitLabは、インスタンス全体をバックアップするためのコマンドラインインターフェースを提供しています。デフォルトでは、バックアップを行うと、単一の圧縮されたtarファイルとしてアーカイブが作成されます。このファイルには、次のものが含まれます。

- データベースのデータと設定
- アカウントとグループの設定
- CI/CDアーティファクトとジョブログ
- GitリポジトリとLFSオブジェクト
- 外部マージリクエストの差分（GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/154914)）
- パッケージレジストリデータとコンテナレジストリイメージ
- プロジェクトと[グループ](../../user/project/wiki/group.md)のWiki。
- プロジェクトレベルの添付ファイルとアップロード
- 安全なファイル（GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121142)）
- GitLab Pagesコンテンツ
- Terraformステート
- スニペット

## バックアップに含まれないデータ {#data-not-included-in-a-backup}

- [Mattermostのデータ](../../integration/mattermost/_index.md#back-up-gitlab-mattermost)
- Redis（およびそれに依存するSidekiqジョブ）
- Linuxパッケージ（Omnibus）/Docker/自己コンパイルによるインストール環境の[オブジェクトストレージ](#object-storage)

- [グローバルサーバーフック](../server_hooks.md#create-global-server-hooks-for-all-repositories)
- [ファイルフック](../file_hooks.md)
- GitLabの設定ファイル（`/etc/gitlab`）
- TLSおよびSSH関連のキーと証明書
- その他のシステムファイル

{{< alert type="warning" >}}

設定ファイルを個別にバックアップするため、[設定ファイルの保存](#storing-configuration-files)に関する情報を確認することを強くおすすめします。

{{< /alert >}}

## 簡単なバックアップ手順 {#simple-backup-procedure}

おおまかなガイドラインとして、100 GB未満のデータで[1,000ユーザー規模のリファレンスアーキテクチャ](../reference_architectures/1k_users.md)を使用している場合は、次の手順に従います。

1. [バックアップコマンド](#backup-command)を実行します。
1. 該当する場合は、[オブジェクトストレージ](#object-storage)をバックアップします。
1. [設定ファイル](#storing-configuration-files)を手動でバックアップします。

## バックアップをスケールする {#scaling-backups}

GitLabのデータ量が増加するにつれて、[バックアップコマンド](#backup-command)の実行に長い時間がかかるようになります。[Gitリポジトリの同時バックアップ](#back-up-git-repositories-concurrently)や[増分リポジトリバックアップ](#incremental-repository-backups)などの[バックアップオプション](#backup-options)を利用すると、実行時間の短縮に役立ちます。状況によっては、バックアップコマンド自体が現実的でなくなることがあります。24時間以上かかる場合があるためです。

GitLab 18.0以降、大量の参照（ブランチ、タグ）があるリポジトリのリポジトリバックアップのパフォーマンスが大幅に向上しました。この改善により、影響を受けるリポジトリのバックアップ時間を数時間から数分に短縮できます。この機能強化を利用するために設定を変更する必要はありません。技術的な詳細については、[GitLabリポジトリのバックアップ時間を短縮することに関する記事](https://about.gitlab.com/blog/2025/06/05/how-we-decreased-gitlab-repo-backup-times-from-48-hours-to-41-minutes/)を参照してください。

バックアップをスケールできるようにするために、アーキテクチャの変更が必要になることがあります。GitLabリファレンスアーキテクチャを使用している場合は、[大規模なリファレンスアーキテクチャのバックアップと復元](backup_large_reference_architectures.md)を参照してください。

詳細については、[代替バックアップ戦略](#alternative-backup-strategies)を参照してください。

## バックアップする必要のあるデータ {#what-data-needs-to-be-backed-up}

- [PostgreSQLデータベース](#postgresql-databases)
- [Gitリポジトリ](#git-repositories)
- [blob](#blobs)
- [コンテナレジストリ](#container-registry)
- [設定ファイル](#storing-configuration-files)
- [その他のデータ](#other-data)

### PostgreSQLデータベース {#postgresql-databases}

GitLabの最も単純なケースでは、他のすべてのGitLabサービスと同じ仮想マシン（VM）上に1つのPostgreSQLサーバーがあり、そのサーバー上に1つのPostgreSQLデータベースが存在します。ただし、設定によっては、複数のPostgreSQLサーバーで複数のPostgreSQLデータベースを使用する場合もあります。

一般に、このデータは、イシューやマージリクエストのコンテンツ、コメント、権限、認証情報など、Webインターフェース内のほとんどのユーザー生成コンテンツの信頼できる唯一の情報源となります。

PostgreSQLは、HTMLレンダリングされたMarkdownなどのキャッシュデータや、デフォルトではマージリクエストの差分も保持します。ただし、マージリクエストの差分は、ファイルシステムまたはオブジェクトストレージにオフロードするように設定することもできます。詳細については、[blob](#blobs)を参照してください。

Gitaly Cluster（Praefect）は、PostgreSQLデータベースを信頼できる唯一の情報源として使用して、Gitalyノードを管理します。

一般的なPostgreSQLユーティリティである[`pg_dump`](https://www.postgresql.org/docs/16/app-pgdump.html)は、PostgreSQLデータベースの復元に使用できるバックアップファイルを生成します。[バックアップコマンド](#backup-command)は、内部でこのユーティリティを使用しています。

残念ながら、データベースのサイズが大きくなるほど、`pg_dump`の実行時間が長くなります。状況によっては、その所要時間が現実的ではなくなります（たとえば、数日かかるなど）。データベースが100 GBを超える場合、`pg_dump`はもちろん、その[バックアップコマンド](#backup-command)も実質的に使えない可能性があります。詳細については、[代替バックアップ戦略](#alternative-backup-strategies)を参照してください。

### Gitリポジトリ {#git-repositories}

GitLabインスタンスには、1つ以上のリポジトリシャードを設定できます。各シャードは、ローカルに保存されたGitリポジトリへのアクセスと操作を可能にするGitalyインスタンスまたはGitaly Clusterです。Gitalyは、次のマシンで実行できます。

- 単一のディスクを使用しているマシン。
- 複数のディスクが（RAIDアレイなどの構成により）単一のマウントポイントとしてマウントされているマシン。
- LVMを使用しているマシン。

各プロジェクトには、最大で3種類のリポジトリを設定できます。

- ソースコードを保存するプロジェクトリポジトリ。
- Wikiコンテンツを保存するWikiリポジトリ。
- デザインアーティファクトをインデックス登録するデザインリポジトリ（実際のアセットはLFSに保存されます）。

これらのリポジトリはすべて同じシャード内に存在し、Wikiリポジトリとデザインリポジトリは同じベース名を共有し、それぞれ`-wiki`および`-design`というサフィックスが付きます。

パーソナルスニペットやプロジェクトスニペット、グループWikiコンテンツは、Gitリポジトリに保存されます。

プロジェクトのフォークは、プールリポジトリを使用して、稼働中のGitLabサイトで重複排除されます。

[バックアップコマンド](#backup-command)は、各リポジトリに対してGitバンドルを生成し、それらをすべてtar形式でアーカイブします。これにより、プールリポジトリデータがすべてのフォークに複製されます。[当社のテスト](https://gitlab.com/gitlab-org/gitlab/-/issues/396343)では、100 GBのGitリポジトリをバックアップしてS3にアップロードするのに、2時間強かかりました。Gitデータが約400 GBに達する場合、バックアップコマンドを定期バックアップに使用するのは現実的ではないと考えられます。詳細については、[代替バックアップ戦略](#alternative-backup-strategies)を参照してください。

### blob {#blobs}

GitLabは、イシューの添付ファイルやLFSオブジェクトなどのblob（またはファイル）を、次のいずれかに保存します。

- 特定の場所にあるファイルシステム。
- [オブジェクトストレージ](../object_storage.md)ソリューション。オブジェクトストレージソリューションには、次のものがあります。
  - Amazon S3やGoogle Cloud Storageなど、クラウドベースのもの。
  - ユーザー自身がホストするもの（MinIOなど）。
  - オブジェクトストレージ互換APIを提供するストレージアプライアンス。

#### オブジェクトストレージ {#object-storage}

[バックアップコマンド](#backup-command)は、ファイルシステムに保存されていないblobをバックアップしません。[オブジェクトストレージ](../object_storage.md)を使用している場合は、オブジェクトストレージプロバイダー側でバックアップを有効にしてください。以下を参照してください。

- [Amazon S3のバックアップ](https://docs.aws.amazon.com/aws-backup/latest/devguide/s3-backups.html)
- [Google Cloud Storage Transfer Service](https://cloud.google.com/storage-transfer-service)および[Google Cloud Storageのオブジェクトのバージョニング](https://cloud.google.com/storage/docs/object-versioning)

### コンテナレジストリ {#container-registry}

[GitLabコンテナレジストリ](../packages/container_registry.md)ストレージは、次のいずれかで設定できます。

- 特定の場所にあるファイルシステム。
- [オブジェクトストレージ](../object_storage.md)ソリューション。オブジェクトストレージソリューションには、次のものがあります。
  - Amazon S3やGoogle Cloud Storageなど、クラウドベースのもの。
  - ユーザー自身がホストするもの（MinIOなど）。
  - オブジェクトストレージ互換APIを提供するストレージアプライアンス。

レジストリデータがオブジェクトストレージに保存されている場合、バックアップコマンドはそれらのデータをバックアップしません。

### 設定ファイルの保存 {#storing-configuration-files}

{{< alert type="warning" >}}

GitLabが提供するバックアップ用Rakeタスクは、設定ファイルを保存しません。その主な理由は、データベースには、2要素認証やCI/CDセキュア変数の暗号化情報を含むアイテムが保存されているためです。暗号化キーと同じ場所に暗号化情報を保存すると、そもそも暗号化を行う意味がなくなります。たとえば、シークレットファイルにはデータベースの暗号化キーが含まれています。このファイルを失うと、GitLabアプリケーションはデータベース内の暗号化された値を復号化できなくなります。

{{< /alert >}}

{{< alert type="warning" >}}

シークレットファイルはアップグレード後に変更される場合があります。{{< /alert >}}

設定ディレクトリをバックアップする必要があります。少なくとも、次のファイルは必ずバックアップするようにしてください。

{{< tabs >}}

{{< tab title="Linuxパッケージ" >}}

- `/etc/gitlab/gitlab-secrets.json`
- `/etc/gitlab/gitlab.rb`

詳細については、[Linuxパッケージ（Omnibus）の設定をバックアップおよび復元する](https://docs.gitlab.com/omnibus/settings/backups.html#backup-and-restore-omnibus-gitlab-configuration)を参照してください。

{{< /tab >}}

{{< tab title="自己コンパイル" >}}

- `/home/git/gitlab/config/secrets.yml`
- `/home/git/gitlab/config/gitlab.yml`

{{< /tab >}}

{{< tab title="Docker" >}}

- 設定ファイルが保存されているボリュームをバックアップします。ドキュメントに従ってGitLabコンテナを作成していれば、設定ファイルは`/srv/gitlab/config`ディレクトリに保存されているはずです。

{{< /tab >}}

{{< tab title="GitLab Helmチャート" >}}

- [シークレットのバックアップ](https://docs.gitlab.com/charts/backup-restore/backup.html#back-up-the-secrets)の手順に従います。

{{< /tab >}}

{{< /tabs >}}

また、フルマシンを復元する必要がある場合に、中間者攻撃の警告を回避するため、TLSキーと証明書（`/etc/gitlab/ssl`、`/etc/gitlab/trusted-certs`）、[SSHホストキー](https://superuser.com/questions/532040/copy-ssh-keys-from-one-server-to-another-server/532079#532079)もバックアップすることをおすすめします。

万が一シークレットファイルを紛失した場合は、[シークレットファイルを紛失した場合](troubleshooting_backup_gitlab.md#when-the-secrets-file-is-lost)を参照してください。

### その他のデータ {#other-data}

GitLabは、キャッシュストアとして、およびバックグラウンドジョブシステムSidekiqの永続データの保存先として、Redisを使用します。提供されている[バックアップコマンド](#backup-command)は、Redisデータをバックアップしません。つまり、[バックアップコマンド](#backup-command)を使用して一貫性のあるバックアップを作成するには、保留中または実行中のバックグラウンドジョブが存在してはいけません。[Redisを手動でバックアップ](https://redis.io/docs/latest/operate/oss_and_stack/management/persistence/#backing-up-redis-data)することも可能です。

Elasticsearchは、高度な検索のためのオプションのデータベースです。これにより、ソースコードレベルと、イシュー、マージリクエスト、ディスカッションにおけるユーザー生成コンテンツの両方で、検索を改善できます。[バックアップコマンド](#backup-command)は、Elasticsearchのデータをバックアップしません。Elasticsearchのデータは、復元後にPostgreSQLデータから再生成できます。[Elasticsearchを手動でバックアップ](https://www.elastic.co/guide/en/elasticsearch/reference/current/snapshot-restore.html)することも可能です。

### 要件 {#requirements}

バックアップと復元を実行できるようにするには、rsyncがシステムにインストールされていることを確認してください。GitLabのインストール方法により、次のように条件が異なります。

- Linuxパッケージを使用した場合、rsyncはすでにインストールされています。
- 自己コンパイルを使用した場合、`rsync`がインストールされているか確認してください。rsyncがインストールされていない場合は、インストールします。次に例を示します。

  ```shell
  # Debian/Ubuntu
  sudo apt-get install rsync

  # RHEL/CentOS
  sudo yum install rsync
  ```

### バックアップコマンド {#backup-command}

{{< alert type="warning" >}}

バックアップコマンドは、Linuxパッケージ（Omnibus）/Docker/自己コンパイルによるインストール環境では、[オブジェクトストレージ](#object-storage)内のアイテムをバックアップしません。

{{< /alert >}}

{{< alert type="warning" >}}

パフォーマンス向上のため、またはPatroniクラスターとの併用のためにPgBouncerを使用しているインストール環境では、バックアップコマンドに[追加のパラメータ](#back-up-and-restore-for-installations-using-pgbouncer)を指定する必要があります。{{< /alert >}}

{{< alert type="warning" >}}

GitLab 15.5.0より前のバージョンでは、[イシュー362593](https://gitlab.com/gitlab-org/gitlab/-/issues/362593)に記載されているとおり、バックアップコマンドは別のバックアップがすでに実行中かどうかを検証しません。そのため、新しいバックアップを開始する前に、すべてのバックアップが完了していることを確認することを強くおすすめします。{{< /alert >}}

{{< alert type="note" >}}

バックアップは、作成時とまったく同じバージョンおよびタイプ（CE/EE）のGitLabにのみ復元できます。

{{< /alert >}}

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
sudo gitlab-backup create
```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

`kubectl`を使用してバックアップタスクを実行し、GitLab Toolboxポッドで`backup-utility`スクリプトを実行します。詳細については、[チャートのバックアップに関するドキュメント](https://docs.gitlab.com/charts/backup-restore/backup.html)を参照してください。

{{< /tab >}}

{{< tab title="Docker" >}}

ホストからバックアップを実行します。

```shell
docker exec -t <container name> gitlab-backup create
```

{{< /tab >}}

{{< tab title="自己コンパイル" >}}

```shell
sudo -u git -H bundle exec rake gitlab:backup:create RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

GitLabデプロイに複数のノードがある場合は、バックアップコマンドを実行するノードを1つ選択する必要があります。選択したノードが次の条件を満たしていることを確認してください。

- 永続的なノードであり、自動スケーリングの対象ではない。
- GitLab Railsアプリケーションがすでにインストールされている。PumaまたはSidekiqが実行されている場合は、Railsがインストールされています。
- バックアップファイルを作成できる十分なストレージとメモリがある。

出力例:

```plaintext
Dumping database tables:
- Dumping table events... [DONE]
- Dumping table issues... [DONE]
- Dumping table keys... [DONE]
- Dumping table merge_requests... [DONE]
- Dumping table milestones... [DONE]
- Dumping table namespaces... [DONE]
- Dumping table notes... [DONE]
- Dumping table projects... [DONE]
- Dumping table protected_branches... [DONE]
- Dumping table schema_migrations... [DONE]
- Dumping table services... [DONE]
- Dumping table snippets... [DONE]
- Dumping table taggings... [DONE]
- Dumping table tags... [DONE]
- Dumping table users... [DONE]
- Dumping table users_projects... [DONE]
- Dumping table web_hooks... [DONE]
- Dumping table wikis... [DONE]
Dumping repositories:
- Dumping repository abcd... [DONE]
Creating backup archive: <backup-id>_gitlab_backup.tar [DONE]
Deleting tmp directories...[DONE]
Deleting old backups... [SKIPPING]
```

バックアッププロセスの詳細については、[バックアップアーカイブプロセス](backup_archive_process.md)を参照してください。

### バックアップオプション {#backup-options}

インスタンスのバックアップ用にGitLabが提供するコマンドラインツールでは、さらに多くのオプションを利用できます。

#### バックアップ戦略オプション {#backup-strategy-option}

デフォルトのバックアップ戦略では、基本的にLinuxコマンドの`tar`および`gzip`を使用し、各データの保存場所からバックアップ先へデータをストリーミングします。この方法はほとんどの場合に問題なく機能しますが、データが急速に変化している場合には問題が発生する可能性があります。

`tar`がデータを読み取っている最中にデータが変更されると、`file changed as we read it`というエラーが発生し、バックアッププロセスが失敗する原因となります。そのような場合には、`copy`というバックアップ戦略を使用できます。この戦略では、`tar`および`gzip`を呼び出す前に、データファイルを一時的な場所にコピーすることで、このエラーを回避します。

副作用として、このバックアッププロセスには追加で最大1倍のディスク容量が必要になります。プロセスは各段階で一時ファイルを可能な限りクリーンアップし、問題を悪化させないよう努めていますが、大規模なインストール環境では大きな変化となる可能性があります。

デフォルトのストリーミング戦略ではなく`copy`戦略を使用するには、Rakeタスクのコマンドで`STRATEGY=copy`を指定します。次に例を示します。

```shell
sudo gitlab-backup create STRATEGY=copy
```

#### バックアップファイル名 {#backup-filename}

{{< alert type="warning" >}}

カスタムのバックアップファイル名を使用する場合、[バックアップのライフタイムを制限する](#limit-backup-lifetime-for-local-files-prune-old-backups)ことはできません。

{{< /alert >}}

バックアップファイルは、[特定のデフォルト](backup_archive_process.md#backup-id)の命名規則に従って作成されます。ただし、`BACKUP`環境変数を設定することで、ファイル名の`<backup-id>`部分をオーバーライドできます。次に例を示します。

```shell
sudo gitlab-backup create BACKUP=dump
```

この場合、作成されるファイル名は`dump_gitlab_backup.tar`になります。これは、rsyncや増分バックアップを使用するシステム向けに便利です。転送速度を大幅に向上させることができます。

#### バックアップの圧縮 {#backup-compression}

デフォルトでは、次のバックアップ時に、Gzipの高速圧縮を適用します。

- [PostgreSQLデータベース](#postgresql-databases)のダンプ。
- [blob](#blobs)（アップロード、ジョブアーティファクト、外部マージリクエストの差分など）。

デフォルトのコマンドは`gzip -c -1`です。このコマンドは、`COMPRESS_CMD`でオーバーライドできます。同様に、解凍コマンドは`DECOMPRESS_CMD`でオーバーライドできます。

注意事項:

- 圧縮コマンドはパイプラインで使用するため、カスタムコマンドは`stdout`に出力する必要があります。
- GitLabにパッケージ化されていないコマンドを指定する場合は、そのコマンドを自分でインストールする必要があります。
- この場合でも、生成されるファイル名の末尾は`.gz`になります。
- 復元時に使用されるデフォルトの解凍コマンドは`gzip -cd`です。したがって、`gzip -cd`で解凍できない形式に圧縮コマンドをオーバーライドした場合は、復元時にも解凍コマンドをオーバーライドする必要があります。
- [環境変数は、バックアップコマンドの後に記述しないでください](https://gitlab.com/gitlab-org/gitlab/-/issues/433227)。たとえば、`gitlab-backup create COMPRESS_CMD="pigz -c --best"`は、意図したとおりに動作しません。

##### デフォルトの圧縮:高速のGzip {#default-compression-gzip-with-fastest-method}

```shell
gitlab-backup create
```

##### 低速のGzip {#gzip-with-slowest-method}

```shell
COMPRESS_CMD="gzip -c --best" gitlab-backup create
```

`gzip`を使用してバックアップを作成した場合は、復元時にオプションを指定する必要はありません。

```shell
gitlab-backup restore
```

##### 圧縮なし {#no-compression}

バックアップ先に自動圧縮機能が備わっている場合は、圧縮をスキップすることをおすすめします。

`tee`コマンドは、`stdin`を`stdout`にパイプ処理します。

```shell
COMPRESS_CMD=tee gitlab-backup create
```

復元時のコマンドは次のとおりです。

```shell
DECOMPRESS_CMD=tee gitlab-backup restore
```

##### `pigz`を使用した並列圧縮 {#parallel-compression-with-pigz}

{{< alert type="warning" >}}

GitLabでは、`COMPRESS_CMD`と`DECOMPRESS_CMD`を使用したデフォルトのGzip圧縮ライブラリのオーバーライドがサポートされていますが、定期的なテストが行われているのは、デフォルトのGzipライブラリとデフォルトのオプションのみです。バックアップの実行可能性については、ユーザー自身がテストおよび検証する必要があります。圧縮コマンドをオーバーライドするかどうかにかかわらず、一般的なバックアップのベストプラクティスとして、ユーザー自身でテストと検証を行うことを強くおすすめします。別の圧縮ライブラリで問題が発生した場合は、デフォルトのライブラリに戻すことをおすすめします。代替ライブラリを使用した場合のトラブルシューティングやエラーの修正は、GitLabにとって優先度が低くなります。

{{< /alert >}}

{{< alert type="note" >}}

`pigz`はGitLab Linuxパッケージには含まれていません。ユーザー自身でインストールする必要があります。

{{< /alert >}}

`pigz`を使用して4つの並列プロセスでバックアップを圧縮する例:

```shell
COMPRESS_CMD="pigz --compress --stdout --fast --processes=4" sudo gitlab-backup create
```

`pigz`は`gzip`形式で圧縮します。したがって、`pigz`で圧縮されたバックアップを解凍する際に`pigz`を使用する必要はありません。ただし、`gzip`よりもパフォーマンス上のメリットを得られる可能性があります。`pigz`を使用してバックアップを解凍する例:

```shell
DECOMPRESS_CMD="pigz --decompress --stdout" sudo gitlab-backup restore
```

##### `zstd`を使用した並列圧縮 {#parallel-compression-with-zstd}

{{< alert type="warning" >}}

GitLabでは、`COMPRESS_CMD`と`DECOMPRESS_CMD`を使用したデフォルトのGzip圧縮ライブラリのオーバーライドがサポートされていますが、定期的なテストが行われているのは、デフォルトのGzipライブラリとデフォルトのオプションのみです。バックアップの実行可能性については、ユーザー自身がテストおよび検証する必要があります。圧縮コマンドをオーバーライドするかどうかにかかわらず、一般的なバックアップのベストプラクティスとして、ユーザー自身でテストと検証を行うことを強くおすすめします。別の圧縮ライブラリで問題が発生した場合は、デフォルトのライブラリに戻すことをおすすめします。代替ライブラリを使用した場合のトラブルシューティングやエラーの修正は、GitLabにとって優先度が低くなります。

{{< /alert >}}

{{< alert type="note" >}}

`zstd`はGitLab Linuxパッケージには含まれていません。ユーザー自身でインストールする必要があります。

{{< /alert >}}

`zstd`を使用して4つのスレッドでバックアップを圧縮する例:

```shell
COMPRESS_CMD="zstd --compress --stdout --fast --threads=4" sudo gitlab-backup create
```

`zstd`を使用してバックアップを解凍する例:

```shell
DECOMPRESS_CMD="zstd --decompress --stdout" sudo gitlab-backup restore
```

#### アーカイブが転送可能であることを確認する {#confirm-archive-can-be-transferred}

生成されたアーカイブをrsyncで転送できるようにするには、`GZIP_RSYNCABLE=yes`オプションを設定します。これは、`--rsyncable`オプションを`gzip`に渡しますが、[バックアップファイル名のオプション](#backup-filename)を設定する場合にのみ効果があります。

`gzip`の`--rsyncable`オプションは、すべてのディストリビューションで利用できるとは限りません。お使いのディストリビューションで利用できるかどうかを確認するには、`gzip --help`を実行するか、manページを参照してください。

```shell
sudo gitlab-backup create BACKUP=dump GZIP_RSYNCABLE=yes
```

#### バックアップから特定のデータを除外する {#excluding-specific-data-from-the-backup}

インストールタイプにより、バックアップ作成時にスキップできるコンポーネントが若干異なります。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）/Docker/自己コンパイル" >}}

<!-- source: https://gitlab.com/gitlab-org/gitlab/-/blob/d693aa7f894c7306a0d20ab6d138a7b95785f2ff/lib/backup/manager.rb#L117-133 -->

- `db`（データベース）
- `repositories`（Gitリポジトリデータ、Wikiを含む）
- `uploads`（添付ファイル）
- `builds`（CIジョブの出力ログ）
- `artifacts`（CIジョブのアーティファクト）
- `pages`（Pagesコンテンツ）
- `lfs`（LFSオブジェクト）
- `terraform_state`（Terraformステート）
- `registry`（コンテナレジストリイメージ）
- `packages`（パッケージ）
- `ci_secure_files`（プロジェクトレベルの安全なファイル）
- `external_diffs`（外部マージリクエストの差分）

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

<!-- source: https://gitlab.com/gitlab-org/build/CNG/-/blob/068e146db915efcd875414e04403410b71a2e70c/gitlab-toolbox/scripts/bin/backup-utility#L19 -->

- `db`（データベース）
- `repositories`（Gitリポジトリデータ、Wikiを含む）
- `uploads`（添付ファイル）
- `artifacts`（CIジョブのアーティファクトと出力ログ）
- `pages`（Pagesコンテンツ）
- `lfs`（LFSオブジェクト）
- `terraform_state`（Terraformステート）
- `registry`（コンテナレジストリイメージ）
- `packages`（パッケージレジストリ）
- `ci_secure_files`（プロジェクトレベルの安全なファイル）
- `external_diffs`（マージリクエストの差分）

{{< /tab >}}

{{< /tabs >}}

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
sudo gitlab-backup create SKIP=db,uploads
```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

チャートバックアップドキュメントの[コンポーネントのスキップ](https://docs.gitlab.com/charts/backup-restore/backup.html#skipping-components)を参照してください。

{{< /tab >}}

{{< tab title="自己コンパイル" >}}

```shell
sudo -u git -H bundle exec rake gitlab:backup:create SKIP=db,uploads RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

`SKIP=`は、次の目的にも使用されます。

- [tarファイルの作成をスキップする](#skipping-tar-creation)（`SKIP=tar`）。
- [リモートストレージへのバックアップのアップロードをスキップする](#skip-uploading-backups-to-remote-storage)（`SKIP=remote`）。

#### tarファイルの作成をスキップする {#skipping-tar-creation}

{{< alert type="note" >}}

[オブジェクトストレージ](#upload-backups-to-a-remote-cloud-storage)を使用してバックアップする場合、tarファイルの作成をスキップすることはできません。

{{< /alert >}}

バックアップ作成の最終ステップは、すべての要素を含む`.tar`ファイルの生成です。場合によっては、`.tar`ファイルの作成が無駄になったり、直接的に悪影響が及んだりする可能性があります。そのため、`SKIP`環境変数に`tar`を追加することで、このステップをスキップできます。想定されるユースケースは次のとおりです。

- バックアップが他のバックアップソフトウェアに引き継がれる場合。
- 毎回バックアップを展開する必要をなくすことで、増分バックアップを高速化する場合（この場合、`PREVIOUS_BACKUP`および`BACKUP`は指定しないでください。指定してしまった場合、その指定されたバックアップはいったん展開されますが、最終的に`.tar`ファイルは生成されません）。

`SKIP`変数に`tar`を追加すると、バックアップデータが保存されているファイルやディレクトリが、中間ファイル用のディレクトリに残されます。これらのファイルは、新しいバックアップを作成する際に上書きされるため、別の場所にコピーしておく必要があります。システム上にはバックアップを1つしか保持できないためです。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
sudo gitlab-backup create SKIP=tar
```

{{< /tab >}}

{{< tab title="自己コンパイル" >}}

```shell
sudo -u git -H bundle exec rake gitlab:backup:create SKIP=tar RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

#### サーバー側のリポジトリのバックアップを作成する {#create-server-side-repository-backups}

{{< history >}}

- GitLab 16.3で、`gitlab-backup`に[導入](https://gitlab.com/gitlab-org/gitaly/-/issues/4941)されました。
- GitLab 16.6で、最新のバックアップではなく指定したバックアップを復元するためのサーバー側のサポートが`gitlab-backup`に[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132188)されました。
- GitLab 16.6で、増分バックアップを作成するためのサーバー側のサポートが`gitlab-backup`に[導入](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6475)されました。
- GitLab 17.0で、サーバー側のサポートが`backup-utility`に[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/438393)されました。

{{< /history >}}

大規模なリポジトリのバックアップをバックアップアーカイブに保存するのではなく、各リポジトリをホストするGitalyノードがバックアップを作成し、オブジェクトストレージにストリーミングできるように設定することが可能です。これにより、バックアップの作成と復元に必要なネットワークリソースを削減できます。

1. [Gitalyでサーバー側のバックアップ先を設定](../gitaly/configure_gitaly.md#configure-server-side-backups)します。
1. リポジトリのサーバー側オプションを使用してバックアップを作成します。次の例を参照してください。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
sudo gitlab-backup create REPOSITORIES_SERVER_SIDE=true
```

{{< /tab >}}

{{< tab title="自己コンパイル" >}}

```shell
sudo -u git -H bundle exec rake gitlab:backup:create REPOSITORIES_SERVER_SIDE=true
```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

```shell
kubectl exec <Toolbox pod name> -it -- backup-utility --repositories-server-side
```

[cronベースのバックアップ](https://docs.gitlab.com/charts/backup-restore/backup.html#cron-based-backup)を使用している場合は、追加の引数として`--repositories-server-side`フラグを指定します。

{{< /tab >}}

{{< /tabs >}}

#### Gitリポジトリを同時にバックアップする {#back-up-git-repositories-concurrently}

[複数のリポジトリのストレージ](../repository_storage_paths.md)を使用している場合、リポジトリを同時にバックアップまたは復元することで、CPU時間を最大限に活用できます。Rakeタスクのデフォルトの動作を変更するには、次の変数を使用します。

- `GITLAB_BACKUP_MAX_CONCURRENCY`: 同時にバックアップするプロジェクトの最大数。デフォルトは論理CPUの数です。
- `GITLAB_BACKUP_MAX_STORAGE_CONCURRENCY`: 各ストレージで同時にバックアップするプロジェクトの最大数。これにより、リポジトリのバックアップを複数のストレージに分散させることができます。デフォルトは`2`です。

たとえば、リポジトリのストレージが4つある場合は、次のようになります。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
sudo gitlab-backup create GITLAB_BACKUP_MAX_CONCURRENCY=4 GITLAB_BACKUP_MAX_STORAGE_CONCURRENCY=1
```

{{< /tab >}}

{{< tab title="自己コンパイル" >}}

```shell
sudo -u git -H bundle exec rake gitlab:backup:create GITLAB_BACKUP_MAX_CONCURRENCY=4 GITLAB_BACKUP_MAX_STORAGE_CONCURRENCY=1
```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

```yaml
toolbox:
#...
    extra: {}
    extraEnv:
      GITLAB_BACKUP_MAX_CONCURRENCY: 4
      GITLAB_BACKUP_MAX_STORAGE_CONCURRENCY: 1

```

{{< /tab >}}

{{< /tabs >}}

#### リポジトリの増分バックアップ {#incremental-repository-backups}

{{< history >}}

- GitLab 14.10で`incremental_repository_backup`[フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/351383)されました。デフォルトでは無効になっています。
- GitLab 15.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/355945)になりました。機能フラグ`incremental_repository_backup`は削除されました。
- GitLab 16.6で増分バックアップを作成するためのサーバー側のサポートが[導入](https://gitlab.com/gitlab-org/gitaly/-/issues/5461)されました。

{{< /history >}}

{{< alert type="note" >}}

増分バックアップをサポートしているのはリポジトリのみです。そのため、`INCREMENTAL=yes`を使用した場合でも、タスクは自己完結型のバックアップtarアーカイブを作成します。これは、リポジトリ以外のすべてのサブタスクが依然としてフルバックアップを作成している（既存のフルバックアップを上書きする）ためです。すべてのサブタスクに対する増分バックアップのサポートに関する機能リクエストについては、[イシュー19256](https://gitlab.com/gitlab-org/gitlab/-/issues/19256)を参照してください。

{{< /alert >}}

リポジトリの増分バックアップは、前回のバックアップ以降の変更のみを、各リポジトリのバックアップバンドルにパック化するため、フルリポジトリバックアップよりも高速になる場合があります。増分バックアップアーカイブは互いにリンクされていません。各アーカイブはインスタンスの自己完結型バックアップです。増分バックアップを作成するには、既存のバックアップが必要です。

使用するバックアップを選択するには、`PREVIOUS_BACKUP=<backup-id>`オプションを使用します。デフォルトでは、バックアップファイルは[バックアップID](backup_archive_process.md#backup-id)セクションで説明されている方法で作成されます。[`BACKUP`環境変数](#backup-filename)を設定して、ファイル名の`<backup-id>`の部分をオーバーライドできます。

増分バックアップを作成するには、次のコマンドを実行します。

```shell
sudo gitlab-backup create INCREMENTAL=yes PREVIOUS_BACKUP=<backup-id>
```

tar形式のバックアップから[展開済み](#skipping-tar-creation)の増分バックアップを作成するには、`SKIP=tar`を使用します。

```shell
sudo gitlab-backup create INCREMENTAL=yes SKIP=tar
```

#### 特定のリポジトリのストレージをバックアップする {#back-up-specific-repository-storages}

{{< history >}}

- GitLab 15.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86896)されました。

{{< /history >}}

[複数のリポジトリのストレージ](../repository_storage_paths.md)を使用している場合、`REPOSITORIES_STORAGES`オプションを使用することで、特定のリポジトリのストレージにあるリポジトリのみを個別にバックアップできます。このオプションは、カンマ区切りのストレージ名のリストを受け入れます。

次に例を示します。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
sudo gitlab-backup create REPOSITORIES_STORAGES=storage1,storage2
```

{{< /tab >}}

{{< tab title="自己コンパイル" >}}

```shell
sudo -u git -H bundle exec rake gitlab:backup:create REPOSITORIES_STORAGES=storage1,storage2
```

{{< /tab >}}

{{< /tabs >}}

#### 特定のリポジトリをバックアップする {#back-up-specific-repositories}

{{< history >}}

- GitLab 15.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88094)されました。
- GitLab 16.1で[特定のリポジトリのスキップ機能が追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121865)されました。

{{< /history >}}

`REPOSITORIES_PATHS`オプションを使用して、特定のリポジトリをバックアップできます。同様に、`SKIP_REPOSITORIES_PATHS`を使用して、特定のリポジトリをスキップできます。これらのオプションには、プロジェクトまたはグループのパスをカンマ区切りリストで指定します。グループのパスを指定した場合、使用するオプションに応じて、そのグループおよび下位グループ内のすべてのプロジェクトに含まれるすべてのリポジトリが、バックアップ対象に含まれるかスキップされます。

たとえば、グループA（`group-a`）内のすべてのプロジェクトのすべてのリポジトリと、グループB（`group-b/project-c`）内のプロジェクトCのリポジトリをバックアップし、グループA（`group-a/project-d`）内のプロジェクトDをスキップする場合、次のように指定します。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
sudo gitlab-backup create REPOSITORIES_PATHS=group-a,group-b/project-c SKIP_REPOSITORIES_PATHS=group-a/project-d
```

{{< /tab >}}

{{< tab title="自己コンパイル" >}}

```shell
sudo -u git -H bundle exec rake gitlab:backup:create REPOSITORIES_PATHS=group-a,group-b/project-c SKIP_REPOSITORIES_PATHS=group-a/project-d
```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

```shell
REPOSITORIES_PATHS=group-a SKIP_REPOSITORIES_PATHS=group-a/project_a2 backup-utility --skip db,registry,uploads,artifacts,lfs,packages,external_diffs,terraform_state,ci_secure_files,pages
```

{{< /tab >}}

{{< /tabs >}}

#### リモート（クラウド）ストレージにバックアップをアップロードする {#upload-backups-to-a-remote-cloud-storage}

{{< alert type="note" >}}

オブジェクトストレージを使用してバックアップする場合、[tarファイルの作成をスキップ](#skipping-tar-creation)することはできません。

{{< /alert >}}

バックアップスクリプトに、作成した`.tar`ファイルを（[Fogライブラリ](https://fog.github.io/)を使用して）アップロードさせることができます。次の例では、ストレージとしてAmazon S3を使用していますが、Fogでは[他のストレージプロバイダー](https://fog.github.io/storage/)を使用することもできます。GitLabは、AWS、Google、Aliyunの[クラウドドライバーもインポート](https://gitlab.com/gitlab-org/gitlab/-/blob/da46c9655962df7d49caef0e2b9f6bbe88462a02/Gemfile#L113)します。ローカルドライバーも[使用可能](#upload-to-locally-mounted-shares)です。

[GitLabにおけるオブジェクトストレージの使用の詳細については、こちらをご覧ください](../object_storage.md)。

##### Amazon S3の使用 {#using-amazon-s3}

Linuxパッケージ（Omnibus）の場合:

1. 次の内容を`/etc/gitlab/gitlab.rb`に追加します。

   ```ruby
   gitlab_rails['backup_upload_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-west-1',
     # Choose one authentication method
     # IAM Profile
     'use_iam_profile' => true
     # OR AWS Access and Secret key
     'aws_access_key_id' => 'AKIAKIAKI',
     'aws_secret_access_key' => 'secret123'
   }
   gitlab_rails['backup_upload_remote_directory'] = 'my.s3.bucket'
   # Consider using multipart uploads when file size reaches 100 MB. Enter a number in bytes.
   # gitlab_rails['backup_multipart_chunk_size'] = 104857600
   ```

1. IAMプロファイル認証方法を使用している場合は、`backup-utility`を実行するインスタンスに、次のポリシーが設定されていることを確認してください（`<backups-bucket>`は正しいバケット名に置き換えます）。

   ```json
   {
       "Version": "2012-10-17",
       "Statement": [
           {
               "Effect": "Allow",
               "Action": [
                   "s3:PutObject",
                   "s3:GetObject",
                   "s3:DeleteObject"
               ],
               "Resource": "arn:aws:s3:::<backups-bucket>/*"
           }
       ]
   }
   ```

1. 変更を有効にするには、[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

##### S3暗号化バケット {#s3-encrypted-buckets}

AWSは、次の[サーバー側の暗号化のモード](https://docs.aws.amazon.com/AmazonS3/latest/userguide/serv-side-encryption.html)をサポートしています。

- Amazon S3マネージドキー（SSE-S3）
- AWS Key Management Service（SSE-KMS）に保存されたカスタマーマスターキー（CMK）
- カスタマー提供キー（SSE-C）

GitLabでは、任意のモードを使用できます。各モードの設定方法は似ていますが、一部に異なる点があります。

###### SSE-S3 {#sse-s3}

SSE-S3を有効にするには、バックアップストレージのオプションで`server_side_encryption`フィールドを`AES256`に設定します。たとえば、Linuxパッケージ（Omnibus）の場合は次のようになります。

```ruby
gitlab_rails['backup_upload_storage_options'] = {
  'server_side_encryption' => 'AES256'
}
```

###### SSE-KMS {#sse-kms}

SSE-KMSを有効にするには、[KMSキーをAmazonリソースネーム（ARN）で指定する必要があります。形式は`arn:aws:kms:region:acct-id:key/key-id`です](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingKMSEncryption.html)。`backup_upload_storage_options`の設定で、次のように設定します。

- `server_side_encryption`を`aws:kms`に設定します。
- `server_side_encryption_kms_key_id`をキーのARNに設定します。

たとえば、Linuxパッケージ（Omnibus）の場合は次のようになります。

```ruby
gitlab_rails['backup_upload_storage_options'] = {
  'server_side_encryption' => 'aws:kms',
  'server_side_encryption_kms_key_id' => 'arn:aws:<YOUR KMS KEY ID>:'
}
```

###### SSE-C {#sse-c}

SSE-Cでは、次の暗号化オプションを設定する必要があります。

- `backup_encryption`: AES256。
- `backup_encryption_key`: エンコードされていない32バイト（256ビット）のキー。このキーが正確に32バイトでない場合、アップロードは失敗します。

たとえば、Linuxパッケージ（Omnibus）の場合は次のようになります。

```ruby
gitlab_rails['backup_encryption'] = 'AES256'
gitlab_rails['backup_encryption_key'] = '<YOUR 32-BYTE KEY HERE>'
```

キーにバイナリ文字が含まれておりUTF-8でエンコードできない場合は、代わりに`GITLAB_BACKUP_ENCRYPTION_KEY`環境変数でキーを指定します。次に例を示します。

```ruby
gitlab_rails['env'] = { 'GITLAB_BACKUP_ENCRYPTION_KEY' => "\xDE\xAD\xBE\xEF" * 8 }
```

##### Digital Ocean Spaces {#digital-ocean-spaces}

この例は、アムステルダム（AMS3）のバケットに使用できます。

1. 次の内容を`/etc/gitlab/gitlab.rb`に追加します。

   ```ruby
   gitlab_rails['backup_upload_connection'] = {
     'provider' => 'AWS',
     'region' => 'ams3',
     'aws_access_key_id' => 'AKIAKIAKI',
     'aws_secret_access_key' => 'secret123',
     'endpoint'              => 'https://ams3.digitaloceanspaces.com'
   }
   gitlab_rails['backup_upload_remote_directory'] = 'my.s3.bucket'
   ```

1. 変更を有効にするには、[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

Digital Ocean Spacesを使用している場合に`400 Bad Request`（不正なリクエスト）エラーメッセージが表示される場合は、バックアップ暗号化の使用が原因である可能性があります。Digital Ocean Spacesは暗号化をサポートしていないため、`gitlab_rails['backup_encryption']`を含む行を削除するかコメントアウトします。

##### その他のS3プロバイダー {#other-s3-providers}

すべてのS3プロバイダーが、Fogライブラリと完全に互換性があるわけではありません。たとえば、アップロードを試みた後に`411 Length Required`（長さ情報が必要）エラーメッセージが表示された場合は、[この問題が原因](https://github.com/fog/fog-aws/issues/428)で、`aws_signature_version`の値をデフォルト値から`2`にダウングレードする必要がある場合があります。

自己コンパイルによるインストールの場合:

1. `home/git/gitlab/config/gitlab.yml`を編集します。

   ```yaml
     backup:
       # snip
       upload:
         # Fog storage connection settings, see https://fog.github.io/storage/ .
         connection:
           provider: AWS
           region: eu-west-1
           aws_access_key_id: AKIAKIAKI
           aws_secret_access_key: 'secret123'
           # If using an IAM Profile, leave aws_access_key_id & aws_secret_access_key empty
           # ie. aws_access_key_id: ''
           # use_iam_profile: 'true'
         # The remote 'directory' to store your backups. For S3, this would be the bucket name.
         remote_directory: 'my.s3.bucket'
         # Specifies Amazon S3 storage class to use for backups, this is optional
         # storage_class: 'STANDARD'
         #
         # Turns on AWS Server-Side Encryption with Amazon Customer-Provided Encryption Keys for backups, this is optional
         #   'encryption' must be set in order for this to have any effect.
         #   'encryption_key' should be set to the 256-bit encryption key for Amazon S3 to use to encrypt or decrypt.
         #   To avoid storing the key on disk, the key can also be specified via the `GITLAB_BACKUP_ENCRYPTION_KEY` your data.
         # encryption: 'AES256'
         # encryption_key: '<key>'
         #
         #
         # Turns on AWS Server-Side Encryption with Amazon S3-Managed keys (optional)
         # https://docs.aws.amazon.com/AmazonS3/latest/userguide/serv-side-encryption.html
         # For SSE-S3, set 'server_side_encryption' to 'AES256'.
         # For SS3-KMS, set 'server_side_encryption' to 'aws:kms'. Set
         # 'server_side_encryption_kms_key_id' to the ARN of customer master key.
         # storage_options:
         #   server_side_encryption: 'aws:kms'
         #   server_side_encryption_kms_key_id: 'arn:aws:kms:YOUR-KEY-ID-HERE'
   ```

1. 変更を有効にするには、[GitLabを再起動](../restart_gitlab.md#self-compiled-installations)します。

##### Google Cloud Storageを使用する {#using-google-cloud-storage}

Google Cloud Storageを使用してバックアップを保存するには、まずGoogleコンソールからアクセスキーを作成する必要があります。

1. [Googleのストレージ設定ページ](https://console.cloud.google.com/storage/settings)に移動します。
1. **Interoperability**（相互運用性）を選択し、アクセスキーを作成します。
1. **Access Key**（アクセスキー）と**Secret**（シークレット）をメモして、次の設定でこれらの値に置き換えます。
1. バケットの高度な設定で、Access Control（アクセス制御）オプションの**Set object-level and bucket-level permissions**（オブジェクトレベルおよびバケットレベルの権限を設定）が選択されていることを確認します。
1. バケットがすでに作成されていることを確認します。

Linuxパッケージ（Omnibus）の場合:

1. `/etc/gitlab/gitlab.rb`を編集します。

   ```ruby
   gitlab_rails['backup_upload_connection'] = {
     'provider' => 'Google',
     'google_storage_access_key_id' => 'Access Key',
     'google_storage_secret_access_key' => 'Secret',

     ## If you have CNAME buckets (foo.example.com), you might run into SSL issues
     ## when uploading backups ("hostname foo.example.com.storage.googleapis.com
     ## does not match the server certificate"). In that case, uncomment the following
     ## setting. See: https://github.com/fog/fog/issues/2834
     #'path_style' => true
   }
   gitlab_rails['backup_upload_remote_directory'] = 'my.google.bucket'
   ```

1. 変更を有効にするには、[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

自己コンパイルによるインストールの場合:

1. `home/git/gitlab/config/gitlab.yml`を編集します。

   ```yaml
     backup:
       upload:
         connection:
           provider: 'Google'
           google_storage_access_key_id: 'Access Key'
           google_storage_secret_access_key: 'Secret'
         remote_directory: 'my.google.bucket'
   ```

1. 変更を有効にするには、[GitLabを再起動](../restart_gitlab.md#self-compiled-installations)します。

##### Azure Blob Storageを使用する {#using-azure-blob-storage}

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します。

   ```ruby
   gitlab_rails['backup_upload_connection'] = {
    'provider' => 'AzureRM',
    'azure_storage_account_name' => '<AZURE STORAGE ACCOUNT NAME>',
    'azure_storage_access_key' => '<AZURE STORAGE ACCESS KEY>',
    'azure_storage_domain' => 'blob.core.windows.net', # Optional
   }
   gitlab_rails['backup_upload_remote_directory'] = '<AZURE BLOB CONTAINER>'
   ```

   [マネージドID](../object_storage.md#azure-workload-and-managed-identities)を使用している場合は、`azure_storage_access_key`を省略します。

   ```ruby
   gitlab_rails['backup_upload_connection'] = {
     'provider' => 'AzureRM',
     'azure_storage_account_name' => '<AZURE STORAGE ACCOUNT NAME>',
     'azure_storage_domain' => '<AZURE STORAGE DOMAIN>' # Optional
   }
   gitlab_rails['backup_upload_remote_directory'] = '<AZURE BLOB CONTAINER>'
   ```

1. 変更を有効にするには、[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

{{< /tab >}}

{{< tab title="自己コンパイル" >}}

1. `home/git/gitlab/config/gitlab.yml`を編集します。

   ```yaml
     backup:
       upload:
         connection:
           provider: 'AzureRM'
           azure_storage_account_name: '<AZURE STORAGE ACCOUNT NAME>'
           azure_storage_access_key: '<AZURE STORAGE ACCESS KEY>'
         remote_directory: '<AZURE BLOB CONTAINER>'
   ```

1. 変更を有効にするには、[GitLabを再起動](../restart_gitlab.md#self-compiled-installations)します。

{{< /tab >}}

{{< /tabs >}}

詳細については、[Azureパラメータの表](../object_storage.md#azure-blob-storage)を参照してください。

##### バックアップ用のカスタムディレクトリを指定する {#specifying-a-custom-directory-for-backups}

このオプションは、リモートストレージでのみ機能します。バックアップをグループ化する場合は、`DIRECTORY`環境変数を渡します。

```shell
sudo gitlab-backup create DIRECTORY=daily
sudo gitlab-backup create DIRECTORY=weekly
```

#### リモートストレージへのバックアップのアップロードをスキップする {#skip-uploading-backups-to-remote-storage}

[リモートストレージにバックアップをアップロード](#upload-backups-to-a-remote-cloud-storage)するようGitLabを設定している場合は、`SKIP=remote`オプションを使用して、リモートストレージへのバックアップのアップロードをスキップできます。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
sudo gitlab-backup create SKIP=remote
```

{{< /tab >}}

{{< tab title="自己コンパイル" >}}

```shell
sudo -u git -H bundle exec rake gitlab:backup:create SKIP=remote RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

#### ローカルにマウントされた共有にアップロードする {#upload-to-locally-mounted-shares}

Fog [`Local`](https://github.com/fog/fog-local#usage)ストレージプロバイダーを使用して、ローカルにマウントされた共有（例: `NFS`、`CIFS`、`SMB`）にバックアップを送信できます。

これを行うには、次の設定キーを指定する必要があります。

- `backup_upload_connection.local_root`: バックアップのコピー先であるマウントされたディレクトリ。
- `backup_upload_remote_directory`: `backup_upload_connection.local_root`ディレクトリのサブディレクトリ。存在しない場合は作成されます。マウントされたディレクトリのルートにtarballをコピーする場合は、`.`を使用します。

マウントする際に、`local_root`キーに設定したディレクトリは、次のいずれかのユーザーが所有している必要があります。

- `git`ユーザー。`CIFS`および`SMB`の場合は、`git`ユーザーの`uid=`を指定してマウントします。
- バックアップタスクを実行しているユーザー。Linuxパッケージ（Omnibus）の場合、これは`git`ユーザーです。

ファイルシステムのパフォーマンスがGitLab全体のパフォーマンスに影響を及ぼす可能性があります。そのため、[ストレージにクラウドベースのファイルシステムを使用することはおすすめしません](../nfs.md#avoid-using-cloud-based-file-systems)。

##### 競合する設定を回避する {#avoid-conflicting-configuration}

次の設定キーを同じパスに設定しないでください。

- `gitlab_rails['backup_path']`（自己コンパイルによるインストールの場合は`backup.path`）。
- `gitlab_rails['backup_upload_connection'].local_root`（自己コンパイルによるインストールの場合は`backup.upload.connection.local_root`）。

`backup_path`設定キーは、バックアップファイルのローカルの場所を設定します。`upload`設定キーは、アーカイブなどの目的で、バックアップファイルを別のサーバーにアップロードする場合に使用することを想定しています。

これらの設定キーが同じ場所に設定されている場合、アップロード先にバックアップがすでに存在するため、アップロード機能は失敗します。この失敗により、アップロード機能はそのバックアップをアップロードの失敗によって残されたファイルと見なし、削除してしまいます。

##### ローカルにマウントされた共有へのアップロードを設定する {#configure-uploads-to-locally-mounted-shares}

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します。

   ```ruby
   gitlab_rails['backup_upload_connection'] = {
     :provider => 'Local',
     :local_root => '/mnt/backups'
   }

   # The directory inside the mounted folder to copy backups to
   # Use '.' to store them in the root directory
   gitlab_rails['backup_upload_remote_directory'] = 'gitlab_backups'
   ```

1. 変更を有効にするには、[GitLabを再設定します](../restart_gitlab.md#reconfigure-a-linux-package-installation)。

{{< /tab >}}

{{< tab title="自己コンパイル" >}}

1. `home/git/gitlab/config/gitlab.yml`を編集します。

   ```yaml
   backup:
     upload:
       # Fog storage connection settings, see https://fog.github.io/storage/ .
       connection:
         provider: Local
         local_root: '/mnt/backups'
       # The directory inside the mounted folder to copy backups to
       # Use '.' to store them in the root directory
       remote_directory: 'gitlab_backups'
   ```

1. 変更を反映させるため、[GitLabを再起動](../restart_gitlab.md#self-compiled-installations)します。

{{< /tab >}}

{{< /tabs >}}

#### バックアップアーカイブの権限 {#backup-archive-permissions}

GitLabによって作成されるバックアップアーカイブ（`1393513186_2014_02_27_gitlab_backup.tar`）のオーナー/グループは、デフォルトで`git`/`git`であり、0600権限が付与されています。これは、他のシステムユーザーがGitLabデータを読み取るのを防ぐためです。バックアップアーカイブに異なる権限を設定する必要がある場合は、`archive_permissions`設定を使用できます。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します。

   ```ruby
   gitlab_rails['backup_archive_permissions'] = 0644 # Makes the backup archives world-readable
   ```

1. 変更を有効にするには、[GitLabを再設定します](../restart_gitlab.md#reconfigure-a-linux-package-installation)。

{{< /tab >}}

{{< tab title="自己コンパイル" >}}

1. `/home/git/gitlab/config/gitlab.yml`を編集します。

   ```yaml
   backup:
     archive_permissions: 0644 # Makes the backup archives world-readable
   ```

1. 変更を反映させるため、[GitLabを再起動](../restart_gitlab.md#self-compiled-installations)します。

{{< /tab >}}

{{< /tabs >}}

#### 毎日バックアップを実行するようcronを設定する {#configuring-cron-to-make-daily-backups}

{{< alert type="warning" >}}

次のcronジョブでは、[GitLabの設定ファイル](#storing-configuration-files)や[SSHホストキー](https://superuser.com/questions/532040/copy-ssh-keys-from-one-server-to-another-server/532079#532079)はバックアップされません。

{{< /alert >}}

リポジトリとGitLabメタデータをバックアップするcronジョブをスケジュールできます。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `root`ユーザーのcrontabを編集します。

   ```shell
   sudo su -
   crontab -e
   ```

1. さらに次の行を追加して、毎日午前2時にバックアップを実行するようスケジュールします。

   ```plaintext
   0 2 * * * /opt/gitlab/bin/gitlab-backup create CRON=1
   ```

{{< /tab >}}

{{< tab title="自己コンパイル" >}}

1. `git`ユーザーのcrontabを編集します。

   ```shell
   sudo -u git crontab -e
   ```

1. 次の行を末尾に追加します。

   ```plaintext
   # Create a full backup of the GitLab repositories and SQL database every day at 2am
   0 2 * * * cd /home/git/gitlab && PATH=/usr/local/bin:/usr/bin:/bin bundle exec rake gitlab:backup:create RAILS_ENV=production CRON=1
   ```

{{< /tab >}}

{{< /tabs >}}

`CRON=1`の環境設定は、エラーがない場合、すべての進行状況の出力を非表示にするようにバックアップスクリプトに指示します。この方法は、cronスパムを減らせるのでおすすめです。ただし、バックアップの問題をトラブルシューティングする場合は、詳細なログを記録するために`CRON=1`を`--trace`に置き換えてください。

#### ローカルファイルのバックアップライフタイムを制限する（古いバックアップを削除する） {#limit-backup-lifetime-for-local-files-prune-old-backups}

{{< alert type="warning" >}}

バックアップに[カスタムファイル名](#backup-filename)を使用している場合、このセクションで説明する方法は使えません。

{{< /alert >}}

定期的なバックアップがディスク容量を使い切ってしまわないように、バックアップのライフタイムを制限しておくとよいでしょう。それにより、次回のバックアップタスクの実行時に、`backup_keep_time`より古いバックアップは削除されます。

この設定オプションで管理できるのは、ローカルファイルのみです。GitLabは、サードパーティの[オブジェクトストレージ](#upload-backups-to-a-remote-cloud-storage)に保存されている古いファイルを削除しません。これは、ユーザーにファイルのリストおよび削除権限がない可能性があるためです。オブジェクトストレージに適切な保持ポリシーを設定することをおすすめします（例: [AWS S3](https://docs.aws.amazon.com/AmazonS3/latest/user-guide/create-lifecycle.html)）。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

1. `/etc/gitlab/gitlab.rb`を編集します。

   ```ruby
   ## Limit backup lifetime to 7 days - 604800 seconds
   gitlab_rails['backup_keep_time'] = 604800
   ```

1. 変更を有効にするには、[GitLabを再設定します](../restart_gitlab.md#reconfigure-a-linux-package-installation)。

{{< /tab >}}

{{< tab title="自己コンパイル" >}}

1. `/home/git/gitlab/config/gitlab.yml`を編集します。

   ```yaml
   backup:
     ## Limit backup lifetime to 7 days - 604800 seconds
     keep_time: 604800
   ```

1. 変更を反映させるため、[GitLabを再起動](../restart_gitlab.md#self-compiled-installations)します。

{{< /tab >}}

{{< /tabs >}}

#### PgBouncerを使用しているインストール環境でバックアップおよび復元する {#back-up-and-restore-for-installations-using-pgbouncer}

PgBouncer経由の接続でGitLabをバックアップまたは復元しないでください。これらのタスクは、必ず[PgBouncerを回避し、PostgreSQLプライマリデータベースノードに直接接続して実行する](#bypassing-pgbouncer)必要があります。そうしないと、GitLabの停止を引き起こす原因となります。

GitLabのバックアップまたは復元タスクをPgBouncerとともに使用すると、次のエラーメッセージが表示されます。

```ruby
ActiveRecord::StatementInvalid: PG::UndefinedTable
```

GitLabのバックアップが実行されるたびに、GitLabは500エラーを生成し始め、[PostgreSQLのログ](../logs/_index.md#postgresql-logs)にはテーブルが存在しないというエラーが記録されます。

```plaintext
ERROR: relation "tablename" does not exist at character 123
```

これは、タスクが`pg_dump`を使用していることが原因で発生します。[CVE-2018-1058](https://www.postgresql.org/about/news/postgresql-103-968-9512-9417-and-9322-released-1834/)への対応として、[検索パスにnullを設定し、すべてのSQLクエリでスキーマを明示的に指定している](https://gitlab.com/gitlab-org/gitlab/-/issues/23211)ためです。

トランザクションプーリングモードでPgBouncerを使用すると、接続が再利用されるため、PostgreSQLはデフォルトの`public`スキーマを検索できません。その結果、検索パスがクリアされ、テーブルと列が存在しないかのように見えます。

##### PgBouncerを回避する {#bypassing-pgbouncer}

この問題を修正するには、次の2つの方法があります。

1. [環境変数を使用して、バックアップタスクのデータベース設定をオーバーライド](#environment-variable-overrides)する。
1. ノードを再設定して、[PostgreSQLプライマリデータベースノードに直接接続](../postgresql/pgbouncer.md#procedure-for-bypassing-pgbouncer)する。

###### 環境変数をオーバーライドする {#environment-variable-overrides}

{{< history >}}

- GitLab 16.5で複数のデータベースのサポートが[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133177)されました。

{{< /history >}}

デフォルトでは、GitLabは設定ファイル（`database.yml`）に保存されたデータベース設定を使用します。ただし、`GITLAB_BACKUP_`をプレフィックスとして付けて環境変数を設定することで、バックアップタスクと復元タスクのデータベース設定をオーバーライドできます。

- `GITLAB_BACKUP_PGHOST`
- `GITLAB_BACKUP_PGUSER`
- `GITLAB_BACKUP_PGPORT`
- `GITLAB_BACKUP_PGPASSWORD`
- `GITLAB_BACKUP_PGSSLMODE`
- `GITLAB_BACKUP_PGSSLKEY`
- `GITLAB_BACKUP_PGSSLCERT`
- `GITLAB_BACKUP_PGSSLROOTCERT`
- `GITLAB_BACKUP_PGSSLCRL`
- `GITLAB_BACKUP_PGSSLCOMPRESSION`

たとえば、Linuxパッケージ（Omnibus）で192.168.1.10とポート5432を使用するようにデータベースのホストとポートをオーバーライドするには、次のコマンドを実行します。

```shell
sudo GITLAB_BACKUP_PGHOST=192.168.1.10 GITLAB_BACKUP_PGPORT=5432 /opt/gitlab/bin/gitlab-backup create
```

GitLabを[複数のデータベース](../postgresql/_index.md)で実行している場合は、環境変数にデータベース名を含めることでデータベース設定をオーバーライドできます。たとえば、`main`データベースと`ci`データベースを異なるデータベースサーバー上でホストしている場合、`GITLAB_BACKUP_`プレフィックスの後にそれぞれの名前を付加し、`PG*`の名前はそのままにします。

```shell
sudo GITLAB_BACKUP_MAIN_PGHOST=192.168.1.10 GITLAB_BACKUP_CI_PGHOST=192.168.1.12 /opt/gitlab/bin/gitlab-backup create
```

これらのパラメータの詳細については、[PostgreSQLのドキュメント](https://www.postgresql.org/docs/16/libpq-envars.html)を参照してください。

#### リポジトリのバックアップと復元における`gitaly-backup` {#gitaly-backup-for-repository-backup-and-restore}

`gitaly-backup`バイナリは、バックアップ用Rakeタスクで使用され、Gitalyからのリポジトリのバックアップを作成および復元します。`gitaly-backup`は、GitLabからGitalyに直接RPCを呼び出す従来のバックアップ方法に代わるものです。

バックアップ用Rakeタスクが、この実行可能ファイルを見つけられる必要があります。ほとんどの場合、バイナリのパスを変更する必要はありません。デフォルトパスの`/opt/gitlab/embedded/bin/gitaly-backup`で正常に動作するはずです。パスを変更する特別な理由がある場合は、Linuxパッケージ（Omnibus）の設定で変更できます。

1. 次の内容を`/etc/gitlab/gitlab.rb`に追加します。

   ```ruby
   gitlab_rails['backup_gitaly_backup_path'] = '/path/to/gitaly-backup'
   ```

1. 変更を有効にするには、[GitLabを再設定します](../restart_gitlab.md#reconfigure-a-linux-package-installation)。

## 代替バックアップ戦略 {#alternative-backup-strategies}

デプロイごとに利用できる機能が異なるため、まずは[どのデータをバックアップする必要があるか](#what-data-needs-to-be-backed-up)を確認し、それらの機能を活用できるか、またどのように活用できるかを十分に理解する必要があります。

たとえば、Amazon RDSを使用している場合、組み込みのバックアップおよび復元機能を使用してGitLabの[PostgreSQLデータ](#postgresql-databases)を処理し、[バックアップコマンド](#backup-command)の使用時に[PostgreSQLデータを除外](#excluding-specific-data-from-the-backup)する、という選択が可能です。

次のような場合は、バックアップ戦略の一環として、ファイルシステムのデータ転送やスナップショットの使用を検討してください。

- GitLabインスタンスに大量のGitリポジトリデータが含まれており、GitLabのバックアップスクリプトでは処理速度が遅すぎる。
- GitLabインスタンスに多くのフォークされたプロジェクトがあり、標準のバックアップタスクではそれらすべてのGitデータが重複してバックアップされる。
- GitLabインスタンスに問題があり、通常のバックアップタスクとインポート用Rakeタスクを使用できない。

{{< alert type="warning" >}}

Gitaly [Cluster does not support snapshot backups](../gitaly/praefect/_index.md#snapshot-backup-and-recovery)（スナップショットのバックアップをサポートしていません）。

{{< /alert >}}

ファイルシステムのデータ転送またはスナップショットの使用を検討する場合は、次の点に注意してください。

- これらの方法を使用して、異なるオペレーティングシステム間で移行しないでください。移行元と移行先のオペレーティングシステムは、可能な限り同じ環境にそろえる必要があります。たとえば、UbuntuからRHELへの移行にはこれらの方法を使用しないでください。
- データの整合性は非常に重要です。ファイルシステムの転送（`rsync`など）やスナップショット作成を行う前に、GitLab（`sudo gitlab-ctl stop`）を停止する必要があります。これにより、メモリ内のすべてのデータがディスクにフラッシュされます。GitLabは複数のサブシステム（Gitaly、データベース、ファイルストレージ）で構成されており、それぞれ独自のバッファー、キュー、ストレージレイヤーを持っています。GitLabのトランザクションはこれらのサブシステム間にまたがる可能性があるため、トランザクションの一部が異なるパスを通ってディスクに書き込まれる場合があります。稼働中のシステムでファイルシステムの転送やスナップショットを実行すると、メモリに残っているトランザクションの一部をキャプチャできません。

例: Amazon Elastic Block Store（EBS）

- Linuxパッケージ（Omnibus）を使用するGitLabサーバーが、Amazon AWSでホストされています。
- ext4ファイルシステムを使用しているEBSドライブが、`/var/opt/gitlab`にマウントされています。
- この場合、EBSスナップショットを作成してアプリケーションのバックアップを作成できます。
- このバックアップには、すべてのリポジトリ、アップロード、PostgreSQLのデータが含まれます。

例: Logical Volume Manager（LVM）スナップショット+ rsync

- Linuxパッケージ（Omnibus）を使用しているGitLabサーバーで、LVM論理ボリュームが`/var/opt/gitlab`にマウントされています。
- rsyncを使用して`/var/opt/gitlab`ディレクトリをレプリケートしても、rsyncの実行中に変更されるファイルが多すぎるため、信頼できません。
- そのため、rsyncで`/var/opt/gitlab`をレプリケートする代わりに、一時的なLVMスナップショットを作成し、`/mnt/gitlab_backup`に読み取り専用ファイルシステムとしてマウントします。
- これで、長時間実行されるrsyncジョブを実行して、リモートサーバー上に一貫性のあるレプリカを作成できるようになります。
- このレプリカには、すべてのリポジトリ、アップロード、PostgreSQLのデータが含まれます。

仮想サーバー上でGitLabを実行している場合は、GitLabサーバー全体の仮想マシン（VM）スナップショットを作成できる場合もあります。ただし、仮想マシン（VM）スナップショットを作成するにはサーバーをシャットダウンしなければならないことが多くあります。そのため、このソリューションは実用性に制約があります。

### リポジトリデータを個別にバックアップする {#back-up-repository-data-separately}

まず、[リポジトリをスキップ](#excluding-specific-data-from-the-backup)して、既存のGitLabデータを確実にバックアップします。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
sudo gitlab-backup create SKIP=repositories
```

{{< /tab >}}

{{< tab title="自己コンパイル" >}}

```shell
sudo -u git -H bundle exec rake gitlab:backup:create SKIP=repositories RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

ディスク上のGitリポジトリデータを手動でバックアップするには、複数の戦略が考えられます。

- 前述の例のように、Amazon EBSドライブのスナップショットやLVMスナップショット+ rsyncなど、スナップショットを使用する。
- [GitLab Geo](../geo/_index.md)を使用し、Geoセカンダリサイトのリポジトリデータに依存する。
- [書き込みを防止し、Gitリポジトリデータをコピーする](#prevent-writes-and-copy-the-git-repository-data)。
- [リポジトリを読み取り専用としてマークし、オンラインバックアップを作成する（実験的機能）](#online-backup-through-marking-repositories-as-read-only-experimental)。

#### 書き込みを防止し、Gitリポジトリデータをコピーする {#prevent-writes-and-copy-the-git-repository-data}

Gitリポジトリは、一貫した方法でコピーする必要があります。同時書き込み操作中にGitリポジトリをコピーした場合、不整合や破損の問題が発生する可能性があります。詳細については、[イシュー270422](https://gitlab.com/gitlab-org/gitlab/-/issues/270422)に潜在的な問題を説明するより詳しいディスカッションがあります。

Gitリポジトリデータへの書き込みを防ぐには、次の2つの方法があります。

- [メンテナンスモード](../maintenance_mode/_index.md)を使用して、GitLabを読み取り専用状態にする。
- リポジトリをバックアップする前に、すべてのGitalyサービスを停止して、明示的にダウンタイムを設ける。

  ```shell
  sudo gitlab-ctl stop gitaly
  # execute git data copy step
  sudo gitlab-ctl start gitaly
  ```

コピー対象のデータへの書き込みが防止されている限り（不整合や破損の問題を防ぐため）、任意の方法でGitリポジトリデータをコピーできます。優先度と安全性の順に、推奨される方法を示します。

1. `rsync`をアーカイブモード、削除オプション、チェックサムオプション付きで使用する。次に例を示します。

   ```shell
   rsync -aR --delete --checksum source destination # be extra safe with the order as it will delete existing data if inverted
   ```

1. [`tar`パイプを使用して、リポジトリのディレクトリ全体を別のサーバーまたは場所にコピーする](../operations/moving_repositories.md#tar-pipe-to-another-server)。

1. `sftp`、`scp`、`cp`など、その他のコピー方法を使用する。

#### リポジトリを読み取り専用としてマークし、オンラインバックアップを作成する（実験的機能） {#online-backup-through-marking-repositories-as-read-only-experimental}

インスタンス全体のダウンタイムを必要とせずにリポジトリをバックアップする方法の1つは、基盤となるデータをコピーする間、プログラムでプロジェクトを読み取り専用としてマークすることです。

この方法には、いくつかの欠点があります。

- リポジトリが読み取り専用になる時間は、リポジトリのサイズが大きくなるにつれて長くなります。
- 各プロジェクトを読み取り専用としてマークするため、バックアップの完了までの時間が長くなり、不整合が発生する可能性があります。たとえば、最初にバックアップされるプロジェクトと最後にバックアップされるプロジェクトの間で、利用できる最終データの日付が一致しない可能性があります。
- プールリポジトリに対する潜在的な変更を防ぐため、フォークネットワークに含まれるプロジェクトのバックアップ中は、フォークネットワーク全体を完全に読み取り専用にする必要があります。

[Geoチームの手順書プロジェクト](https://gitlab.com/gitlab-org/geo-team/runbooks/-/tree/main/experimental-online-backup-through-rsync)には、このプロセスの自動化を試みる実験的なスクリプトがあります。
