---
stage: Runtime
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 複数のノード用のGeo
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このドキュメントでは、マルチノード構成でGeoを実行するための最小限のリファレンスアーキテクチャについて説明します。お使いのマルチノード構成が、ここで説明されているものと異なる場合は、これらの手順を必要に応じて調整できます。

このガイドは、複数のアプリケーションノード（SidekiqまたはGitLab Rails）がインストールされている場合に適用されます。外部PostgreSQLを使用した単一ノードインストールの場合、[2つの単一ノードサイト（外部PostgreSQLサービスを使用）のGeoのセットアップ](../setup/two_single_node_external_services.md)に従い、他の外部サービスを使用する場合は、設定を調整してください。

## アーキテクチャの概要 {#architecture-overview}

![プライマリおよびセカンダリバックエンドサービスを使用したマルチノード構成でGeoを実行するためのアーキテクチャ](img/geo-ha-diagram_v11_11.png)

**[diagram source - GitLab team members only](https://docs.google.com/drawings/d/1z0VlizKiLNXVVVaERFwgsIOuEgjcUqDTWPdQYsE7Z4c/edit)**（図の出典 - GitLabチームメンバーのみ）

トポロジ図は、**プライマリ**と**セカンダリ**のGeoサイトが、専用の仮想ネットワーキングとプライベートIPアドレスを使用して、2つの異なる場所に配置されていることを前提としています。ネットワークは、1つの地理的な場所にあるすべてのマシンが、プライベートIPアドレスを使用して相互に通信できるように構成されています。指定されたIPアドレスは例であり、デプロイのネットワークトポロジによっては異なる場合があります。

2つのGeoサイトにアクセスする唯一の外部方法は、前の例では`gitlab.us.example.com`と`gitlab.eu.example.com`のHTTPS経由です。

{{< alert type="note" >}}

**プライマリ**と**セカンダリ**のGeoサイトは、HTTPS経由で相互に通信できる必要があります。

{{< /alert >}}

## マルチノード用のRedisとPostgreSQL {#redis-and-postgresql-for-multiple-nodes}

PostgreSQLとRedisのこの設定のセットアップにはさらに複雑さが伴うため、このGeoのマルチノードドキュメントでは説明されていません。

Linuxパッケージを使用してマルチノードのPostgreSQLクラスターおよびRedisクラスターをセットアップする方法の詳細については、以下を参照してください:

- [Geoマルチノードデータベースレプリケーション](../setup/database.md#multi-node-database-replication)
- [Redisマルチノードドキュメント](../../redis/replication_and_failover.md)

{{< alert type="note" >}}

PostgreSQLとRedisにクラウドでホストされているサービスを使用することもできますが、このドキュメントのスコープ外です。

{{< /alert >}}

## 前提要件: 独立して動作する2つのGitLabマルチノードサイト {#prerequisites-two-independently-working-gitlab-multi-node-sites}

1つのGitLabサイトがGeoの**プライマリ**サイトとして機能します。これをセットアップするには、[GitLabリファレンスアーキテクチャドキュメント](../../reference_architectures/_index.md)を使用してください。Geoサイトごとに異なるリファレンスアーキテクチャのサイズを使用できます。既に使用中の動作中のGitLabインスタンスがある場合は、**プライマリ**サイトとして使用できます。

2番目のGitLabサイトは、Geoの**セカンダリ**サイトとして機能します。繰り返しますが、これをセットアップするには、[GitLabリファレンスアーキテクチャドキュメント](../../reference_architectures/_index.md)を使用してください。サインインしてテストすることをお勧めします。ただし、データは**プライマリ**サイトからレプリケーションするプロセスの一部として消去されることに注意してください。

## GitLabサイトをGeoの**プライマリ**サイトとして設定する {#configure-a-gitlab-site-to-be-the-geo-primary-site}

次の手順では、GitLabサイトがGeoの**プライマリ**サイトとして機能するようにします。

### ステップ1: **プライマリ**フロントエンドノードを設定する {#step-1-configure-the-primary-frontend-nodes}

{{< alert type="note" >}}

[`geo_primary_role`](https://docs.gitlab.com/omnibus/roles/#gitlab-geo-roles)は単一ノードサイトを対象としているため、使用しないでください。

{{< /alert >}}

1. `/etc/gitlab/gitlab.rb`を編集し、次の内容を追加します:

   ```ruby
   ##
   ## The unique identifier for the Geo site. See
   ## https://docs.gitlab.com/ee/administration/geo_sites.html#common-settings
   ##
   gitlab_rails['geo_node_name'] = '<site_name_here>'

   ##
   ## Disable automatic migrations
   ##
   gitlab_rails['auto_migrate'] = false
   ```

これらの変更を加えた後、変更を有効にするために[GitLabを再構成](../../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

### ステップ2: サイトを**プライマリ**サイトとして定義する {#step-2-define-the-site-as-the-primary-site}

1. フロントエンドノードのいずれかで、次のコマンドを実行します:

   ```shell
   sudo gitlab-ctl set-geo-primary-node
   ```

{{< alert type="note" >}}

PostgreSQLとRedisは、一般的なGitLabマルチノードセットアップ中に、アプリケーションノードですでに無効になっているはずです。バックエンドノードのサービスへのアプリケーションノードからの接続も設定されている必要があります。[PostgreSQL](../../postgresql/replication_and_failover.md#configuring-the-application-nodes)および[Redis](../../redis/replication_and_failover.md#example-configuration-for-the-gitlab-application)のマルチノード設定ドキュメントを参照してください。

{{< /alert >}}

## 他のGitLabサイトをGeo **セカンダリ**サイトとして設定する {#configure-the-other-gitlab-site-to-be-a-geo-secondary-site}

**セカンダリ**サイトは、他のGitLabマルチノードサイトと同様ですが、3つの大きな違いがあります:

- メインのPostgreSQLデータベースは、Geoの**プライマリ**サイトのPostgreSQLデータベースの読み取り専用のレプリカです。
- 各Geo **セカンダリ**サイトには、追加のPostgreSQLデータベース（「Geoトラッキングデータベース」と呼ばれる）があり、さまざまなリソースのレプリケーションと検証の状態を追跡します。
- 追加のGitLabサービス[`geo-logcursor`](../_index.md#geo-log-cursor)があります

したがって、マルチノードコンポーネントを1つずつセットアップし、一般的なマルチノードセットアップからの逸脱を含めます。ただし、Geoセットアップの一部ではないかのように、最初に真新しいGitLabサイトを設定することを強くお勧めします。これにより、動作中のGitLabサイトであることを確認できます。その後でのみ、Geo **セカンダリ**サイトとして使用するために変更する必要があります。これにより、Geoのセットアップの問題を、関係のないマルチノード設定の問題から分離できます。

### ステップ1: Geo **セカンダリ**サイトでRedisおよびGitalyサービスを設定する {#step-1-configure-the-redis-and-gitaly-services-on-the-geo-secondary-site}

次のサービスを、Geo以外のマルチノードドキュメントを使用して再度設定します:

- [GitLabのRedisの設定](../../redis/replication_and_failover.md#example-configuration-for-the-gitlab-application)（マルチノードの場合）。
- Geoの**プライマリ**サイトから同期されたデータを保存する[Gitaly](../../gitaly/_index.md)。

{{< alert type="note" >}}

[NFS](../../nfs.md)はGitalyの代わりに使用できますが、推奨されていません。

{{< /alert >}}

### ステップ2: Geo **セカンダリ**サイトでGeoトラッキングデータベースを設定する {#step-2-configure-the-geo-tracking-database-on-the-geo-secondary-site}

GeoトラッキングデータベースはマルチノードのPostgreSQLクラスターでは実行できません。[トラッキングデータベース用のPatroniクラスターの設定](../setup/database.md#configuring-patroni-cluster-for-the-tracking-postgresql-database)を参照してください。

次のように、単一ノードでGeoトラッキングデータベースを実行できます:

1. GitLabアプリケーションがトラッキングデータベースへのアクセスに使用するデータベースユーザー名の目的のパスワードのMD5ハッシュを生成します:

   ユーザー名（`gitlab_geo`（デフォルト）はハッシュに組み込まれています。

   ```shell
   gitlab-ctl pg-password-md5 gitlab_geo
   # Enter password: <your_tracking_db_password_here>
   # Confirm password: <your_tracking_db_password_here>
   # fca0b89a972d69f00eb3ec98a5838484
   ```

   次の手順で、このハッシュを使用して`<tracking_database_password_md5_hash>`に入力します。

1. Geoトラッキングデータベースの実行を目的とするマシンで、`/etc/gitlab/gitlab.rb`に以下を追加します:

   ```ruby
   ##
   ## Enable the Geo secondary tracking database
   ##
   geo_postgresql['enable'] = true
   geo_postgresql['listen_address'] = '<ip_address_of_this_host>'
   geo_postgresql['sql_user_password'] = '<tracking_database_password_md5_hash>'

   ##
   ## Configure PostgreSQL connection to the replica database
   ##
   geo_postgresql['md5_auth_cidr_addresses'] = ['<replica_database_ip>/32']
   gitlab_rails['db_host'] = '<replica_database_ip>'

   # Prevent reconfigure from attempting to run migrations on the replica database
   gitlab_rails['auto_migrate'] = false
   ```

1. GitLabのアップグレード時に意図しないダウンタイムが発生しないように、[PostgreSQLの自動アップグレードをオプトアウト](https://docs.gitlab.com/omnibus/settings/database/#opt-out-of-automatic-postgresql-upgrades)します。[GeoでPostgreSQLをアップグレードする際の既知の注意点](https://docs.gitlab.com/omnibus/settings/database/#caveats-when-upgrading-postgresql-with-geo)に注意してください。特に大規模な環境では、PostgreSQLのアップグレードは慎重に計画し、実行する必要があります。その結果、今後、PostgreSQLのアップグレードが定期的なメンテナンスアクティビティーの一部であることを確認してください。

これらの変更を加えた後、変更を有効にするために[GitLabを再構成](../../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

外部PostgreSQLインスタンスを使用している場合は、[外部PostgreSQLインスタンスを使用したGeo](../setup/external_database.md)も参照してください。

### ステップ3: PostgreSQLストリーミングレプリケーションを設定する {#step-3-configure-postgresql-streaming-replication}

[Geoデータベースレプリケーションの手順](../setup/database.md)に従います。

外部PostgreSQLインスタンスを使用している場合は、[外部PostgreSQLインスタンスを使用したGeo](../setup/external_database.md)も参照してください。

ストリーミングレプリケーションを有効にすると、`gitlab-rake db:migrate:status:geo`[セカンダリサイトの設定が完了](#step-7-copy-secrets-and-add-the-secondary-site-in-the-application)するまで失敗します。具体的には、[Geoの設定 - ステップ3。セカンダリサイトを追加します](configuration.md#step-3-add-the-secondary-site)。

### ステップ4: Geo **セカンダリ**サイトでフロントエンドアプリケーションノードを設定する {#step-4-configure-the-frontend-application-nodes-on-the-geo-secondary-site}

{{< alert type="note" >}}

[`geo_secondary_role`](https://docs.gitlab.com/omnibus/roles/#gitlab-geo-roles)は単一ノードサイトを対象としているため、使用しないでください。

{{< /alert >}}

最小限の[アーキテクチャの概要](#architecture-overview)では、GitLabアプリケーションサービスを実行している2台のマシンがあります。これらのサービスは、設定で選択的に有効になります。

[リファレンスアーキテクチャ](../../reference_architectures/_index.md)に概説されている関連する手順に従ってGitLab Railsアプリケーションノードを設定し、次の変更を加えます:

1. Geo **セカンダリ**サイトの各アプリケーションノードで`/etc/gitlab/gitlab.rb`を編集し、以下を追加します:

   ```ruby
   ##
   ## Enable GitLab application services. The application_role enables many services.
   ## Alternatively, you can choose to enable or disable specific services on
   ## different nodes to aid in horizontal scaling and separation of concerns.
   ##
   roles ['application_role']

   ## `application_role` already enables this. You only need this line if
   ## you selectively enable individual services that depend on Rails, like
   ## `puma`, `sidekiq`, `geo-logcursor`, and so on.
   gitlab_rails['enable'] = true

   ##
   ## Enable Geo Log Cursor service
   ##
   geo_logcursor['enable'] = true

   ##
   ## The unique identifier for the Geo site. See
   ## https://docs.gitlab.com/ee/administration/geo_sites.html#common-settings
   ##
   gitlab_rails['geo_node_name'] = '<site_name_here>'

   ##
   ## Disable automatic migrations
   ##
   gitlab_rails['auto_migrate'] = false

   ##
   ## Configure the connection to the tracking database
   ##
   geo_secondary['enable'] = true
   geo_secondary['db_host'] = '<geo_tracking_db_host>'
   geo_secondary['db_password'] = '<geo_tracking_db_password>'

   ##
   ## Configure connection to the streaming replica database, if you haven't
   ## already
   ##
   gitlab_rails['db_host'] = '<replica_database_host>'
   gitlab_rails['db_password'] = '<replica_database_password>'

   ##
   ## Configure connection to Redis, if you haven't already
   ##
   gitlab_rails['redis_host'] = '<redis_host>'
   gitlab_rails['redis_password'] = '<redis_password>'

   ##
   ## If you are using custom users not managed by Omnibus, you need to specify
   ## UIDs and GIDs like below, and ensure they match between nodes in a
   ## cluster to avoid permissions issues
   ##
   user['uid'] = 9000
   user['gid'] = 9000
   web_server['uid'] = 9001
   web_server['gid'] = 9001
   registry['uid'] = 9002
   registry['gid'] = 9002
   ```

{{< alert type="note" >}} `postgresql['sql_user_password'] = 'md5 digest of secret'`Linuxパッケージを使用してPostgreSQLクラスターをセットアップし、`postgresql['sql_user_password'] = 'md5 digest of secret'`を設定した場合は、`gitlab_rails['db_password']`と`geo_secondary['db_password']`に平文パスワードが含まれていることに注意してください。これらの設定は、Railsノードがデータベースに接続できるようにするために使用されます。

{{< /alert >}}

{{< alert type="note" >}}

 現在のノードのIPが`postgresql['md5_auth_cidr_addresses']`のリードレプリカのデータベースの設定にリストされていることを確認して、このノードのRailsがPostgreSQLに接続できるようにします。{{< /alert >}}

これらの変更を加えた後、変更を有効にするために[GitLabを再構成](../../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

[アーキテクチャの概要](#architecture-overview)トポロジでは、次のGitLabサービスが「フロントエンド」ノードで有効になっています:

- `geo-logcursor`
- `gitlab-pages`
- `gitlab-workhorse`
- `logrotate`
- `nginx`
- `registry`
- `remote-syslog`
- `sidekiq`
- `puma`

`sudo gitlab-ctl status`をフロントエンドアプリケーションノードで実行して、これらのサービスが存在することを確認します。

### ステップ5: Geo **セカンダリ**サイト用のロードバランサーをセットアップする {#step-5-set-up-the-loadbalancer-for-the-geo-secondary-site}

最小限の[アーキテクチャの概要](#architecture-overview)は、アプリケーションノードへのトラフィックをルーティングするために、地理的な場所ごとにロードバランサーを示しています。

詳細については、[複数のノードを持つGitLabのロードバランサー](../../load_balancer.md)を参照してください。

### ステップ6: Geo **セカンダリ**サイトでバックエンドアプリケーションノードを設定する {#step-6-configure-the-backend-application-nodes-on-the-geo-secondary-site}

最小限の[アーキテクチャの概要](#architecture-overview)は、すべてのアプリケーションサービスが同じマシン上で一緒に実行されていることを示しています。ただし、複数のノードの場合、[すべてのサービスを個別に実行することを強くお勧めします](../../reference_architectures/_index.md)。

たとえば、Sidekiqノードは、以前にドキュメント化されたフロントエンドアプリケーションノードと同様に設定できますが、`sidekiq`サービスのみを実行するように変更されています:

1. Geo **セカンダリ**サイトの各Sidekiqノードで`/etc/gitlab/gitlab.rb`を編集し、以下を追加します:

   ```ruby
   ##
   ## Enable the Sidekiq service
   ##
   sidekiq['enable'] = true
   gitlab_rails['enable'] = true

   ##
   ## The unique identifier for the Geo site. See
   ## https://docs.gitlab.com/ee/administration/geo_sites.html#common-settings
   ##
   gitlab_rails['geo_node_name'] = '<site_name_here>'

   ##
   ## Disable automatic migrations
   ##
   gitlab_rails['auto_migrate'] = false

   ##
   ## Configure the connection to the tracking database
   ##
   geo_secondary['enable'] = true
   geo_secondary['db_host'] = '<geo_tracking_db_host>'
   geo_secondary['db_password'] = '<geo_tracking_db_password>'

   ##
   ## Configure connection to the streaming replica database, if you haven't
   ## already
   ##
   gitlab_rails['db_host'] = '<replica_database_host>'
   gitlab_rails['db_password'] = '<replica_database_password>'

   ##
   ## Configure connection to Redis, if you haven't already
   ##
   gitlab_rails['redis_host'] = '<redis_host>'
   gitlab_rails['redis_password'] = '<redis_password>'

   ##
   ## If you are using custom users not managed by Omnibus, you need to specify
   ## UIDs and GIDs like below, and ensure they match between nodes in a
   ## cluster to avoid permissions issues
   ##
   user['uid'] = 9000
   user['gid'] = 9000
   web_server['uid'] = 9001
   web_server['gid'] = 9001
   registry['uid'] = 9002
   registry['gid'] = 9002
   ```

   `geo_logcursor['enable'] = true`で`geo-logcursor`サービスのみを実行するようにノードを同様に設定し、`sidekiq['enable'] = false`でSidekiqを無効にすることができます。

   これらのノードは、ロードバランサーにアタッチする必要はありません。

### ステップ7: シークレットをコピーし、アプリケーションにセカンダリサイトを追加する {#step-7-copy-secrets-and-add-the-secondary-site-in-the-application}

1. [GitLabを設定する](configuration.md) **プライマリ**サイトと**セカンダリ**サイトを設定します。
