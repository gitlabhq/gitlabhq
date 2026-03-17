---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 複数のノード用のGeoをセットアップする
description: "Geoをマルチノード環境で設定し、プライマリサイトおよびセカンダリサイトのセットアップ、データベースレプリケーション、トラッキングデータベースの設定、ロードバランサーのインテグレーションをカバーします。"
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このドキュメントでは、Geoをマルチノードの設定で実行するための最小限のリファレンスアーキテクチャについて説明します。お使いのマルチノードセットアップが記載されているものと異なる場合は、これらの手順を必要に応じて調整できます。

このガイドは、複数のアプリケーションノード（SidekiqまたはGitLab Rails）があるインストールに適用されます。外部PostgreSQLを使用する単一ノードのインストールについては、[2つの単一ノードサイト（外部PostgreSQLサービスあり）のGeoをセットアップ](../setup/two_single_node_external_services.md)に従い、他の外部サービスを使用する場合は設定を調整してください。

## アーキテクチャの概要 {#architecture-overview}

![プライマリおよびセカンダリバックエンドサービスを含むマルチノード設定でGeoを実行するためのアーキテクチャ](img/geo-ha-diagram_v11_11.png)

**[図のソース - GitLabチームメンバーのみ](https://docs.google.com/drawings/d/1z0VlizKiLNXVVVaERFwgsIOuEgjcUqDTWPdQYsE7Z4c/edit)**

トポロジー図は、**プライマリ**および**セカンダリ**のGeoサイトが、プライベートIPアドレスを持つ独自の仮想ネットワーク上の2つの別々の場所に配置されていることを前提としています。ネットワークは、1つの地理的場所にあるすべてのマシンがプライベートIPアドレスを使用して相互に通信できるように設定されています。指定されたIPアドレスは例であり、デプロイのネットワークトポロジーによって異なる場合があります。

2つのGeoサイトに外部からアクセスする唯一の方法は、前の例では`gitlab.us.example.com`および`gitlab.eu.example.com`でのHTTPS経由です。

> [!note]
> **プライマリ**および**セカンダリ**のGeoサイトは、HTTPS経由で相互に通信できる必要があります。

## マルチノードのRedisおよびPostgreSQL {#redis-and-postgresql-for-multiple-nodes}

PostgreSQLとRedisのこの設定をセットアップする際の追加の複雑さのため、このGeoマルチノードドキュメントでは取り上げていません。

マルチノードのPostgreSQLクラスターおよびRedisクラスターをLinuxパッケージを使用してセットアップする方法の詳細については、以下を参照してください:

- [Geoマルチノードデータベースレプリケーション](../setup/database.md#multi-node-database-replication)
- [Redisマルチノードドキュメント](../../redis/replication_and_failover.md)

> [!note]
> PostgreSQLとRedisにクラウドホスト型サービスを使用することは可能ですが、これはこのドキュメントのスコープ外です。

## 前提条件: 独立して機能する2つのGitLabマルチノードサイト {#prerequisites-two-independently-working-gitlab-multi-node-sites}

1つのGitLabサイトがGeoの**プライマリ**サイトとして機能します。これをセットアップするには、[GitLabリファレンスアーキテクチャドキュメント](../../reference_architectures/_index.md)を使用します。各Geoサイトに異なるリファレンスアーキテクチャサイズを使用できます。稼働中のGitLabインスタンスが既にある場合は、それを**プライマリ**サイトとして使用できます。

2番目のGitLabサイトは、Geoの**セカンダリ**サイトとして機能します。繰り返しになりますが、これをセットアップするには[GitLabリファレンスアーキテクチャドキュメント](../../reference_architectures/_index.md)を使用します。サインインしてテストすることをお勧めします。ただし、データは**プライマリ**サイトからのレプリケーションプロセスの一部として消去されることに注意してください。

## GitLabサイトをGeo**プライマリ**サイトとして設定する {#configure-a-gitlab-site-to-be-the-geo-primary-site}

以下の手順により、GitLabサイトがGeo**プライマリ**サイトとして機能できるようになります。

### ステップ1: **プライマリ**フロントエンドノードを設定 {#step-1-configure-the-primary-frontend-nodes}

> [!note]
> [`geo_primary_role`](https://docs.gitlab.com/omnibus/roles/#gitlab-geo-roles)は単一ノードサイト用であるため、使用しないでください。

1. `/etc/gitlab/gitlab.rb`を編集して、以下を追加します:

   ```ruby
   ##
   ## The unique identifier for the Geo site. See
   ## https://docs.gitlab.com/administration/geo_sites/#common-settings
   ##
   gitlab_rails['geo_node_name'] = '<site_name_here>'

   ##
   ## Disable automatic migrations
   ##
   gitlab_rails['auto_migrate'] = false
   ```

これらの変更を行った後、変更を有効にするために[GitLabを再設定](../../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

### ステップ2: サイトを**プライマリ**サイトとして定義する {#step-2-define-the-site-as-the-primary-site}

1. フロントエンドノードのいずれかで次のコマンドを実行します:

   ```shell
   sudo gitlab-ctl set-geo-primary-node
   ```

> [!note]
> 通常のGitLabマルチノードセットアップ中に、アプリケーションノードでPostgreSQLとRedisはすでに無効になっているはずです。アプリケーションノードからバックエンドノード上のサービスへの接続も設定されている必要があります。[PostgreSQL](../../postgresql/replication_and_failover.md#configuring-the-application-nodes)および[Redis](../../redis/replication_and_failover.md#example-configuration-for-the-gitlab-application)のマルチノード設定ドキュメントを参照してください。

## 他のGitLabサイトをGeo**セカンダリ**サイトとして設定する {#configure-the-other-gitlab-site-to-be-a-geo-secondary-site}

**セカンダリ**サイトは他のGitLabマルチノードサイトと同様ですが、3つの大きな違いがあります:

- メインのPostgreSQLデータベースは、Geo **プライマリ**サイトのPostgreSQLデータベースの読み取り専用レプリカです。
- 各Geo **セカンダリ**サイトには、「Geoトラッキングデータベース」と呼ばれる追加のPostgreSQLデータベースがあり、さまざまなリソースのレプリケーションおよび検証ステータスを追跡するします。
- 追加のGitLabサービス[`geo-logcursor`](../_index.md#geo-log-cursor)があります。

したがって、マルチノードコンポーネントを1つずつセットアップし、一般的なマルチノードセットアップからの逸脱を含めます。ただし、最初にGeoセットアップの一部ではないかのように、新品のGitLabサイトを設定することを強くお勧めします。これにより、稼働中のGitLabサイトであることを確認できます。その後でのみ、Geo **セカンダリ**サイトとして使用するために変更する必要があります。これは、Geoセットアップの問題と無関係なマルチノード設定の問題を分離するのに役立ちます。

### ステップ1: Geo **セカンダリ**サイトでRedisおよびGitalyサービスを設定する {#step-1-configure-the-redis-and-gitaly-services-on-the-geo-secondary-site}

非Geoマルチノードドキュメントを使用して、以下のサービスを設定します:

- 複数のノード用の[GitLab用Redisの設定](../../redis/replication_and_failover.md#example-configuration-for-the-gitlab-application)。
- Geo **プライマリ**サイトから同期されたデータを保存する[Gitaly](../../gitaly/_index.md)。

> [!note]
> [NFS](../../nfs.md)はGitalyの代わりに使用できますが、推奨されません。

### ステップ2: Geo **セカンダリ**サイトでGeoトラッキングデータベースを設定する {#step-2-configure-the-geo-tracking-database-on-the-geo-secondary-site}

GeoトラッキングデータベースはマルチノードPostgreSQLクラスターでは実行できません。[トラッキングPostgreSQLデータベースのPatroniクラスターの設定](../setup/database.md#configuring-patroni-cluster-for-the-tracking-postgresql-database)を参照してください。

Geoトラッキングデータベースを単一ノードで次のように実行できます:

1. GitLabアプリケーションがトラッキングデータベースにアクセスするために使用するデータベースユーザー名の希望するパスワードのMD5ハッシュを生成します:

   ユーザー名（`gitlab_geo`デフォルト）がハッシュに組み込まれます。

   ```shell
   gitlab-ctl pg-password-md5 gitlab_geo
   # Enter password: <your_tracking_db_password_here>
   # Confirm password: <your_tracking_db_password_here>
   # fca0b89a972d69f00eb3ec98a5838484
   ```

   このハッシュを使用して、次のステップで`<tracking_database_password_md5_hash>`を記入します。

1. Geoトラッキングデータベースを実行するマシンで、`/etc/gitlab/gitlab.rb`に以下を追加します:

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

1. GitLabのアップグレード時に意図しないダウンタイムを避けるため、[PostgreSQLの自動アップグレードをオプトアウト](https://docs.gitlab.com/omnibus/settings/database/#opt-out-of-automatic-postgresql-upgrades)します。GeoでのPostgreSQLアップグレードに関する既知の[注意点](https://docs.gitlab.com/omnibus/settings/database/#caveats-when-upgrading-postgresql-with-geo)に注意してください。特に大規模な環境では、PostgreSQLのアップグレードは計画的かつ意識的に実行する必要があります。その結果として、今後、PostgreSQLのアップグレードが定期的なメンテナンス活動の一部であることを確認してください。

これらの変更を行った後、変更を有効にするために[GitLabを再設定](../../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

外部PostgreSQLインスタンスを使用している場合は、[外部PostgreSQLインスタンスを持つGeo](../setup/external_database.md)も参照してください。

### ステップ3: PostgreSQLストリーミングレプリケーションを設定する {#step-3-configure-postgresql-streaming-replication}

[Geoデータベースレプリケーションの手順](../setup/database.md)に従ってください。

外部PostgreSQLインスタンスを使用している場合は、[外部PostgreSQLインスタンスを持つGeo](../setup/external_database.md)も参照してください。

ストリーミングレプリケーションを有効にした後、[セカンダリサイトの設定が完了](#step-7-copy-secrets-and-add-the-secondary-site-in-the-application)するまで`gitlab-rake db:migrate:status:geo`は失敗します。具体的には[Geo設定 - ステップ3。セカンダリサイトを追加する](configuration.md#step-3-add-the-secondary-site)

### ステップ4: Geo **セカンダリ**サイトでフロントエンドアプリケーションノードを設定する {#step-4-configure-the-frontend-application-nodes-on-the-geo-secondary-site}

> [!note]
> [`geo_secondary_role`](https://docs.gitlab.com/omnibus/roles/#gitlab-geo-roles)は単一ノードサイト用であるため、使用しないでください。

最小限の[アーキテクチャ図](#architecture-overview)では、2台のマシンがGitLabアプリケーションサービスを実行しています。これらのサービスは設定で選択的に有効になります。

[リファレンスアーキテクチャ](../../reference_architectures/_index.md)に示されている関連する手順に従ってGitLab Railsアプリケーションノードを設定し、以下の変更を加えます:

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
   ## https://docs.gitlab.com/administration/geo_sites/#common-settings
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

> [!warning]
> Linuxパッケージを使用してPostgreSQLクラスターをセットアップし、`postgresql['sql_user_password'] = 'md5 digest of secret'`を設定していた場合、`gitlab_rails['db_password']`と`geo_secondary['db_password']`にはプレーンテキストパスワードが含まれていることに注意してください。これらの設定は、Railsノードがデータベースに接続できるようにするために使用されます。

このノード上のRailsがPostgreSQLに接続できるように、現在のノードのIPがリードレプリカのデータベースの`postgresql['md5_auth_cidr_addresses']`設定にリストされていることを確認してください。

これらの変更を行った後、変更を有効にするために[GitLabを再設定](../../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

[アーキテクチャの概要](#architecture-overview)トポロジーでは、以下のGitLabサービスが「フロントエンド」ノードで有効になっています:

- `geo-logcursor`
- `gitlab-pages`
- `gitlab-workhorse`
- `logrotate`
- `nginx`
- `registry`
- `remote-syslog`
- `sidekiq`
- `puma`

フロントエンドアプリケーションノードで`sudo gitlab-ctl status`を実行して、これらのサービスが存在することを確認します。

### ステップ5: Geo **セカンダリ**サイトのロードバランサーをセットアップする {#step-5-set-up-the-loadbalancer-for-the-geo-secondary-site}

最小限の[アーキテクチャ図](#architecture-overview)は、各地理的場所にアプリケーションノードへトラフィックをルーティングするためのロードバランサーがあることを示しています。

詳細については、[複数ノードを持つGitLab用のロードバランサー](../../load_balancer.md)を参照してください。

### ステップ6: Geo **セカンダリ**サイトでバックエンドアプリケーションノードを設定する {#step-6-configure-the-backend-application-nodes-on-the-geo-secondary-site}

最小限の[アーキテクチャ図](#architecture-overview)は、すべてのアプリケーションサービスが同じマシンでまとめて実行されていることを示しています。ただし、複数のノードの場合、すべてのサービスを個別に実行することを[強くお勧め](../../reference_architectures/_index.md)します。

たとえば、Sidekiqノードは、`sidekiq`サービスのみを実行するようにいくつかの変更を加えて、以前にドキュメント化されたフロントエンドアプリケーションノードと同様に設定できます:

1. Geo **セカンダリ**サイトの各Sidekiqノードで`/etc/gitlab/gitlab.rb`を編集し、以下を追加します:

   ```ruby
   ##
   ## Enable the Sidekiq service
   ##
   sidekiq['enable'] = true
   gitlab_rails['enable'] = true

   ##
   ## The unique identifier for the Geo site. See
   ## https://docs.gitlab.com/administration/geo_sites/#common-settings
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

   同様に、`geo_logcursor['enable'] = true`を使用して`geo-logcursor`サービスのみを実行するようにノードを設定し、`sidekiq['enable'] = false`でSidekiqを無効にできます。

   これらのノードはロードバランサーにアタッチする必要はありません。

### ステップ7: シークレットをコピーし、アプリケーションにセカンダリサイトを追加する {#step-7-copy-secrets-and-add-the-secondary-site-in-the-application}

1. [GitLabを設定](configuration.md)して、**プライマリ**サイトと**セカンダリ**サイトを設定します。
