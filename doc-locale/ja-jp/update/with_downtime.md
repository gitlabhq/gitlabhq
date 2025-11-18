---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ダウンタイムを設けてマルチノードインスタンスをアップグレードする
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

ダウンタイムを伴うマルチノードGitLabインスタンスをアップグレードするには、次の手順に従います:

1. GitLabアプリケーションを停止します。
1. Consulサーバーをアップグレードします。
1. Gitaly、Rails、PostgreSQL、Redis、およびPgBouncerを任意の順序でアップグレードします。クラウドプロバイダーのPostgreSQLまたはRedisを使用しており、アップグレードが必要な場合は、これらの手順をクラウドプロバイダーの手順に置き換えてください。
1. GitLabアプリケーション（Sidekiq、Puma）をアップグレードし、アプリケーションを起動します。

ダウンタイムを伴うアップグレードを開始する前に、[ダウンタイムのオプションを検討してください](downtime_options.md)。

## GitLabアプリケーションを停止する {#shut-down-the-gitlab-application}

アップグレードする前に、GitLabアプリケーションを停止してデータベースへの書き込みを停止する必要があります。プロセスは、[インストール方法](../administration/reference_architectures/_index.md)によって異なります。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

これらのプロセスを実行しているすべてのサーバーで、PumaとSidekiqを停止します:

```shell
sudo gitlab-ctl stop sidekiq
sudo gitlab-ctl stop puma
```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

[Helmチャート](../administration/reference_architectures/_index.md#cloud-native-hybrid)インスタンスの場合:

1. 後続の再起動のために、データベースクライアントの現在のレプリカ数を書き留めます:

```shell
kubectl get deploy -n <namespace> -l release=<helm release name> -l 'app in (prometheus,webservice,sidekiq)' -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.replicas}{"\n"}{end}'
```

1. データベースのクライアントを停止します:

```shell
kubectl scale deploy -n <namespace> -l release=<helm release name> -l 'app in (prometheus,webservice,sidekiq)' --replicas=0
```

{{< /tab >}}

{{< /tabs >}}

## Consulノードのアップグレード {#upgrade-the-consul-nodes}

[Consulノードのアップグレード](../administration/consul.md#upgrade-the-consul-nodes)の手順に従います。要約:

1. Consulノードがすべて正常であることを確認します。
1. すべてのConsulサーバーで[GitLabをアップグレード](package/_index.md)します。
1. すべてのGitLabサービスを**一度に1つのノード**ずつ再起動します:

   ```shell
   sudo gitlab-ctl restart
   ```

Consulクラスターのプロセスは、独自のサーバー上に存在しない可能性があり、Redis高可用性やPatroniなどの別のサービスと共有されています。この場合、これらのサーバーをアップグレードするとき:

- 一度に1つのサーバーでのみサービスを再起動します。
- サービスをアップグレードまたは再起動する前に、Consulクラスターが正常であることを確認してください。

## GitalyとGitalyクラスター（Praefect）のアップグレード {#upgrade-gitaly-and-gitaly-cluster-praefect}

Gitalyクラスター（Praefect）の一部ではないGitalyサーバーの場合は、[GitLabをアップグレード](package/_index.md)します。複数のGitalyシャードがある場合は、Gitalyサーバーを任意の順序でアップグレードできます。

Gitalyクラスター（Praefect）を実行している場合は、[Gitalyクラスター（Praefect）のゼロダウンタイムアップグレードプロセス](zero_downtime.md#upgrade-gitaly-cluster-praefect-nodes)に従ってください。

### Amazon Web Services Machine Imagesを使用する場合 {#when-using-amazon-machine-images}

AWSでAmazon Web Services Machine Images（AMI）を使用している場合は、AMI再デプロイプロセスを使用してGitalyノードをアップグレードできます。このプロセスを使用するには、[Elasticネットワーキング](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-eni.html)（ENI）を使用する必要があります。Gitalyクラスター（Praefect）は、サーバーのホスト名でGitリポジトリのレプリカを追跡します。ENIは、インスタンスが再デプロイされるときにプライベートドメイン名サービス名が同じままであることを保証できます。ストレージが同じであっても、ノードが新しいホスト名で再デプロイされる場合、Gitalyクラスター（Praefect）は機能しません。

ENIを使用していない場合は、Linuxパッケージを使用してGitalyノードをアップグレードする必要があります。

AMI再デプロイプロセスを使用してGitalyクラスター（Praefect）ノードをアップグレードするには:

1. AMI再デプロイプロセスには`gitlab-ctl reconfigure`を含める必要があります。すべてのノードがこれを取得するように、AMIで`praefect['auto_migrate'] = false`を設定します。この設定により、`reconfigure`がデータベースの移行を自動的に実行できなくなります。
1. アップグレードされたイメージで再デプロイされる最初のノードは、デプロイノードである必要があります。
1. デプロイされたら、`praefect['auto_migrate'] = true`を`gitlab.rb`に設定し、`gitlab-ctl reconfigure`を適用します。
1. このコマンドは、データベースの移行を実行します。
1. 他のGitalyクラスター（Praefect）ノードを再デプロイします。

## PostgreSQLノードのアップグレード {#upgrade-the-postgresql-nodes}

クラスター化されていないPostgreSQLサーバーの場合:

1. [GitLabをアップグレード](package/_index.md)します。
1. アップグレードプロセスではバイナリのアップグレード時にPostgreSQLが再起動されないため、再起動して新しいバージョンを読み込むます:

   ```shell
   sudo gitlab-ctl restart
   ```

### Patroniノードのアップグレード {#upgrade-patroni-nodes}

Patroniは、PostgreSQLで高可用性を実現するために使用されます。

PostgreSQLのメジャーバージョンのアップグレードが必要な場合は、[メジャーバージョンのプロセスに従ってください](../administration/postgresql/replication_and_failover.md#upgrading-postgresql-major-version-in-a-patroni-cluster)。

他のすべてのバージョンのアップグレードプロセスは、最初にすべてのレプリカで実行されます。レプリカがアップグレードされると、リーダーからアップグレードされたレプリカの1つにクラスターフェイルオーバーが発生します。このプロセスにより、必要なフェイルオーバーが1つだけで、完了すると、新しいリーダーがアップグレードされます。

Patroniノードをアップグレードするには:

1. リーダーノードとレプリカノードを特定し、[クラスターが正常であることを確認](../administration/postgresql/replication_and_failover.md#check-replication-status)します。データベースノードで、次を実行します:

   ```shell
   sudo gitlab-ctl patroni members
   ```

1. レプリカノードの1つで[GitLabをアップグレード](package/_index.md)します。
1. 再起動して新しいバージョンを読み込むます:

   ```shell
   sudo gitlab-ctl restart
   ```

1. [クラスターが正常であることを確認](../administration/postgresql/replication_and_failover.md#check-replication-status)します。
1. 他のレプリカについて、アップグレード、再起動、ヘルスチェックの手順を繰り返します。
1. リーダーノードを、レプリカと同じLinuxパッケージアップグレードに従ってアップグレードします。
1. リーダーノード上のすべてのサービスを再起動して、新しいバージョンを読み込むと同時に、クラスターフェイルオーバーをトリガーします:

   ```shell
   sudo gitlab-ctl restart
   ```

1. [クラスターが正常であることを確認](../administration/postgresql/replication_and_failover.md#check-replication-status)

## PgBouncerノードのアップグレード {#upgrade-the-pgbouncer-nodes}

GitLabアプリケーション（Rails）ノードでPgBouncerを実行している場合、PgBouncerはアプリケーションサーバーのアップグレードの一部としてアップグレードされます。それ以外の場合は、PgBouncerノードで[GitLabをアップグレード](package/_index.md)します。

## Redisノードのアップグレード {#upgrade-the-redis-node}

Redisノードで[GitLabをアップグレード](package/_index.md)して、スタンドアロンRedisサーバーをアップグレードします。

### Redis高可用性（Sentinelを使用）のアップグレード {#upgrade-redis-ha-using-sentinel}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Redis HAクラスターをアップグレードするには、[ゼロダウンタイムの手順](zero_downtime.md)に従ってください。

## GitLabアプリケーションコンポーネントのアップグレード {#upgrade-the-gitlab-application-components}

GitLabアプリケーションのアップグレードプロセスは、インストール方法によって異なります。

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

PumaプロセスとSidekiqプロセスはすべて、以前に停止されました。各GitLabアプリケーションノードで:

1. `/etc/gitlab/skip-auto-reconfigure`が存在しないことを確認します。
1. PumaとSidekiqが停止していることを確認してください:

   ```shell
   ps -ef | egrep 'puma: | puma | sidekiq '
   ```

すべてのデータベース移行を実行するデプロイノードとしてPumaを実行する1つのノードを選択します。デプロイノードで:

1. サーバーが通常の移行を許可するように構成されていることを確認します。`/etc/gitlab/gitlab.rb`に`gitlab_rails['auto_migrate'] = false`が含まれていないことを確認します。具体的に`gitlab_rails['auto_migrate'] = true`を設定するか、デフォルトの動作（`true`）を省略します。

1. PgBouncerを使用している場合は、PgBouncerを回避し、移行を実行する前にPostgreSQLに直接接続する必要があります。

   Railsは、同じデータベースで同時移行が実行されないようにするために、移行を実行しようとすると、アドバイザリーロックを使用します。これらのロックはトランザクション間で共有されないため、トランザクションプールモードでPgBouncerを使用してデータベースの移行を実行すると、`ActiveRecord::ConcurrentMigrationError`エラーやその他の問題が発生します。

   1. Patroniを実行している場合は、リーダーノードを見つけます。データベースノードで実行します:

      ```shell
      sudo gitlab-ctl patroni members
      ```

   1. デプロイノードで`gitlab.rb`を更新します。`gitlab_rails['db_host']`と`gitlab_rails['db_port']`を次のいずれかに変更します:

      - データベースサーバー（クラスター化されていないPostgreSQL）のホストとポート。
      - Patroniを実行している場合は、クラスターリーダーのホストとポート。

   1. 変更を適用します:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

1. [GitLabをアップグレード](package/_index.md)します。
1. PgBouncerを回避するためにデプロイノードで`gitlab.rb`を変更した場合:
   1. デプロイノードで`gitlab.rb`を更新します。`gitlab_rails['db_host']`と`gitlab_rails['db_port']`をPgBouncer設定に戻します。
   1. 変更を適用します:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

1. すべてのサービスがアップグレードされたバージョンを実行し、（該当する場合）PgBouncerを使用してデータベースにアクセスしていることを確認するには、デプロイノードですべてのサービスを再起動します:

   ```shell
   sudo gitlab-ctl restart
   ```

次に、他のすべてのPumaノードとSidekiqノードをアップグレードします。これらのノードでは、設定`gitlab_rails['auto_migrate']`を`gitlab.rb`の任意の値に設定できます。

これらは並行してアップグレードできます:

1. [GitLabをアップグレード](package/_index.md)します。
1. すべてのサービスが再起動されていることを確認します:

   ```shell
   sudo gitlab-ctl restart
   ```

{{< /tab >}}

{{< tab title="Helmチャート（Kubernetes）" >}}

すべてのステートフルコンポーネントがアップグレードされたら、[GitLabチャートのアップグレード手順](https://docs.gitlab.com/charts/installation/upgrade.html)に従って、ステートレスコンポーネント（Webservice、Sidekiq、その他のサポートサービス）をアップグレードします。

GitLabチャートのアップグレードを実行したら、データベースクライアントを再開します:

```shell
kubectl scale deploy -lapp=sidekiq,release=<helm release name> -n <namespace> --replicas=<value>
kubectl scale deploy -lapp=webservice,release=<helm release name> -n <namespace> --replicas=<value>
kubectl scale deploy -lapp=prometheus,release=<helm release name> -n <namespace> --replicas=<value>
```

{{< /tab >}}

{{< /tabs >}}

## モニターノードのアップグレード {#upgrade-the-monitor-node}

スタンドアロンのモニタリングノードとして機能するようにPrometheusを構成している場合があります。たとえば、[60 RPSまたは3,000人のユーザー参照アーキテクチャを構成する](../administration/reference_architectures/3k_users.md#configure-prometheus)一部として。

モニターノードをアップグレードするには、ノードで[GitLabをアップグレード](package/_index.md)します。
