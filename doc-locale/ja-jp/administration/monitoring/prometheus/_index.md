---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Prometheusを使用したGitLabのモニタリング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

[Prometheus](https://prometheus.io)は、GitLabおよびその他のソフトウェア製品のモニタリングに柔軟なプラットフォームを提供する、強力な時系列モニタリングサービスです。

GitLabは、Prometheusを活用したモニタリング機能を標準で備えており、GitLabサービスに対する高品質な時系列モニタリングへのアクセスを提供します。

このページに記載されているPrometheusおよび各種exporterは、Linuxパッケージにバンドルされています。exporterの追加時期については、各exporterのドキュメントを参照してください。自己コンパイルによるインストール環境では、ユーザー自身がこれらをインストールする必要があります。今後のリリースでは、GitLabの追加のメトリクスがキャプチャされる予定です。

デフォルトでは、Prometheusサービスは有効になっています。

Prometheusおよびそのexporterはユーザーを認証しないため、アクセス権のあるすべてのユーザーが利用できます。

## Prometheusの仕組み {#how-prometheus-works}

Prometheusは、[各種exporter](#bundled-software-metrics)を介してデータソースに定期的に接続し、パフォーマンスメトリクスを収集することで機能します。モニタリングデータを表示および操作するには、[Prometheusに直接接続](#viewing-performance-metrics)するか、[Grafana](https://grafana.com)などのダッシュボードツールを使用します。

## Prometheusを設定する {#configuring-prometheus}

自己コンパイルによるインストール環境では、ユーザー自身がPrometheusをインストールして設定する必要があります。

デフォルトでは、Prometheusとそのexporterは有効になっています。Prometheusは`gitlab-prometheus`ユーザーとして実行され、`http://localhost:9090`でリッスンします。デフォルトでは、GitLabサーバー自身からのみPrometheusにアクセスできます。各exporterは、個別に無効にしない限り、Prometheusのモニタリング対象として自動的に設定されます。

Prometheusとそのすべてのexporter、さらに将来的に追加されるexporterを無効にするには、次の手順に従います:

1. `/etc/gitlab/gitlab.rb`を編集します。
1. 次の行を追加するか、検索してコメントアウトを解除し、`false`に設定されていることを確認します:

   ```ruby
   prometheus_monitoring['enable'] = false
   sidekiq['metrics_enabled'] = false

   # Already set to `false` by default, but you can explicitly disable it to be sure
   puma['exporter_enabled'] = false
   ```

1. ファイルを保存して、[GitLabを再設定](../../restart_gitlab.md#reconfigure-a-linux-package-installation)し、変更を有効にします。

### Prometheusがリッスンするポートとアドレスを変更する {#changing-the-port-and-address-prometheus-listens-on}

{{< alert type="warning" >}}

Prometheusがリッスンするポートは変更できます。ただ、おすすめしません。変更すると、GitLabサーバーで実行されている他のサービスに影響したり、これらのサービスと競合したりする可能性があります。それでも変更する場合は、ご自身の責任において行ってください。

{{< /alert >}}

GitLabサーバーの外部からPrometheusにアクセスするには、Prometheusがリッスンするアドレスまたはポートを変更します:

1. `/etc/gitlab/gitlab.rb`を編集します。
1. 次の行を追加するか、検索してコメントアウトを解除します:

   ```ruby
   prometheus['listen_address'] = 'localhost:9090'
   ```

   `localhost:9090`を、Prometheusにリッスンさせるアドレスまたはポートに置き換えます。`localhost`以外のホストからPrometheusへのアクセスを許可する場合は、ホスト部分を省略するか、`0.0.0.0`を使用してパブリックアクセスを許可します:

   ```ruby
   prometheus['listen_address'] = ':9090'
   # or
   prometheus['listen_address'] = '0.0.0.0:9090'
   ```

1. ファイルを保存し、変更を反映させるため[GitLabを再設定](../../restart_gitlab.md#reconfigure-a-linux-package-installation)します。

### カスタムスクレイプ設定を追加する {#adding-custom-scrape-configurations}

[Prometheusのスクレイプターゲットの設定](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#%3Cscrape_config%3E)の構文を用いて、`/etc/gitlab/gitlab.rb`内の`prometheus['scrape_configs']`を編集することで、LinuxパッケージバンドルのPrometheusに追加のスクレイプターゲットを設定できます。

`http://1.1.1.1:8060/probe?param_a=test&param_b=additional_test`をスクレイプする設定の例を次に示します:

```ruby
prometheus['scrape_configs'] = [
  {
    'job_name': 'custom-scrape',
    'metrics_path': '/probe',
    'params' => {
      'param_a' => ['test'],
      'param_b' => ['additional_test'],
    },
    'static_configs' => [
      'targets' => ['1.1.1.1:8060'],
    ],
  },
]
```

### Linuxパッケージを使用したスタンドアロンPrometheus {#standalone-prometheus-using-the-linux-package}

Linuxパッケージを使用して、Prometheusを実行するスタンドアロンのモニタリングノードを設定できます。このモニタリングノードに接続するよう外部の[Grafana](../performance/grafana_configuration.md)を設定し、ダッシュボードを表示できます。

[複数ノードのGitLabデプロイ](../../reference_architectures/_index.md)には、スタンドアロンのモニタリングノードの使用が推奨されます。

LinuxパッケージでPrometheusを実行するモニタリングノードを設定するには、以下の手順が最低限必要です:

1. モニタリングノードにSSHで接続します。
1. GitLabのダウンロードページにある**steps 1 and 2**（手順1と2）を実行し、必要なLinuxパッケージを[インストール](https://about.gitlab.com/install/)します。ただし、それ以降の手順は実行しないでください。
1. 次の手順で使用するため、ConsulサーバーノードのIPアドレスまたはDNSレコードを事前に確認してください。
1. `/etc/gitlab/gitlab.rb`を編集し、次の内容を追加します:

   ```ruby
   roles ['monitoring_role']

   external_url 'http://gitlab.example.com'

   # Prometheus
   prometheus['listen_address'] = '0.0.0.0:9090'
   prometheus['monitor_kubernetes'] = false

   # Enable service discovery for Prometheus
   consul['enable'] = true
   consul['monitoring_service_discovery'] = true
   consul['configuration'] = {
      retry_join: %w(10.0.0.1 10.0.0.2 10.0.0.3), # The addresses can be IPs or FQDNs
   }

   # Nginx - For Grafana access
   nginx['enable'] = true
   ```

1. `sudo gitlab-ctl reconfigure`を実行して設定をコンパイルします。

次に、モニタリングノードの位置を他のすべてのノードに知らせる手順を実行します:

1. `/etc/gitlab/gitlab.rb`を編集し、次の行を追加するか、検索してコメントアウトを解除します:

   ```ruby
   # can be FQDN or IP
   gitlab_rails['prometheus_address'] = '10.0.0.1:9090'
   ```

   ここでの`10.0.0.1:9090`は、PrometheusノードのIPアドレスとポートです。

1. ファイルを保存して、[GitLabを再設定](../../restart_gitlab.md#reconfigure-a-linux-package-installation)し、変更を有効にします。

`consul['monitoring_service_discovery'] = true`を設定してサービスディスカバリによるモニタリングを有効にした後は、`/etc/gitlab/gitlab.rb`で`prometheus['scrape_configs']`を設定しないようにしてください。`/etc/gitlab/gitlab.rb`で`consul['monitoring_service_discovery'] = true`と`prometheus['scrape_configs']`の両方を設定すると、エラーが発生します。

### 外部のPrometheusサーバーを使用する {#using-an-external-prometheus-server}

{{< alert type="warning" >}}

Prometheusおよびほとんどのexporterは、認証をサポートしていません。そのため、ローカルネットワークを外部に公開するのはおすすめしません。

{{< /alert >}}

GitLabを外部のPrometheusサーバーでモニタリングできるようにするには、いくつかの設定変更が必要です。

外部のPrometheusサーバーを使用するには、次の手順に従います:

1. `/etc/gitlab/gitlab.rb`を編集します。
1. バンドルされているPrometheusを無効にします:

   ```ruby
   prometheus['enable'] = false
   ```

1. バンドルされている各サービスの[exporter](#bundled-software-metrics)がネットワークアドレスでリッスンするように設定します。次に例を示します:

   ```ruby
   node_exporter['listen_address'] = '0.0.0.0:9100'
   gitlab_workhorse['prometheus_listen_addr'] = "0.0.0.0:9229"

   # Rails nodes
   gitlab_exporter['listen_address'] = '0.0.0.0'
   gitlab_exporter['listen_port'] = '9168'
   registry['debug_addr'] = '0.0.0.0:5001'

   # Sidekiq nodes
   sidekiq['listen_address'] = '0.0.0.0'

   # Redis nodes
   redis_exporter['listen_address'] = '0.0.0.0:9121'

   # PostgreSQL nodes
   postgres_exporter['listen_address'] = '0.0.0.0:9187'

   # Gitaly nodes
   gitaly['configuration'] = {
      # ...
      prometheus_listen_addr: '0.0.0.0:9236',
   }

   # Pgbouncer nodes
   pgbouncer_exporter['listen_address'] = '0.0.0.0:9188'
   ```

1. 必要に応じて、[公式インストール手順](https://prometheus.io/docs/prometheus/latest/installation/)に従って専用のPrometheusインスタンスをインストールしてセットアップします。

1. **すべて**のGitLab Rails（Puma、Sidekiq）サーバーで、PrometheusサーバーのIPアドレスとリッスンポートを設定します。例: 

   ```ruby
   gitlab_rails['prometheus_address'] = '192.168.0.1:9090'
   ```

1. NGINXメトリクスをスクレイプするには、PrometheusサーバーのIPを許可するようにNGINXを設定する必要もあります。例: 

   ```ruby
   nginx['status']['options'] = {
         "server_tokens" => "off",
         "access_log" => "off",
         "allow" => "192.168.0.1",
         "deny" => "all",
   }
   ```

   Prometheusサーバーが複数ある場合は、複数のIPアドレスを指定することも可能です:

   ```ruby
   nginx['status']['options'] = {
         "server_tokens" => "off",
         "access_log" => "off",
         "allow" => ["192.168.0.1", "192.168.0.2"],
         "deny" => "all",
   }
   ```

1. Prometheusサーバーが[GitLabメトリクス](#gitlab-metrics)のエンドポイントをフェッチできるようにするには、[モニタリング用IP許可リスト](../ip_allowlist.md)にPrometheusサーバーのIPアドレスを追加します:

   ```ruby
   gitlab_rails['monitoring_whitelist'] = ['127.0.0.0/8', '192.168.0.1']
   ```

1. GitLabでは、バンドルされている各サービスの[exporter](#bundled-software-metrics)がネットワークアドレスでリッスンするように設定しているため、インスタンスのファイアウォールを更新し、有効になっているexporterに対してはPrometheusのIPからのトラフィックのみを許可するようにしてください。exporterサービスと[それぞれの](../../package_information/defaults.md#ports)ポートをまとめた完全なリストは、こちらを参照してください。
1. 変更を反映させるため、[GitLabを再設定](../../restart_gitlab.md#reconfigure-a-linux-package-installation)します。
1. Prometheusサーバーの設定ファイルを編集します。
1. 各ノードのexporterを、Prometheusサーバーの[スクレイプターゲット設定](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#%3Cscrape_config%3E)に追加します。たとえば、`static_configs`を使用したサンプルスニペットは次のとおりです:

   ```yaml
   scrape_configs:
     - job_name: nginx
       static_configs:
         - targets:
           - 1.1.1.1:8060
     - job_name: redis
       static_configs:
         - targets:
           - 1.1.1.1:9121
     - job_name: postgres
       static_configs:
         - targets:
           - 1.1.1.1:9187
     - job_name: node
       static_configs:
         - targets:
           - 1.1.1.1:9100
     - job_name: gitlab-workhorse
       static_configs:
         - targets:
           - 1.1.1.1:9229
     - job_name: gitlab-rails
       metrics_path: "/-/metrics"
       scheme: https
       static_configs:
         - targets:
           - 1.1.1.1
     - job_name: gitlab-sidekiq
       static_configs:
         - targets:
           - 1.1.1.1:8082
     - job_name: gitlab_exporter_database
       metrics_path: "/database"
       static_configs:
         - targets:
           - 1.1.1.1:9168
     - job_name: gitlab_exporter_sidekiq
       metrics_path: "/sidekiq"
       static_configs:
         - targets:
           - 1.1.1.1:9168
     - job_name: gitaly
       static_configs:
         - targets:
           - 1.1.1.1:9236
     - job_name: registry
       static_configs:
         - targets:
           - 1.1.1.1:5001
   ```

   {{< alert type="warning" >}}

   このスニペットの`gitlab-rails`ジョブは、GitLabにHTTPS経由でアクセス可能であることを前提としています。デプロイがHTTPSを使用していない場合は、`http`スキームとポート80を使用するようにジョブ設定が調整されます。

   {{< /alert >}}

1. Prometheusサーバーをリロードします。

### ストレージ保持サイズを設定する {#configure-the-storage-retention-size}

Prometheusには、ローカルストレージを設定するためのカスタムフラグがいくつかあります:

- `storage.tsdb.retention.time`: 古いデータを削除するタイミング。デフォルトは`15d`です。このフラグがデフォルト以外の値に設定されている場合、`storage.tsdb.retention`を上書きします。
- `storage.tsdb.retention.size`: 保持するストレージブロックの最大バイト数（実験的なフラグ）。最も古いデータから削除されます。デフォルトは`0`（無効）です。このフラグは実験的な機能です。今後のリリースで変更される可能性があります。サポート対象の単位は`B`、`KB`、`MB`、`GB`、`TB`、`PB`、`EB`です。例えば、`512MB`です。

ストレージ保持サイズを設定するには、次の手順に従います:

1. `/etc/gitlab/gitlab.rb`を編集します:

   ```ruby
   prometheus['flags'] = {
     'storage.tsdb.path' => "/var/opt/gitlab/prometheus/data",
     'storage.tsdb.retention.time' => "7d",
     'storage.tsdb.retention.size' => "2GB",
     'config.file' => "/var/opt/gitlab/prometheus/prometheus.yml"
   }
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## パフォーマンスメトリクスを表示する {#viewing-performance-metrics}

Prometheusがデフォルトで提供するダッシュボードを確認するには、`http://localhost:9090`にアクセスします。

GitLabインスタンスでSSLが有効になっており、同じFQDNを使用している場合、[HSTS](https://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security)の影響により、GitLabと同じブラウザでPrometheusにアクセスできない可能性があります。アクセスできるようにするための[GitLabテストプロジェクトが進行中](https://gitlab.com/gitlab-org/multi-user-prometheus)ですが、それが利用可能になるまでの間は、別のFQDNを使用する、サーバーIPを使用する、Prometheus用に別のブラウザを使用する、HSTSをリセットする、[NGINXでプロキシ処理を行う](https://docs.gitlab.com/omnibus/settings/nginx.html#inserting-custom-nginx-settings-into-the-gitlab-server-block)といった回避策があります。

Prometheusによって収集されたパフォーマンスデータは、Prometheusコンソールで直接表示するか、互換性のあるダッシュボードツールで表示できます。Prometheusインターフェースには、収集されたデータを操作するための[柔軟なクエリ言語](https://prometheus.io/docs/prometheus/latest/querying/basics/)が用意されており、出力を視覚化できます。フル機能を備えたダッシュボードとしてGrafanaを使用でき、[Prometheus向けの公式サポート](https://prometheus.io/docs/visualization/grafana/)もあります。

## Prometheusクエリのサンプル {#sample-prometheus-queries}

以下は、使用できるPrometheusクエリのサンプルです。

{{< alert type="note" >}}

これらのサンプルはあくまでも一例です。すべてのセットアップで機能するとは限りません。さらに調整が必要になる場合があります。

{{< /alert >}}

- **% CPU utilization**（CPU使用率）: `1 - avg without (mode,cpu) (rate(node_cpu_seconds_total{mode="idle"}[5m]))`
- **% Memory available**（使用可能なメモリの割合）: `((node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) or ((node_memory_MemFree_bytes + node_memory_Buffers_bytes + node_memory_Cached_bytes) / node_memory_MemTotal_bytes)) * 100`
- **Data transmitted**（送信データ量）: `rate(node_network_transmit_bytes_total{device!="lo"}[5m])`
- **Data received**（受信データ量）: `rate(node_network_receive_bytes_total{device!="lo"}[5m])`
- **Disk read IOPS**（ディスクの読み取りIOPS）: `sum by (instance) (rate(node_disk_reads_completed_total[1m]))`
- **Disk write IOPS**（ディスクの書き込みIOPS）: `sum by (instance) (rate(node_disk_writes_completed_total[1m]))`
- **RPS via GitLab transaction count**（GitLabのトランザクション数に基づくRPS）: `sum(irate(gitlab_transaction_duration_seconds_count{controller!~'HealthController|MetricsController'}[1m])) by (controller, action)`

## GrafanaデータソースとしてのPrometheus {#prometheus-as-a-grafana-data-source}

Grafanaでは、Prometheusパフォーマンスメトリクスをデータソースとしてインポートし、そのメトリクスをグラフやダッシュボードとして表示できます。これはメトリクスの視覚化に役立ちます。

単一サーバーのGitLabセットアップにPrometheusダッシュボードを追加するには、次の手順に従います:

1. Grafanaで新しいデータソースを作成します。
1. **種類**で、`Prometheus`を選択します。
1. データソースに名前を付けます（例: GitLab）。
1. **Prometheus server URL**（PrometheusサーバーのURL）に、Prometheusのリッスンアドレスを入力します。
1. **HTTP method**（HTTPメソッド）を`GET`に設定します。
1. 設定を保存してテストし、正しく動作することを確認します。

## GitLabメトリクス {#gitlab-metrics}

GitLabは独自の内部サービスメトリクスを監視し、`/-/metrics`エンドポイントで利用できるようにします。他のexporterとは異なり、このエンドポイントはユーザートラフィックと同じURLおよびポートで提供されるため、認証が必要です。

詳細については、[GitLabメトリクス](gitlab_metrics.md)を参照してください。

## バンドルされたソフトウェアメトリクス {#bundled-software-metrics}

LinuxパッケージにバンドルされているGitLabの依存関係の多くは、Prometheusメトリクスをエクスポートするように事前に設定されています。

### ノードExporter {#node-exporter}

ノードexporterを使用すると、メモリ、ディスク、CPU使用率など、さまざまなマシンリソースを測定できます。

詳細については、[ノードexporter](node_exporter.md)を参照してください。

### Web exporter {#web-exporter}

Web exporterは、エンドユーザーとPrometheusのトラフィックを2つの異なるアプリケーションに分離することで、パフォーマンスと可用性を向上させる専用のメトリクスサーバーです。

詳細については、[Web exporter](web_exporter.md)を参照してください。

### Redis exporter {#redis-exporter}

Redis exporterを使用すると、さまざまなRedisメトリクスを測定できます。

詳細については、[Redis exporter](redis_exporter.md)を参照してください。

### PostgreSQL exporter {#postgresql-exporter}

PostgreSQL exporterを使用すると、さまざまなPostgreSQLメトリクスを測定できます。

詳細については、[PostgreSQL exporter](postgres_exporter.md)を参照してください。

### PgBouncer exporter {#pgbouncer-exporter}

PgBouncer exporterを使用すると、さまざまなPgBouncerメトリクスを測定できます。

詳細については、[PgBouncer exporter](pgbouncer_exporter.md)を参照してください。

### レジストリexporter {#registry-exporter}

レジストリexporterを使用すると、さまざまなレジストリメトリクスを測定できます。

詳細については、[レジストリexporter](registry_exporter.md)を参照してください。

### GitLab exporter {#gitlab-exporter}

GitLab exporterを使用すると、RedisやデータベースからプルされたさまざまなGitLabメトリクスを測定できます。

詳細については、[GitLab exporter](gitlab_exporter.md)を参照してください。

## トラブルシューティング {#troubleshooting}

### `/var/opt/gitlab/prometheus`がディスク容量を過剰に消費する {#varoptgitlabprometheus-consumes-too-much-disk-space}

Prometheusモニタリングを**not**（使用していない場合）:

1. [Prometheusを無効にします](_index.md#configuring-prometheus)。
1. `/var/opt/gitlab/prometheus`配下のデータを削除します。

Prometheusモニタリングを使用している場合:

1. Prometheusを停止します（実行中にデータを削除すると、データが破損する可能性があります）:

   ```shell
   gitlab-ctl stop prometheus
   ```

1. `/var/opt/gitlab/prometheus/data`配下のデータを削除します。
1. サービスを再起動します:

   ```shell
   gitlab-ctl start prometheus
   ```

1. サービスが起動して実行中であることを確認します:

   ```shell
   gitlab-ctl status prometheus
   ```

1. オプション。[ストレージ保持サイズを設定します](_index.md#configure-the-storage-retention-size)。

### モニタリングノードがデータを受信していない {#monitoring-node-not-receiving-data}

モニタリングノードがデータを受信していない場合は、次のようにexporterがデータをキャプチャしていることを確認してください:

```shell
curl "http[s]://localhost:<EXPORTER LISTENING PORT>/metrics"
```

または

```shell
curl "http[s]://localhost:<EXPORTER LISTENING PORT>/-/metrics"
```
