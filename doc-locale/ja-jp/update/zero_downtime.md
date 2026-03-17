---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: ダウンタイムなしでマルチノードインスタンスをアップグレードする
description: ゼロダウンタイムでマルチノードのLinuxパッケージベースをアップグレードします。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

ゼロダウンタイムでGitLab環境のマルチノードをアップグレードするプロセスには、[アップグレード順序](#upgrade-order)に従って各ノードを順番に処理することが含まれます。ロードバランサーとHAメカニズムは、各ノードのダウンに適切に対応します。

ゼロダウンタイムでのアップグレードを開始する前に、[ダウンタイムのオプション](downtime_options.md)を検討してください。

## はじめに {#before-you-start}

アップグレードの一環としてゼロダウンタイムを実現することは、分散アプリケーションにとって非常に困難です。ドキュメントは、HA[リファレンスアーキテクチャ](../administration/reference_architectures/_index.md)に対してテストされており、実質的に観測可能なダウンタイムは発生しませんでした。ただし、システムの構成によっては結果が異なる場合があることに注意してください。

さらなる確実性のため、一部の顧客は、特定のロードバランサーやインフラストラクチャの機能を使用してノードを手動でドレインするなどの追加の技術で成功を収めています。これらの技術は、基盤となるインフラストラクチャの機能に大きく依存します。

追加情報については、GitLab担当者または[サポートチーム](https://about.gitlab.com/support/)にお問い合わせください。

### 要件 {#requirements}

ゼロダウンタイムアップグレードのプロセスには、ロードバランシングと、次のHAメカニズムが構成されたLinuxパッケージで構築されたマルチノードのGitLab環境が必要です:

- GitLabアプリケーションノード用に構成された外部ロードバランサーと、[readiness](../administration/monitoring/health_check.md#readiness) (`/-/readiness`) エンドポイントに対して有効化されたヘルスチェック。
- PgBouncerおよびPraefectコンポーネント用に構成された内部ロードバランサーと、有効化されたTCPヘルスチェック。
- 存在する場合は、Consul、Postgres、およびRedisコンポーネント用に構成されたHAメカニズム。
  - HA形式でデプロイされていないこれらのコンポーネントは、ダウンタイムを伴って個別にアップグレードする必要があります。
  - データベースの場合、[Linuxパッケージ](https://gitlab.com/groups/gitlab-org/-/epics/7814)はメインのGitLabデータベースでのみHAをサポートしています。[Praefectデータベース](#upgrade-gitaly-cluster-praefect-nodes)などの他のデータベースの場合、HAを実現し、その結果ダウンタイムを回避するには、サードパーティのデータベースソリューションが必要です。

ゼロダウンタイムアップグレードの場合、次のことを行う必要があります:

- **one minor release at a time**をアップグレードします。したがって、`16.1`から`16.2`へであり、`16.3`へではありません。リリースをスキップすると、データベースの変更が誤った順序で実行され、[データベースのスキーマが破損した状態になる](https://gitlab.com/gitlab-org/gitlab/-/issues/321542)可能性があります。
- デプロイ後移行を使用します。

### 考慮事項 {#considerations}

ダウンタイムなしのアップグレードを検討する場合は、以下に注意してください:

- 多くの場合、パッチリリースが最新でなくても、そのバージョンから次のマイナーリリースへは安全にアップグレードできます。たとえば、`16.3.3`がリリースされた場合でも、`16.3.2`から`16.4.1`へのアップグレードは安全です。関連する[バージョン固有のアップグレードノート](versions/_index.md)と[アップグレードパス](upgrade_paths.md)を確認し、必要なアップグレード停止に注意してください:

  - [GitLab 18アップグレードノート](versions/gitlab_18_changes.md)
  - [GitLab 17アップグレードノート](versions/gitlab_17_changes.md)
  - [GitLab 16アップグレードノート](versions/gitlab_16_changes.md)
  - [GitLab 15アップグレードノート](versions/gitlab_15_changes.md)
- 一部のリリースにはバックグラウンド移行が含まれる場合があります。これらの移行はSidekiqによってバックグラウンドで実行され、多くの場合データの移行に使用されます。バックグラウンド移行は月次リリースでのみ追加されます。
  - 特定のメジャーリリースまたはマイナーリリースでは、一連のバックグラウンド移行を完了する必要がある場合があります。これにはダウンタイムは必要ありませんが（以前の条件が満たされている場合）、メジャーリリースまたはマイナーリリースのアップグレードごとに、バックグラウンド移行が完了するのを待つ必要があります。
  - これらの移行を完了するために必要な時間は、`background_migration`キューでジョブを処理できるSidekiqワーカーの数を増やすことで短縮できます。このキューのサイズを確認するには、[アップグレードする前にバックグラウンド移行を確認](background_migrations.md)してください。
- ゼロダウンタイムアップグレードは、正常なリロードメカニズムにより[Gitaly](#upgrade-gitaly-nodes)に対して実行できます。[Gitalyクラスター (Praefect)](#upgrade-gitaly-cluster-praefect-nodes)コンポーネントも、ダウンタイムなしで直接アップグレードできます。ただし、LinuxパッケージはPraefectデータベースに対するHAまたはゼロダウンタイムサポートを提供していません。ダウンタイムを回避するには、サードパーティのデータベースソリューションが必要です。
- [PostgreSQL](../administration/postgresql/replication_and_failover.md#near-zero-downtime-upgrade-of-postgresql-in-a-patroni-cluster)メジャーバージョンアップグレードは別のプロセスであり、ゼロダウンタイムアップグレードではカバーされません。小規模なアップグレードはカバーされます。
- ゼロダウンタイムアップグレードは、Linuxパッケージでデプロイした指定のGitLabコンポーネントでサポートされています。AWS RDSのPostgreSQLやGCP MemorystoreのRedisなど、サポートされているサードパーティサービスを通じて選択したコンポーネントをデプロイしている場合、それらのサービスのアップグレードは、標準プロセスに従って個別に実行する必要があります。
- 一般的なガイドラインとして、データ量が多ければ多いほど、アップグレードの完了にはより多くの時間が必要です。テストでは、10 GB未満のデータベースは通常1時間以上かかることはありませんが、環境によっては異なる場合があります。

### アップグレード順序 {#upgrade-order}

ゼロダウンタイムでアップグレードするコンポーネントの順序については、バックトゥフロントのアプローチを取る必要があります:

1. ステートフルバックエンド
1. バックエンドの依存ノード
1. フロントエンド

デプロイの順序を変更することはできますが、GitLabアプリケーションコード（たとえば、RailsやSidekiq）を実行しているコンポーネントは一緒にデプロイする必要があります。可能であれば、これらのコンポーネントはメジャーリリースのバージョンアップグレードで導入された変更に依存しないため、サポートインフラストラクチャを個別にアップグレードしてください。

GitLabコンポーネントは、次の順序でアップグレードする必要があります:

1. Consul
1. PostgreSQL
1. PgBouncer
1. Redis
1. Gitaly
1. Praefect
1. Rails
1. Sidekiq

## Consul、PostgreSQL、PgBouncer、およびRedisノードをアップグレードする {#upgrade-consul-postgresql-pgbouncer-and-redis-nodes}

[Consul](../administration/consul.md) 、[PostgreSQL](../administration/postgresql/replication_and_failover.md) 、[PgBouncer](../administration/postgresql/pgbouncer.md) 、および[Redis](../administration/redis/replication_and_failover.md)のコンポーネントはすべて、ダウンタイムなしでアップグレードするための同じ基本プロセスに従います。

アップグレードを実行するには、各コンポーネントのノードで次のようにします:

1. `/etc/gitlab/skip-auto-reconfigure`に空のファイルを作成します。これにより、アップグレードによって`gitlab-ctl reconfigure`が実行されるのを防ぎます。これは、デフォルトでGitLabを自動的に停止し、すべてのデータベース移行を実行し、GitLabを再起動します:

   ```shell
   sudo touch /etc/gitlab/skip-auto-reconfigure
   ```

1. [Linuxパッケージ](package/_index.md#upgrade-with-the-linux-package)でアップグレードしてノードをアップグレードします。
1. 最新のコードを適用するために再構成して再起動します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

   {{< tabs >}}

   {{< tab title="PostgreSQLノードのみ" >}}

   Consulクライアントを最初に再起動し、次に他のすべてのサービスを再起動して、PostgreSQLのフェイルオーバーが正常に発生するようにします:

   ```shell
   sudo gitlab-ctl restart consul
   sudo gitlab-ctl restart-except consul
   ```

   {{< /tab >}}

   {{< tab title="その他のすべてのコンポーネントノード" >}}

   ```shell
   sudo gitlab-ctl restart
   ```

   {{< /tab >}}

   {{< /tabs >}}

## Gitalyノードをアップグレードする {#upgrade-gitaly-nodes}

[Gitaly](../administration/gitaly/_index.md)は、アップグレードに関して同じコアプロセスに従いますが、Gitalyプロセス自体は再起動されないという重要な違いがあります。これは、最も早い機会に正常にリロードするための組み込みプロセスがあるためです。その他のコンポーネントは依然として再起動する必要があります。

このプロセスは、Gitalyシャード化設定とクラスター設定の両方に適用されます。各Gitalyノードで次の手順を順番に実行してアップグレードを実行します:

1. `/etc/gitlab/skip-auto-reconfigure`に空のファイルを作成します。これにより、アップグレードによって`gitlab-ctl reconfigure`が実行されるのを防ぎます。これは、デフォルトでGitLabを自動的に停止し、すべてのデータベース移行を実行し、GitLabを再起動します:

   ```shell
   sudo touch /etc/gitlab/skip-auto-reconfigure
   ```

1. [Linuxパッケージ](package/_index.md#upgrade-with-the-linux-package)でアップグレードしてノードをアップグレードします。
1. `reconfigure`コマンドを実行して最新のコードを適用し、Gitalyに次の機会に正常にリロードするように指示します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. 最後に、Gitalyが正常にリロードされている間も、デプロイされた他のコンポーネントは再起動が必要です:

   ```shell
   # Get a list of what other components have been deployed beside Gitaly
   sudo gitlab-ctl status

   # Restart each component except Gitaly. Example given for Consul, Node Exporter and Logrotate
   sudo gitlab-ctl restart consul node-exporter logrotate
   ```

### Gitalyクラスター (Praefect) ノードをアップグレードする {#upgrade-gitaly-cluster-praefect-nodes}

> [!note]このセクションは、Praefectコンポーネントのみに焦点を当てており、[必要なPostgreSQLデータベース](../administration/gitaly/praefect/configure.md#postgresql)ではありません。[GitLab](https://gitlab.com/groups/gitlab-org/-/epics/7814) Linuxパッケージは、Praefectデータベースに対するHAおよびゼロダウンタイムサポートを提供していません。ダウンタイムを回避するには、サードパーティのデータベースソリューションが必要です。

Gitalyクラスター (Praefect) の設定では、正常なリロードを使用して、同様の方法でPraefectをデプロイおよびアップグレードする必要があります。

> [!note]アップグレードプロセスは、新しいPraefectプロセスへの正常なハンドオーバーを試みます。アップグレード前に開始された既存の長時間のGitリクエストは、このハンドオーバーが発生すると最終的にドロップされる可能性があります。将来、この機能が変更される可能性があります。詳細については、[このエピック](https://gitlab.com/groups/gitlab-org/-/epics/10328)を参照してください。

Praefectは、既存のデータをアップグレードするためにデータベース移行も実行する必要があります。競合を避けるため、移行は1つのPraefectノードでのみ実行する必要があります。これを行うには、移行を実行する**Praefect deploy node**を指定します:

1. **Praefect deploy node**で:

   1. `/etc/gitlab/skip-auto-reconfigure`に空のファイルを作成します。これにより、アップグレードによって`gitlab-ctl reconfigure`が実行されるのを防ぎます。これは、デフォルトでGitLabを自動的に停止し、すべてのデータベース移行を実行し、GitLabを再起動します:

      ```shell
      sudo touch /etc/gitlab/skip-auto-reconfigure
      ```

   1. [Linuxパッケージ](package/_index.md#upgrade-with-the-linux-package)でアップグレードしてノードをアップグレードします。
   1. データベース移行が実行されるように、`/etc/gitlab/gitlab.rb`に`praefect['auto_migrate'] = true`が設定されていることを確認します。
   1. `reconfigure`コマンドを実行して最新のコードを適用し、Praefectデータベース移行を適用して正常に再起動します:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

1. すべての**remaining Praefect nodes**で:

   1. `/etc/gitlab/skip-auto-reconfigure`に空のファイルを作成します。これにより、アップグレードによって`gitlab-ctl reconfigure`が実行されるのを防ぎます。これは、デフォルトでGitLabを自動的に停止し、すべてのデータベース移行を実行し、GitLabを再起動します:

      ```shell
      sudo touch /etc/gitlab/skip-auto-reconfigure
      ```

   1. [Linuxパッケージ](package/_index.md#upgrade-with-the-linux-package)でアップグレードしてノードをアップグレードします。
   1. `reconfigure`によるデータベース移行の自動実行を防ぐために、`/etc/gitlab/gitlab.rb`に`praefect['auto_migrate'] = false`が設定されていることを確認します。
   1. `reconfigure`コマンドを実行して最新のコードを適用し、正常に再起動します:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

1. 最後に、Praefectが正常にリロードされている間も、デプロイされた他のコンポーネントは再起動が必要です。すべての**Praefect nodes**で:

   ```shell
   # Get a list of what other components have been deployed beside Praefect
   sudo gitlab-ctl status

   # Restart each component except Praefect. Example given for Consul, Node Exporter and Logrotate
   sudo gitlab-ctl restart consul node-exporter logrotate
   ```

## GitLabアプリケーション (Rails) ノードをアップグレードする {#upgrade-gitlab-application-rails-nodes}

ウェブサーバーとしてのRailsは、主に[Puma](../administration/operations/puma.md)、Workhorse、およびNGINXで構成されています。

これらのコンポーネントはそれぞれ、ライブアップグレードを行う際に異なる動作をします。Pumaは正常なリロードを許可できますが、Workhorseは許可しません。最善のアプローチは、ロードバランサーを使用するなど、他の手段でノードのトラフィックを正常にドレインすることです。ノードでNGINXの正常シャットダウン機能を使用することでもこれを行うことができます。このセクションではNGINXのアプローチについて説明します。

上記に加えて、Railsは主要なデータベース移行を実行する必要がある場所です。Praefectと同様に、最善のアプローチはデプロイノードを使用することです。現在PgBouncerが使用されている場合、Railsは移行の実行を試みる際にアドバイザリロックを使用するため、同時に実行される移行が同じデータベースで実行されるのを防ぐために、これもバイパスする必要があります。これらのロックはトランザクション間で共有されず、トランザクションプールモードでPgBouncerを使用してデータベース移行を実行すると、`ActiveRecord::ConcurrentMigrationError`やその他の問題が発生します。

1. **Rails deploy node**で:

   1. ノードのトラフィックを正常にドレインします。これにはさまざまな方法がありますが、1つのアプローチは、NGINXに`QUIT`シグナルを送信し、サービスを停止することです。例として、次のシェルスクリプトを使用してこれを行うことができます:

      ```shell
      # Send QUIT to NGINX master process to drain and exit
      NGINX_PID=$(cat /var/opt/gitlab/nginx/nginx.pid)
      kill -QUIT $NGINX_PID

      # Wait for drain to complete
      while kill -0 $NGINX_PID 2>/dev/null; do sleep 1; done

      # Stop NGINX service to prevent automatic restarts
      gitlab-ctl stop nginx
      ```

   1. `/etc/gitlab/skip-auto-reconfigure`に空のファイルを作成します。これにより、アップグレードによって`gitlab-ctl reconfigure`が実行されるのを防ぎます。これは、デフォルトでGitLabを自動的に停止し、すべてのデータベース移行を実行し、GitLabを再起動します:

      ```shell
      sudo touch /etc/gitlab/skip-auto-reconfigure
      ```

   1. [Linuxパッケージ](package/_index.md#upgrade-with-the-linux-package)でアップグレードしてGitLabをアップグレードします。
   1. `/etc/gitlab/gitlab.rb`設定ファイルで`gitlab_rails['auto_migrate'] = true`を設定して、通常の移行が実行されるように構成します。
      - デプロイノードがPgBouncerを介してデータベースにアクセスする場合、移行を実行する前に[それをバイパス](../administration/postgresql/pgbouncer.md#procedure-for-bypassing-pgbouncer)してデータベースリーダーに直接接続する必要があります。
      - データベースリーダーを見つけるには、任意のデータベースノードで次のコマンドを実行できます。`sudo gitlab-ctl patroni members`

   1. 通常の移行を実行し、最新のコードを適用します:

      ```shell
      sudo SKIP_POST_DEPLOYMENT_MIGRATIONS=true gitlab-ctl reconfigure
      ```

   1. このノードは、後でデプロイ後移行を実行するためにそのままにしておきます。

1. すべての**other Rails node**で順番に:

   1. ノードのトラフィックを正常にドレインします。これにはさまざまな方法がありますが、1つのアプローチは、NGINXに`QUIT`シグナルを送信し、サービスを停止することです。例として、次のシェルスクリプトを使用してこれを行うことができます:

      ```shell
      # Send QUIT to NGINX master process to drain and exit
      NGINX_PID=$(cat /var/opt/gitlab/nginx/nginx.pid)
      kill -QUIT $NGINX_PID

      # Wait for drain to complete
      while kill -0 $NGINX_PID 2>/dev/null; do sleep 1; done

      # Stop NGINX service to prevent automatic restarts
      gitlab-ctl stop nginx
      ```

   1. `/etc/gitlab/skip-auto-reconfigure`に空のファイルを作成します。これにより、アップグレードによって`gitlab-ctl reconfigure`が実行されるのを防ぎます。これは、デフォルトでGitLabを自動的に停止し、すべてのデータベース移行を実行し、GitLabを再起動します:

      ```shell
      sudo touch /etc/gitlab/skip-auto-reconfigure
      ```

   1. [Linuxパッケージ](package/_index.md#upgrade-with-the-linux-package)でアップグレードしてGitLabをアップグレードします。
   1. `reconfigure`によるデータベース移行の自動実行を防ぐために、`/etc/gitlab/gitlab.rb`に`gitlab_rails['auto_migrate'] = false`が設定されていることを確認します。
   1. `reconfigure`コマンドを実行して最新のコードを適用し、再起動します:

      ```shell
      sudo gitlab-ctl reconfigure
      sudo gitlab-ctl restart
      ```

1. **Rails deploy node**でデプロイ後移行を実行します:

   1. デプロイノードが引き続きデータベースリーダーに直接ポイントしていることを確認します。ノードがPgBouncerを介してデータベースにアクセスする場合、移行を実行する前に[それをバイパス](../administration/postgresql/pgbouncer.md#procedure-for-bypassing-pgbouncer)してデータベースリーダーに直接接続する必要があります。
      - データベースリーダーを見つけるには、任意のデータベースノードで次のコマンドを実行できます。`sudo gitlab-ctl patroni members`

   1. デプロイ後移行を実行します:

      ```shell
      sudo gitlab-rake gitlab:db:configure
      ```

      このタスクは、ClickHouse移行も実行し、スキーマを読み込むことによってその状態に基づいてデータベースを構成します。

   1. `/etc/gitlab/gitlab.rb`設定ファイルで`gitlab_rails['auto_migrate'] = false`を設定して、構成を通常に戻します。
      - PgBouncerを使用している場合は、データベース構成が再度それにポイントするように設定されていることを確認してください。

   1. 通常の構成を再適用するために、もう一度再構成を実行し、再起動します:

      ```shell
      sudo gitlab-ctl reconfigure
      sudo gitlab-ctl restart
      ```

## Sidekiqノードをアップグレードする {#upgrade-sidekiq-nodes}

[Sidekiq](../administration/sidekiq/_index.md)は、ダウンタイムなしでアップグレードするために他のコンポーネントと同じ基本プロセスに従います。

アップグレードを実行するには、各コンポーネントノードで次の手順を順番に実行します:

1. `/etc/gitlab/skip-auto-reconfigure`に空のファイルを作成します。これにより、アップグレードによって`gitlab-ctl reconfigure`が実行されるのを防ぎます。これは、デフォルトでGitLabを自動的に停止し、すべてのデータベース移行を実行し、GitLabを再起動します:

   ```shell
   sudo touch /etc/gitlab/skip-auto-reconfigure
   ```

1. [Linuxパッケージ](package/_index.md#upgrade-with-the-linux-package)でアップグレードしてノードをアップグレードします。
1. `reconfigure`コマンドを実行して最新のコードを適用し、再起動します:

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl restart
   ```

## マルチノードGeoインスタンスをアップグレードする {#upgrade-multi-node-geo-instances}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

このセクションでは、GeoをデプロイしたライブGitLab環境をアップグレードするために必要な手順について説明します。

全体として、アプローチは通常のプロセスとほぼ同じですが、各セカンダリサイトに必要な追加の手順がいくつかあります。必要な順序は、プライマリを最初にアップグレードし、次にセカンダリをアップグレードすることです。また、すべてのセカンダリが更新された後、プライマリでデプロイ後の移行を実行する必要があります。

> [!note] GeoをデプロイしたライブGitLab環境のアップグレードには、同じ[要件](#requirements)と[考慮事項](#considerations)が適用されます。

### プライマリサイト {#primary-site}

プライマリサイトのアップグレードプロセスは通常のプロセスと同じですが、すべてのセカンダリが更新されるまでデプロイ後の移行を実行しないという例外が1つあります。

説明されているプライマリサイトと同じ手順を実行しますが、Railsノードのデプロイ後移行を実行する手順で停止します。

### セカンダリサイト {#secondary-sites}

すべてのセカンダリサイトのアップグレードプロセスは、Railsノードを除いて、通常のプロセスと同じ手順に従います。プライマリサイトとセカンダリサイトの両方でアップグレードプロセスは同じです。ただし、セカンダリサイトのRailsノードについては、次の追加手順を実行する必要があります。

#### Rails {#rails}

1. **Rails deploy node**で:

   1. ノードのトラフィックを正常にドレインします。これにはさまざまな方法がありますが、1つのアプローチは、NGINXに`QUIT`シグナルを送信し、サービスを停止することです。例として、次のシェルスクリプトを使用してこれを行うことができます:

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

   1. `/etc/gitlab/skip-auto-reconfigure`に空のファイルを作成します。これにより、アップグレードによって`gitlab-ctl reconfigure`が実行されるのを防ぎます。これは、デフォルトでGitLabを自動的に停止し、すべてのデータベース移行を実行し、GitLabを再起動します:

      ```shell
      sudo touch /etc/gitlab/skip-auto-reconfigure
      ```

   1. [Linuxパッケージ](package/_index.md#upgrade-with-the-linux-package)でアップグレードしてGitLabをアップグレードします。
   1. プライマリサイトのRailsノードとセカンダリサイトのRailsノードが異なる場合、`/etc/gitlab/gitlab-secrets.json`ファイルをコピーします。このファイルは、サイトのすべてのノードで同じでなければなりません。
   1. `/etc/gitlab/gitlab.rb`設定ファイルで`gitlab_rails['auto_migrate'] = false`および`geo_secondary['auto_migrate'] = false`を設定して、移行が自動的に実行されないようにします。
   1. `reconfigure`コマンドを実行して最新のコードを適用し、再起動します:

      ```shell
      sudo gitlab-ctl reconfigure
      sudo gitlab-ctl restart
      ```

   1. 通常のGeo追跡移行を実行し、最新のコードを適用します:

      ```shell
      sudo SKIP_POST_DEPLOYMENT_MIGRATIONS=true gitlab-rake db:migrate:geo
      ```

1. すべての**other Rails node**で順番に:

   1. ノードのトラフィックを正常にドレインします。これにはさまざまな方法がありますが、1つのアプローチは、NGINXに`QUIT`シグナルを送信し、サービスを停止することです。例として、次のシェルスクリプトを使用してこれを行うことができます:

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

   1. `/etc/gitlab/skip-auto-reconfigure`に空のファイルを作成します。これにより、アップグレードによって`gitlab-ctl reconfigure`が実行されるのを防ぎます。これは、デフォルトでGitLabを自動的に停止し、すべてのデータベース移行を実行し、GitLabを再起動します:

      ```shell
      sudo touch /etc/gitlab/skip-auto-reconfigure
      ```

   1. [Linuxパッケージ](package/_index.md#upgrade-with-the-linux-package)でアップグレードしてGitLabをアップグレードします。
   1. `/etc/gitlab/gitlab.rb`設定ファイルで`gitlab_rails['auto_migrate'] = false`および`geo_secondary['auto_migrate'] = false`を設定して、移行が自動的に実行されないようにします。
   1. `reconfigure`コマンドを実行して最新のコードを適用し、再起動します:

      ```shell
      sudo gitlab-ctl reconfigure
      sudo gitlab-ctl restart
      ```

#### Sidekiq {#sidekiq}

メインプロセスに従い、残りのタスクはSidekiqをアップグレードすることです。

メインセクションで説明されているのと[同じ方法](#sidekiq)でSidekiqをアップグレードします。

### デプロイ後移行 {#post-deployment-migrations}

最後に、プライマリサイトに戻り、デプロイ後移行を実行してアップグレードを完了します:

1. プライマリサイトの**Rails deploy node**でデプロイ後移行を実行します:

   1. デプロイノードが引き続きデータベースリーダーに直接ポイントしていることを確認します。ノードがPgBouncerを介してデータベースにアクセスする場合、移行を実行する前に[それをバイパス](../administration/postgresql/pgbouncer.md#procedure-for-bypassing-pgbouncer)してデータベースリーダーに直接接続する必要があります。
      - データベースリーダーを見つけるには、任意のデータベースノードで次のコマンドを実行できます。`sudo gitlab-ctl patroni members`

   1. デプロイ後移行を実行します:

      ```shell
      sudo gitlab-rake gitlab:db:configure
      ```

   1. Geo構成と依存関係を確認します。

      ```shell
      sudo gitlab-rake gitlab:geo:check
      ```

   1. `/etc/gitlab/gitlab.rb`設定ファイルで`gitlab_rails['auto_migrate'] = false`を設定して、構成を通常に戻します。
      - PgBouncerを使用している場合は、データベース構成が再度それにポイントするように設定されていることを確認してください。

   1. 通常の構成を再適用するために、もう一度再構成を実行し、再起動します:

      ```shell
      sudo gitlab-ctl reconfigure
      sudo gitlab-ctl restart
      ```

1. セカンダリサイトの**Rails deploy node**で、デプロイ後Geo追跡移行を実行します:

   1. デプロイ後Geo追跡移行を実行します:

      ```shell
      sudo gitlab-rake db:migrate:geo
      ```

   1. Geoステータスを確認します:

       ```shell
       sudo gitlab-rake geo:status
       ```
