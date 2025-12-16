---
stage: Runtime
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 外部PostgreSQLインスタンスでのGitLab Geo
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このドキュメントは、Linuxパッケージによって管理されていないPostgreSQLデータベースのインスタンスを使用している場合に該当します。これには、[クラウドで管理されたインスタンス](../../reference_architectures/_index.md#best-practices-for-the-database-services)、または手動でインストールおよび構成されたPostgreSQLデータベースのインスタンスが含まれます。

Geoサイトを再構築する必要がある場合にバージョンのミスマッチを回避するために、[Linuxパッケージに同梱されている](../../package_information/postgresql_versions.md) PostgreSQLデータベースのバージョンのいずれかを使用していることを確認してください。[バージョンの不一致を回避する](../_index.md#requirements-for-running-geo)ようにしてください。

{{< alert type="note" >}}

GitLab Geoを使用している場合は、Linuxパッケージを使用するか、[検証済みのクラウド管理インスタンス](../../reference_architectures/_index.md#recommended-cloud-providers-and-services)を使用してインストールされたインスタンスを実行することを強くお勧めします。これらに基づいて積極的に開発およびテストを行っているためです。他の外部データベースとの互換性は保証されていません。

{{< /alert >}}

## **プライマリ**サイト {#primary-site}

1. **プライマリサイトのRailsノード**にSSHで接続し、rootとしてログインします:

   ```shell
   sudo -i
   ```

1. `/etc/gitlab/gitlab.rb`を編集して、以下を追加します:

   ```ruby
   ##
   ## Geo Primary role
   ## - configure dependent flags automatically to enable Geo
   ##
   roles ['geo_primary_role']

   ##
   ## The unique identifier for the Geo site. See
   ## https://docs.gitlab.com/ee/administration/geo_sites.html#common-settings
   ##
   gitlab_rails['geo_node_name'] = '<site_name_here>'
   ```

1. 変更を有効にするには、**Rails node**（Railsノード）を再構成します:

   ```shell
   gitlab-ctl reconfigure
   ```

1. サイトを**プライマリ**サイトとして定義するには、**Rails node**（Railsノード）で次のコマンドを実行します:

   ```shell
   gitlab-ctl set-geo-primary-node
   ```

   このコマンドは、`external_url`で定義された`/etc/gitlab/gitlab.rb`を使用します。

### 外部データベースがレプリケーションされるように構成します {#configure-the-external-database-to-be-replicated}

外部データベースをセットアップするには、次のいずれかを実行します:

- 自分で[ストリーミングレプリケーション](https://www.postgresql.org/docs/16/warm-standby.html#STREAMING-REPLICATION-SLOTS)を設定します（たとえば、Amazon RDS、またはLinuxパッケージで管理されていないベアメタル）。
- 次のように、Linuxパッケージインストールの設定を手動で実行します。

#### プライマリデータベースをレプリケートするために、クラウドプロバイダーのツールを活用する {#leverage-your-cloud-providers-tools-to-replicate-the-primary-database}

RDSを使用するAWS EC2にプライマリサイトがセットアップされているとします。これで、別のリージョンに読み取り専用レプリカを作成でき、レプリケーションプロセスはAWSによって管理されます。セカンダリRailsノードがデータベースにアクセスできるように、必要に応じてネットワークACL（アクセス制御リスト）、サブネット、およびセキュリティグループを設定していることを確認してください。

次の手順では、一般的なクラウドプロバイダーの読み取り専用レプリカを作成する方法について詳しく説明します:

- Amazon RDS - [リードレプリカの作成](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ReadRepl.html#USER_ReadRepl.Create)
- Azure PostgreSQLデータベース - [Azure PostgreSQLデータベースでリードレプリカのデータベース](https://learn.microsoft.com/en-us/azure/postgresql/single-server/how-to-read-replicas-portal)を作成および管理する
- Google Cloud SQL - [リードレプリカの作成](https://cloud.google.com/sql/docs/postgres/replication/create-replica)

読み取り専用レプリカがセットアップされたら、[セカンダリサイト](#configure-secondary-site-to-use-the-external-read-replica)を設定するに進むことができます

{{< alert type="warning" >}}

たとえば、オンプレミスのプライマリデータベースからRDSセカンダリにレプリケートするために、[AWS PostgreSQLデータベース移行サービス](https://aws.amazon.com/dms/)や[Google Cloud PostgreSQLデータベース移行サービス](https://cloud.google.com/database-migration)などの論理レプリケーションメソッドの使用はサポートされていません。

{{< /alert >}}

#### レプリケーションのためにプライマリデータベースを手動で構成する {#manually-configure-the-primary-database-for-replication}

[`geo_primary_role`](https://docs.gitlab.com/omnibus/roles/#gitlab-geo-roles)は、`pg_hba.conf`および`postgresql.conf`に変更を加えることによって、レプリケーションされるように**プライマリ**ノードのデータベースを構成します。外部データベースの設定に次の設定変更を手動で行い、変更を有効にするために、その後PostgreSQLデータベースを再起動してください:

```plaintext
##
## Geo Primary Role
## - pg_hba.conf
##
host    all         all               <trusted primary IP>/32       md5
host    replication gitlab_replicator <trusted primary IP>/32       md5
host    all         all               <trusted secondary IP>/32     md5
host    replication gitlab_replicator <trusted secondary IP>/32     md5
```

```plaintext
##
## Geo Primary Role
## - postgresql.conf
##
wal_level = hot_standby
max_wal_senders = 10
wal_keep_segments = 50
max_replication_slots = 1 # number of secondary instances
hot_standby = on
```

## **セカンダリ**サイト {#secondary-sites}

### レプリカデータベースを手動で構成する {#manually-configure-the-replica-database}

外部レプリカデータベースの`pg_hba.conf`および`postgresql.conf`に次の設定変更を手動で行い、変更を有効にするために、その後PostgreSQLデータベースを再起動してください:

```plaintext
##
## Geo Secondary Role
## - pg_hba.conf
##
host    all         all               <trusted secondary IP>/32     md5
host    replication gitlab_replicator <trusted secondary IP>/32     md5
host    all         all               <trusted primary IP>/24       md5
```

```plaintext
##
## Geo Secondary Role
## - postgresql.conf
##
wal_level = hot_standby
max_wal_senders = 10
wal_keep_segments = 10
hot_standby = on
```

### 外部リードレプリカのデータベースを使用するように**セカンダリ**サイトを構成する {#configure-secondary-site-to-use-the-external-read-replica}

Linuxパッケージのインストールでは、[`geo_secondary_role`](https://docs.gitlab.com/omnibus/roles/#gitlab-geo-roles)には3つの主な機能があります:

1. レプリカデータベースを構成します。
1. トラッキングデータベースを構成します。
1. [Geoログカーソル](../_index.md#geo-log-cursor)を有効にします（このセクションでは説明しません）。

外部リードレプリカのデータベースへの接続を構成し、ログカーソルを有効にするには:

1. **セカンダリ**サイトの各**Rails、Sidekiq、Geo Log Cursor**ノードにSSHで接続し、rootとしてログインします:

   ```shell
   sudo -i
   ```

1. `/etc/gitlab/gitlab.rb`を編集し、次の行を追加します

   ```ruby
   ##
   ## Geo Secondary role
   ## - configure dependent flags automatically to enable Geo
   ##
   roles ['geo_secondary_role']

   # note this is shared between both databases,
   # make sure you define the same password in both
   gitlab_rails['db_password'] = '<your_primary_db_password_here>'

   gitlab_rails['db_username'] = 'gitlab'
   gitlab_rails['db_host'] = '<database_read_replica_host>'

   # Disable the bundled Omnibus PostgreSQL because we are
   # using an external PostgreSQL
   postgresql['enable'] = false
   ```

1. ファイルを保存して、[GitLabを再構成](../../restart_gitlab.md#reconfigure-a-linux-package-installation)します

### トラッキングデータベースを構成する {#configure-the-tracking-database}

**セカンダリ**サイトは、レプリケーションステータスを追跡し、潜在的なレプリケーションのイシューから自動的に回復するために、別のPostgreSQLデータベースインストールをトラッキングデータベースとして使用します。Linuxパッケージは、`roles ['geo_secondary_role']`が設定されている場合、自動的にトラッキングデータベースを構成します。このデータベースをLinuxパッケージのインストール以外で実行する場合は、次の手順を使用します。

#### 内部および外部トラッキングデータベースについて {#understanding-internal-and-external-tracking-databases}

トラッキングデータベースは、次のいずれかになるように構成できます:

- 内部（`geo_postgresql['enable'] = true`）: トラッキングデータベースPostgreSQLデータベースインスタンスとして実行されます。これはデフォルトです。これはデフォルトです。
- 外部（`geo_postgresql['enable'] = false`）: トラッキングデータベースは、別のサーバー上、またはクラウド管理サービスとして実行されます。

マルチノードセカンダリサイトのセットアップでは、1つのRailsノードでトラッキングデータベースを有効にすると、サイト内の他のすべてのRailsノードに対して「外部」になります。他のすべてのRailsノードは、`geo_postgresql['enable'] = false`を設定し、そのトラッキングデータベースに接続するための接続詳細を指定する必要があります。

#### クラウドプロバイダー管理データベースサービス {#cloud-managed-database-services}

トラッキングデータベースにクラウド管理サービスを使用している場合は、トラッキングデータベースユーザーに追加のロールを付与する必要がある場合があります（デフォルトでは`gitlab_geo`です）:

- Amazon RDSには、[`rds_superuser`](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.html#Appendix.PostgreSQL.CommonDBATasks.Roles)ロールが必要です。
- Azure PostgreSQLデータベースには、[`azure_pg_admin`](https://learn.microsoft.com/en-us/azure/postgresql/single-server/how-to-create-users#how-to-create-additional-admin-users-in-azure-database-for-postgresql)ロールが必要です。
- Google Cloud SQLには、[`cloudsqlsuperuser`](https://cloud.google.com/sql/docs/postgres/users#default-users)ロールが必要です。

これは、インストールとアップグレード中に拡張機能をインストールするためです。別の方法として、[拡張機能が手動でインストールされていることを確認し、将来のGitLabアップグレード中に発生する可能性のある問題についてお読みください](../../../install/postgresql_extensions.md)。

{{< alert type="note" >}}

Amazon RDSをトラッキングデータベースとして使用する場合は、セカンダリデータベースへのアクセス権があることを確認してください。残念ながら、送信ルールはRDS PostgreSQLデータベースには適用されないため、同じセキュリティグループを割り当てるだけでは十分ではありません。したがって、ポート5432のトラッキングデータベースTCPトラフィックを許可する受信ルールを、読み取り専用のセキュリティグループに明示的に追加する必要があります。

{{< /alert >}}

#### トラッキングデータベースを作成する {#create-the-tracking-database}

PostgreSQLインスタンスでトラッキングデータベースを作成および構成します:

1. [データベース要件に関するドキュメント](../../../install/requirements.md#postgresql)に従ってPostgreSQLをセットアップします。
1. 任意のパスワードを持つ`gitlab_geo`ユーザーをセットアップし、`gitlabhq_geo_production`データベースを作成して、ユーザーをデータベースのオーナーにします。このセットアップの例は、[セルフコンパイルインストールのドキュメント](../../../install/self_compiled/_index.md#7-database)にあります。
1. クラウドプロバイダー管理のPostgreSQLデータベースを使用**not**（していない）場合は、セカンダリサイトがトラッキングデータベースと関連付けられている`pg_hba.conf`を手動で変更することにより、トラッキングデータベースと通信できることを確認してください。変更を有効にするために、その後PostgreSQLデータベースを再起動することを忘れないでください:

   ```plaintext
   ##
   ## Geo Tracking Database Role
   ## - pg_hba.conf
   ##
   host    all         all               <trusted tracking IP>/32      md5
   host    all         all               <trusted secondary IP>/32     md5
   # In multi-node setups, add entries for all Rails nodes that will connect
   ```

#### GitLabを設定する {#configure-gitlab}

このデータベースを使用するようにGitLabを構成します。これらの手順は、LinuxパッケージおよびDockerデプロイ用です。

1. GitLab **セカンダリ**サーバーにSSHで接続し、rootとしてログインします:

   ```shell
   sudo -i
   ```

1. PostgreSQLインスタンスを備えたマシンの接続パラメータと認証情報を使用して`/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   geo_secondary['db_username'] = 'gitlab_geo'
   geo_secondary['db_password'] = '<your_tracking_db_password_here>'

   geo_secondary['db_host'] = '<tracking_database_host>'
   geo_secondary['db_port'] = <tracking_database_port>      # change to the correct port
   geo_postgresql['enable'] = false     # don't use internal managed instance
   ```

   マルチノードのセットアップでは、外部トラッキングデータベースへの接続が必要な各Railsノードにこの設定を適用します。

1. ファイルを保存して、[GitLabを再構成](../../restart_gitlab.md#reconfigure-a-linux-package-installation)します

#### データベーススキーマをセットアップする {#set-up-the-database-schema}

LinuxパッケージおよびDockerデプロイの[以前にリストされた手順](#configure-gitlab)の再構成コマンドは、これらの手順を自動的に処理する必要があります。

1. このタスクは、データベーススキーマを作成します。データベースユーザーがスーパーユーザーである必要があります。

   ```shell
   sudo gitlab-rake db:create:geo
   ```

1. Railsデータベースの移行（スキーマとデータの更新）の適用も、再構成によって実行されます。`geo_secondary['auto_migrate'] = false`が設定されている場合、またはスキーマが手動で作成された場合、この手順が必要になります:

   ```shell
   sudo gitlab-rake db:migrate:geo
   ```
