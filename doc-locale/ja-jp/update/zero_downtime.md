---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ダウンタイムなしでマルチノードインスタンスをアップグレードする
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

ゼロダウンタイムでマルチノードのGitLab環境をアップグレードするプロセスでは、[アップグレードの順序](#upgrade-order)に従って、各ノードを順番に処理します。ロードバランサーとHAメカニズムにより、各ノードの停止が適切に処理されます。

ゼロダウンタイムでのアップグレードを開始する前に、[ダウンタイムのオプションを検討](downtime_options.md)してください。

## はじめに {#before-you-start}

アップグレードの一環としてゼロダウンタイムを達成することは、分散アプリケーションにとっては特に困難です。このドキュメントは、HAの[参照アーキテクチャ](../administration/reference_architectures/_index.md)に対して提供されているとおりにテストされており、事実上、観測可能なダウンタイムは発生しませんでした。ただし、実際の結果は、特定のシステム構成によって異なる可能性があることに注意してください。

さらに信頼性を高めるために、特定のロードバランサーまたはインフラストラクチャ機能を使用してノードを手動でドレインするなど、高度な手法で成功を収めているお客様もいます。これらの手法は、基盤となるインフラストラクチャの機能に大きく依存します。

詳細については、GitLabの担当者または[サポートチーム](https://about.gitlab.com/support/)にお問い合わせください。

### 要件 {#requirements}

ゼロダウンタイムアップグレードプロセスには、ロードバランシングと、次のように設定された利用可能なHAメカニズムを備えたLinuxパッケージで構築されたマルチノードのGitLab環境が必要です:

- [ヘルスチェック](../administration/monitoring/health_check.md#readiness)（`/-/readiness`）エンドポイントに対して有効になっているヘルスチェックを使用して、GitLabアプリケーションノード用に構成された外部ロードバランサー。
- TCPヘルスチェックが有効になっているPgBouncerおよびPraefectコンポーネント用に構成された内部ロードバランサー。
- 存在する場合は、Consul、Postgres、およびRedisコンポーネント用に構成されたHAメカニズム。
  - HA方式でデプロイされていないこれらのコンポーネントは、ダウンタイムを伴って個別にアップグレードする必要があります。
  - データベースの場合、[Linuxパッケージは、メインのGitLab PostgreSQLデータベースでのみHAをサポートします。](https://gitlab.com/groups/gitlab-org/-/epics/7814)その他のデータベース（[Praefectデータベース](#upgrade-gitaly-cluster-praefect-nodes)など）の場合、HAを実現し、結果としてダウンタイムを回避するには、サードパーティのデータベースソリューションが必要です。

ゼロダウンタイムアップグレードを行うには、以下が必要です:

- **一度に1つのマイナーリリースを**アップグレードします。そのため、`16.1`から`16.2`へはアップグレードできますが、`16.3`へはアップグレードできません。リリースをスキップすると、データベースの変更が間違った順序で実行され、[データベーススキーマが破損した状態になる可能性](https://gitlab.com/gitlab-org/gitlab/-/issues/321542)があります。
- post-deployment移行を使用してください。

### 考慮事項 {#considerations}

ゼロダウンタイムアップグレードを検討する場合は、次の点に注意してください:

- ほとんどの場合、パッチリリースが最新でない場合は、パッチリリースから次のマイナーリリースに安全にアップグレードできます。たとえば、`16.3.2`から`16.4.1`へのアップグレードは、`16.3.3`がリリースされている場合でも安全であるはずです。[アップグレードパス](upgrade_paths.md)に関連するバージョン固有のアップグレードノートを確認し、必要なアップグレード停止を認識しておく必要があります:
  - [GitLab 17アップグレードノート](versions/gitlab_17_changes.md)
  - [GitLab 16アップグレードノート](versions/gitlab_16_changes.md)
  - [GitLab 15アップグレードノート](versions/gitlab_15_changes.md)
- 一部のリリースには、バックグラウンド移行が含まれている場合があります。これらの移行は、Sidekiqによってバックグラウンドで実行され、多くの場合、データを移行するために使用されます。バックグラウンド移行は、毎月のリリースでのみ追加されます。
  - 特定のメジャーまたはマイナーリリースでは、一連のバックグラウンド移行を完了する必要がある場合があります。これにより（上記の条件が満たされている場合）ダウンタイムは不要になりますが、メジャーまたはマイナーリリースをアップグレードするたびに、バックグラウンド移行が完了するまで待つ必要があります。
  - これらの移行を完了するために必要な時間は、`background_migration`キュー内のジョブを処理できるSidekiqワーカーの数を増やすことで短縮できます。このキューのサイズを確認するには、[アップグレードする前にバックグラウンド移行を確認](background_migrations.md)してください。
- 正常な再読み込みメカニズムにより、[Gitaly](#upgrade-gitaly-nodes)のゼロダウンタイムアップグレードを実行できます。[Gitaly](#upgrade-gitaly-cluster-praefect-nodes)クラスター（Praefect）コンポーネントも、ダウンタイムなしで直接アップグレードできます。ただし、Linuxパッケージは、PraefectデータベースのHAまたはゼロダウンタイムサポートを提供していません。ダウンタイムを回避するには、サードパーティのデータベースソリューションが必要です。
- [PostgreSQLのメジャーバージョンのアップグレード](../administration/postgresql/replication_and_failover.md#near-zero-downtime-upgrade-of-postgresql-in-a-patroni-cluster)は別のプロセスであり、ゼロダウンタイムアップグレードの対象ではありません。小規模なアップグレードは対象となります。
- ゼロダウンタイムアップグレードは、Linuxパッケージでデプロイした、注記されているGitLabコンポーネントでサポートされています。AWS Amazon Relational Database ServiceのPostgreSQLやGCP MemorystoreのRedisなど、サポートされているサードパーティサービスを介して特定のコンポーネントをデプロイしている場合は、それらのサービスのアップグレードを標準プロセスに従って個別に行う必要があります。
- 一般的なガイドラインとして、データの量が多いほど、アップグレードの完了に必要な時間が長くなります。テストでは、10 GB未満のデータベースは通常1時間以上かかることはありませんが、結果は異なる場合があります。

### アップグレードの順序 {#upgrade-order}

ゼロダウンタイムでアップグレードするコンポーネントの順序については、奥から手前に向かうアプローチを採用する必要があります:

1. ステートフルバックエンド
1. バックエンドの依存
1. フロントエンド

デプロイの順序は変更できますが、GitLabアプリケーションコード（RailsやSidekiqなど）を実行するコンポーネントはまとめてデプロイする必要があります。可能であれば、メジャーリリースのバージョンアップグレードで導入された変更に対する依存関係がないため、サポートインフラストラクチャを個別にアップグレードしてください。

次の順序でGitLabコンポーネントをアップグレードする必要があります:

1. Consul
1. PostgreSQL
1. PgBouncer
1. Redis
1. Gitaly
1. Praefect
1. Rails
1. Sidekiq

## Consul、PostgreSQLデータベース、PgBouncer、およびRedisノードのアップグレード {#upgrade-consul-postgresql-pgbouncer-and-redis-nodes}

[Consul](../administration/consul.md) 、[PostgreSQLデータベース](../administration/postgresql/replication_and_failover.md) 、[PgBouncer](../administration/postgresql/pgbouncer.md) 、および[Redis](../administration/redis/replication_and_failover.md)コンポーネントはすべて、ダウンタイムなしでアップグレードするための同じ基盤となるプロセスに従います。

アップグレードを実行する各コンポーネントのノードで:

1. `/etc/gitlab/skip-auto-reconfigure`に空のファイルを作成します。これにより、`gitlab-ctl reconfigure`の実行によるアップグレードが防止されます。デフォルトでは、GitLabが自動的に停止し、すべてのデータベース移行が実行され、GitLabが再起動されます:

   ```shell
   sudo touch /etc/gitlab/skip-auto-reconfigure
   ```

1. [GitLabパッケージをアップグレード](package/_index.md)します。
1. 再構成して再起動し、最新のコードを配置します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

   {{< tabs >}}

   {{< tab title="PostgreSQLデータベースノードのみ" >}}

   最初にConsulクライアントを再起動し、次に他のすべてのサービスを再起動して、PostgreSQLデータベースのフェイルオーバーが正常に行われるようにします:

   ```shell
   sudo gitlab-ctl restart consul
   sudo gitlab-ctl restart-except consul
   ```

   {{< /tab >}}

   {{< tab title="他のすべてのコンポーネントノード" >}}

   ```shell
   sudo gitlab-ctl restart
   ```

   {{< /tab >}}

   {{< /tabs >}}

## Gitalyノードのアップグレード {#upgrade-gitaly-nodes}

[Gitaly](../administration/gitaly/_index.md)は、アップグレードに関しては同じコアプロセスに従いますが、Gitalyプロセス自体は、可能な限り早く正常に再読み込みするための組み込みプロセスがあるため、再起動されないという重要な違いがあります。他のコンポーネントは引き続き再起動する必要があります。

{{< alert type="note" >}}

アップグレードプロセスは、新しいGitalyプロセスへの正常な引き渡しを試みます。アップグレード前に開始された既存の長時間実行されているGitリクエストは、この引き渡しが発生すると最終的にドロップされる可能性があります。将来的には、この機能が変更される可能性があります。詳細については、[このEpicを参照](https://gitlab.com/groups/gitlab-org/-/epics/10328)してください。

{{< /alert >}}

このプロセスは、Gitalyシャーディングおよびクラスターセットアップの両方に適用されます。アップグレードを実行するには、各Gitalyノードで次の手順を順番に実行します:

1. `/etc/gitlab/skip-auto-reconfigure`に空のファイルを作成します。これにより、`gitlab-ctl reconfigure`の実行によるアップグレードが防止されます。デフォルトでは、GitLabが自動的に停止し、すべてのデータベース移行が実行され、GitLabが再起動されます:

   ```shell
   sudo touch /etc/gitlab/skip-auto-reconfigure
   ```

1. [GitLabパッケージをアップグレード](package/_index.md)します。
1. 最新のコードを配置し、Gitalyに次の機会に正常に再読み込みするように指示するには、`reconfigure`コマンドを実行します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. 最後に、Gitalyはデプロイされている他のコンポーネントを正常に再読み込みしますが、再起動は依然として必要です:

   ```shell
   # Get a list of what other components have been deployed beside Gitaly
   sudo gitlab-ctl status

   # Restart each component except Gitaly. Example given for Consul, Node Exporter and Logrotate
   sudo gitlab-ctl restart consul node-exporter logrotate
   ```

### Gitalyクラスター（Praefect）ノードのアップグレード {#upgrade-gitaly-cluster-praefect-nodes}

Gitalyクラスター（Praefect）セットアップの場合、正常な再読み込みを使用して、同様の方法でPraefectをデプロイおよびアップグレードする必要があります。

{{< alert type="note" >}}

アップグレードプロセスは、新しいPraefectプロセスへの正常な引き渡しを試みます。アップグレード前に開始された既存の長時間実行されているGitリクエストは、この引き渡しが発生すると最終的にドロップされる可能性があります。将来的には、この機能が変更される可能性があります。詳細については、[このEpicを参照](https://gitlab.com/groups/gitlab-org/-/epics/10328)してください。

{{< /alert >}}

{{< alert type="note" >}}

このセクションでは、Praefectコンポーネントのみに焦点を当てており、[必須のPostgreSQLデータベース](../administration/gitaly/praefect/configure.md#postgresql)には焦点を当てていません。[GitLab LinuxパッケージはHAを提供していません](https://gitlab.com/groups/gitlab-org/-/epics/7814)。したがって、Praefectデータベースのゼロダウンタイムサポートも提供していません。ダウンタイムを回避するには、サードパーティのデータベースソリューションが必要です。

{{< /alert >}}

Praefectは、既存のデータをアップグレードするためにデータベース移行も実行する必要があります。競合を避けるために、移行は1つのPraefectノードでのみ実行する必要があります。これを行うには、移行を実行する特定のノードをデプロイノードとして指定します。これは、以下の手順で**Praefectデプロイノード**と呼ばれます:

1. **Praefectデプロイノードで**:

   1. `/etc/gitlab/skip-auto-reconfigure`に空のファイルを作成します。これにより、`gitlab-ctl reconfigure`の実行によるアップグレードが防止されます。デフォルトでは、GitLabが自動的に停止し、すべてのデータベース移行が実行され、GitLabが再起動されます:

      ```shell
      sudo touch /etc/gitlab/skip-auto-reconfigure
      ```

   1. [GitLabパッケージをアップグレード](package/_index.md)します。

   1. `praefect['auto_migrate'] = true`が`/etc/gitlab/gitlab.rb`で設定されていることを確認して、データベース移行が実行されるようにします。

   1. `reconfigure`コマンドを実行して、最新のコードを配置し、Praefectデータベース移行を適用して正常に再起動します:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

1. すべて**残りのPraefectノード**:

   1. `/etc/gitlab/skip-auto-reconfigure`に空のファイルを作成します。これにより、`gitlab-ctl reconfigure`の実行によるアップグレードが防止されます。デフォルトでは、GitLabが自動的に停止し、すべてのデータベース移行が実行され、GitLabが再起動されます:

      ```shell
      sudo touch /etc/gitlab/skip-auto-reconfigure
      ```

   1. [GitLabパッケージをアップグレード](package/_index.md)します。

   1. `reconfigure`がデータベース移行を自動的に実行しないようにするには、`praefect['auto_migrate'] = false`が`/etc/gitlab/gitlab.rb`で設定されていることを確認してください。

   1. `reconfigure`コマンドを実行して、最新のコードを配置し、正常に再起動します:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

1. 最後に、Praefectは正常に再読み込みされますが、デプロイされている他のコンポーネントは引き続き再起動が必要です。すべての**Praefectノード**:

   ```shell
   # Get a list of what other components have been deployed beside Praefect
   sudo gitlab-ctl status

   # Restart each component except Praefect. Example given for Consul, Node Exporter and Logrotate
   sudo gitlab-ctl restart consul node-exporter logrotate
   ```

## GitLabアプリケーション（Rails）ノードのアップグレード {#upgrade-gitlab-application-rails-nodes}

WebサーバーとしてのRailsは、主に[Puma](../administration/operations/puma.md)、Workhorse、およびNGINXで構成されています。

これらの各コンポーネントには、ライブアップグレードの実行に関して異なる動作があります。Pumaは正常な再読み込みを許可できますが、Workhorseは許可しません。最良のアプローチは、ロードバランサーを使用するなど、他の手段でノードを正常にドレインすることです。また、正常なシャットダウン機能を使用して、ノードでNGINXを使用することによってこれを行うこともできます。このセクションでは、NGINXアプローチについて説明します。

上記の他に、Railsはメインデータベース移行を実行する必要がある場所です。Praefectと同様に、最良のアプローチはデプロイノードを使用することです。PgBouncerが現在使用されている場合は、データベース移行の実行を試みるときに、Railsがアドバイザリロックを使用するため、これも回避する必要があります。これにより、同じデータベースで同時移行が実行されるのを防ぎます。これらのロックはトランザクション間で共有されないため、トランザクションプールモードでPgBouncerを使用してデータベース移行を実行すると、`ActiveRecord::ConcurrentMigrationError`やその他の問題が発生します。

1. **Railsデプロイノード**の場合:

   1. トラフィックのノードを正常にドレインします。これはさまざまな方法で実行できますが、1つのアプローチは、`QUIT`シグナルを送信してサービスを停止することにより、NGINXを使用することです。例として、次のシェルスクリプトを使用してこれを行うことができます:

      ```shell
      # Send QUIT to NGINX master process to drain and exit
      NGINX_PID=$(cat /var/opt/gitlab/nginx/nginx.pid)
      kill -QUIT $NGINX_PID

      # Wait for drain to complete
      while kill -0 $NGINX_PID 2>/dev/null; do sleep 1; done

      # Stop NGINX service to prevent automatic restarts
      gitlab-ctl stop nginx
      ```

   1. `/etc/gitlab/skip-auto-reconfigure`に空のファイルを作成します。これにより、`gitlab-ctl reconfigure`の実行によるアップグレードが防止されます。デフォルトでは、GitLabが自動的に停止し、すべてのデータベース移行が実行され、GitLabが再起動されます:

      ```shell
      sudo touch /etc/gitlab/skip-auto-reconfigure
      ```

   1. [GitLabパッケージをアップグレード](package/_index.md)します。

   1. `/etc/gitlab/gitlab.rb`設定ファイルで`gitlab_rails['auto_migrate'] = true`を設定することにより、通常の移行が実行されるように構成します。
      - デプロイノードが現在PgBouncerを介してデータベースに接続している場合は、[回避し](../administration/postgresql/pgbouncer.md#procedure-for-bypassing-pgbouncer)、移行を実行する前にデータベースリーダーに直接接続する必要があります。
      - データベースリーダーを見つけるには、任意のデータベースノードで次のコマンドを実行します - `sudo gitlab-ctl patroni members`。

   1. 通常の移行を実行し、最新のコードを配置します:

      ```shell
      sudo SKIP_POST_DEPLOYMENT_MIGRATIONS=true gitlab-ctl reconfigure
      ```

   1. 後でデプロイ後の移行を実行するために戻ってくるので、このノードは現状のままにしておきます。

1. すべての**他のRailsノード**で順番に:

   1. トラフィックのノードを正常にドレインします。これはさまざまな方法で実行できますが、1つのアプローチは、`QUIT`シグナルを送信してサービスを停止することにより、NGINXを使用することです。例として、次のシェルスクリプトを使用してこれを行うことができます:

      ```shell
      # Send QUIT to NGINX master process to drain and exit
      NGINX_PID=$(cat /var/opt/gitlab/nginx/nginx.pid)
      kill -QUIT $NGINX_PID

      # Wait for drain to complete
      while kill -0 $NGINX_PID 2>/dev/null; do sleep 1; done

      # Stop NGINX service to prevent automatic restarts
      gitlab-ctl stop nginx
      ```

   1. `/etc/gitlab/skip-auto-reconfigure`に空のファイルを作成します。これにより、`gitlab-ctl reconfigure`の実行によるアップグレードが防止されます。デフォルトでは、GitLabが自動的に停止し、すべてのデータベース移行が実行され、GitLabが再起動されます:

      ```shell
      sudo touch /etc/gitlab/skip-auto-reconfigure
      ```

   1. [GitLabパッケージをアップグレード](package/_index.md)します。

   1. `reconfigure`がデータベース移行を自動的に実行しないようにするには、`gitlab_rails['auto_migrate'] = false`が`/etc/gitlab/gitlab.rb`で設定されていることを確認してください。

   1. `reconfigure`コマンドを実行して、最新のコードを配置し、再起動します:

      ```shell
      sudo gitlab-ctl reconfigure
      sudo gitlab-ctl restart
      ```

1. **Railsデプロイノード**で、デプロイ後の移行を実行します:

   1. デプロイノードがデータベースリーダーを直接指していることを確認します。ノードが現在PgBouncerを介してデータベースに接続している場合は、[回避し](../administration/postgresql/pgbouncer.md#procedure-for-bypassing-pgbouncer)、移行を実行する前にデータベースリーダーに直接接続する必要があります。
      - データベースリーダーを見つけるには、任意のデータベースノードで次のコマンドを実行します - `sudo gitlab-ctl patroni members`。

   1. post-deployment移行を実行します:

      ```shell
      sudo gitlab-rake gitlab:db:configure
      ```

      このタスクは、ClickHouse移行も実行し、スキーマを読み込むことで、その状態に基づいてデータベースを構成します。

   1. `/etc/gitlab/gitlab.rb`設定ファイルで`gitlab_rails['auto_migrate'] = false`を設定することにより、構成を通常に戻します。
      - PgBouncerを使用している場合は、データベース構成が再びそれを指すように設定してください

   1. 再構成をもう一度実行して、通常の構成を再適用し、再起動します:

      ```shell
      sudo gitlab-ctl reconfigure
      sudo gitlab-ctl restart
      ```

## Sidekiqノードのアップグレード {#upgrade-sidekiq-nodes}

[Sidekiq](../administration/sidekiq/_index.md)は、ダウンタイムなしでアップグレードするために、他のプロセスと同じ基盤となるプロセスに従います。

アップグレードを実行するには、各コンポーネントノードで次の手順を順番に実行します:

1. `/etc/gitlab/skip-auto-reconfigure`に空のファイルを作成します。これにより、`gitlab-ctl reconfigure`の実行によるアップグレードが防止されます。デフォルトでは、GitLabが自動的に停止し、すべてのデータベース移行が実行され、GitLabが再起動されます:

   ```shell
   sudo touch /etc/gitlab/skip-auto-reconfigure
   ```

1. [GitLabパッケージをアップグレード](package/_index.md)します。

1. `reconfigure`コマンドを実行して、最新のコードを配置し、再起動します:

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl restart
   ```

## マルチノードGeoインスタンスのアップグレード {#upgrade-multi-node-geo-instances}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このセクションでは、GeoでライブGitLab環境デプロイをアップグレードするために必要な手順について説明します。

全体として、このアプローチは通常のプロセスとほぼ同じですが、セカンダリサイトごとに追加の手順が必要です。必要な順序は、最初にプライマリをアップグレードし、次にセカンダリをアップグレードすることです。すべてのセカンダリが更新されたら、プライマリでデプロイ後の移行も実行する必要があります。

{{< alert type="note" >}}

[要件](#requirements)と[考慮事項](#considerations)は、GeoでライブGitLab環境をアップグレードする場合にも適用されます。

{{< /alert >}}

### プライマリサイト {#primary-site}

プライマリサイトのアップグレードプロセスは、セカンダリがすべて更新されるまで、デプロイ後の移行を実行しないことを除き、通常のプロセスと同じです。

説明されているプライマリサイトと同じ手順を実行しますが、デプロイ後の移行の実行のRailsノードの手順で停止します。

### セカンダリサイト {#secondary-sites}

セカンダリサイトのアップグレードプロセスは、Railsノードを除き、通常のプロセスと同じ手順に従います。アップグレードプロセスは、プライマリサイトとセカンダリサイトの両方で同じです。ただし、セカンダリサイトのRailsノードに対して、次の追加手順を実行する必要があります。

#### Rails {#rails}

1. **Railsデプロイノード**の場合:

   1. トラフィックのノードを正常にドレインします。これはさまざまな方法で実行できますが、1つのアプローチは、`QUIT`シグナルを送信してサービスを停止することにより、NGINXを使用することです。例として、次のシェルスクリプトを使用してこれを行うことができます:

      ```shell
      # Send QUIT to NGINX master process to drain and exit
      NGINX_PID=$(cat /var/opt/gitlab/nginx/nginx.pid)
      kill -QUIT $NGINX_PID

      # Wait for drain to complete
      while kill -0 $NGINX_PID 2>/dev/null; do sleep 1; done

      # Stop NGINX service to prevent automatic restarts
      gitlab-ctl stop nginx
      ```

   1. Geo Log Cursorプロセスを停止して、別のノードへのフェイルオーバーを確実にします:

      ```shell
      gitlab-ctl stop geo-logcursor
      ```

   1. `/etc/gitlab/skip-auto-reconfigure`に空のファイルを作成します。これにより、`gitlab-ctl reconfigure`の実行によるアップグレードが防止されます。デフォルトでは、GitLabが自動的に停止し、すべてのデータベース移行が実行され、GitLabが再起動されます:

      ```shell
      sudo touch /etc/gitlab/skip-auto-reconfigure
      ```

   1. [GitLabパッケージをアップグレード](package/_index.md)します。

   1. プライマリサイトのRailsノードから`/etc/gitlab/gitlab-secrets.json`ファイルをセカンダリサイトのRailsノードにコピーします（異なる場合）。ファイルは、サイトのすべてのノードで同じである必要があります。

   1. `/etc/gitlab/gitlab.rb`設定ファイルで、`gitlab_rails['auto_migrate'] = false`と`geo_secondary['auto_migrate'] = false`を設定して、移行が自動的に実行されるように設定されていないことを確認します。

   1. `reconfigure`コマンドを実行して、最新のコードを配置し、再起動します:

      ```shell
      sudo gitlab-ctl reconfigure
      sudo gitlab-ctl restart
      ```

   1. 通常のGeo Tracking移行を実行し、最新のコードを配置します:

      ```shell
      sudo SKIP_POST_DEPLOYMENT_MIGRATIONS=true gitlab-rake db:migrate:geo
      ```

1. すべての**他のRailsノード**で順番に:

   1. トラフィックのノードを正常にドレインします。これはさまざまな方法で実行できますが、1つのアプローチは、`QUIT`シグナルを送信してサービスを停止することにより、NGINXを使用することです。例として、次のシェルスクリプトを使用してこれを行うことができます:

      ```shell
      # Send QUIT to NGINX master process to drain and exit
      NGINX_PID=$(cat /var/opt/gitlab/nginx/nginx.pid)
      kill -QUIT $NGINX_PID

      # Wait for drain to complete
      while kill -0 $NGINX_PID 2>/dev/null; do sleep 1; done

      # Stop NGINX service to prevent automatic restarts
      gitlab-ctl stop nginx
      ```

   1. Geo Log Cursorプロセスを停止して、別のノードへのフェイルオーバーを確実にします:

      ```shell
      gitlab-ctl stop geo-logcursor
      ```

   1. `/etc/gitlab/skip-auto-reconfigure`に空のファイルを作成します。これにより、`gitlab-ctl reconfigure`の実行によるアップグレードが防止されます。デフォルトでは、GitLabが自動的に停止し、すべてのデータベース移行が実行され、GitLabが再起動されます:

      ```shell
      sudo touch /etc/gitlab/skip-auto-reconfigure
      ```

   1. [GitLabパッケージをアップグレード](package/_index.md)します。

   1. `/etc/gitlab/gitlab.rb`設定ファイルで、`gitlab_rails['auto_migrate'] = false`と`geo_secondary['auto_migrate'] = false`を設定して、移行が自動的に実行されるように設定されていないことを確認します。

   1. `reconfigure`コマンドを実行して、最新のコードを配置し、再起動します:

      ```shell
      sudo gitlab-ctl reconfigure
      sudo gitlab-ctl restart
      ```

#### Sidekiq {#sidekiq}

メインプロセスに続いて、残りの作業はSidekiqのアップグレードです。

[メインセクションで説明されているのと同じ方法](#sidekiq)でSidekiqをアップグレードします。

### post-deployment移行 {#post-deployment-migrations}

最後に、プライマリサイトに戻り、デプロイ後の移行を実行してアップグレードを完了します:

1. プライマリサイトの**Railsデプロイノード**で、デプロイ後の移行を実行します:

   1. デプロイノードがデータベースリーダーを直接指していることを確認します。ノードが現在PgBouncerを介してデータベースに接続している場合は、[回避し](../administration/postgresql/pgbouncer.md#procedure-for-bypassing-pgbouncer)、移行を実行する前にデータベースリーダーに直接接続する必要があります。
      - データベースリーダーを見つけるには、任意のデータベースノードで次のコマンドを実行します - `sudo gitlab-ctl patroni members`。

   1. post-deployment移行を実行します:

      ```shell
      sudo gitlab-rake gitlab:db:configure
      ```

   1. Geo設定と依存関係を確認します

      ```shell
      sudo gitlab-rake gitlab:geo:check
      ```

   1. `/etc/gitlab/gitlab.rb`設定ファイルで`gitlab_rails['auto_migrate'] = false`を設定することにより、構成を通常に戻します。
      - PgBouncerを使用している場合は、データベース構成が再びそれを指すように設定してください

   1. 再構成をもう一度実行して、通常の構成を再適用し、再起動します:

      ```shell
      sudo gitlab-ctl reconfigure
      sudo gitlab-ctl restart
      ```

1. セカンダリサイトの**Railsデプロイノード**で、デプロイ後のGeo Tracking移行を実行します:

   1. デプロイ後のGeo Tracking移行を実行します:

      ```shell
      sudo gitlab-rake db:migrate:geo
      ```

   1. Geoステータスを確認します:

       ```shell
       sudo gitlab-rake geo:status
       ```
