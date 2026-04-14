---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Redisのトラブルシューティング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

HAのセットアップが期待通りに機能するためには、多くの動的要素に注意を払う必要があります。

以下のトラブルシューティングに進む前に、ファイアウォールルールを確認してください:

- Redisマシン
  - `6379`でTCP接続を受け入れます
  - `6379`でTCP経由で他のRedisマシンに接続します
- Sentinelマシン
  - `26379`でTCP接続を受け入れます
  - `26379`でTCP経由で他のSentinelマシンに接続します
  - `6379`でTCP経由でRedisマシンに接続します

## 基本的なRedisアクティビティチェック {#basic-redis-activity-check}

基本的なRedisアクティビティチェックでRedisのトラブルシューティングを開始します:

1. GitLabサーバーでターミナルを開きます。
1. `gitlab-redis-cli --stat`を実行し、実行中の出力を観察します。
1. お使いのGitLab UIに移動し、いくつかのページを閲覧します。グループまたはプロジェクトの概要、イシュー、リポジトリ内のファイルなど、どのページでも機能します。
1. 再度`stat`の出力を確認し、閲覧するにつれて`keys`、`clients`、`requests`、および`connections`の値が増加することを確認します。数値が増加すれば、基本的なRedis機能は動作しており、GitLabはそれに接続できます。

## Redisのレプリケーションのトラブルシューティング {#troubleshooting-redis-replication}

`redis-cli`アプリケーションを使用して各サーバーに接続し、以下の`info replication`コマンドを送信することで、すべてが正しいか確認できます。

```shell
/opt/gitlab/embedded/bin/redis-cli -h <redis-host-or-ip> -a '<redis-password>' info replication
```

`Primary` Redisに接続すると、接続されている`replicas`の数と、接続詳細を含むそれぞれのリストが表示されます:

```plaintext
# Replication
role:master
connected_replicas:1
replica0:ip=10.133.5.21,port=6379,state=online,offset=208037514,lag=1
master_repl_offset:208037658
repl_backlog_active:1
repl_backlog_size:1048576
repl_backlog_first_byte_offset:206989083
repl_backlog_histlen:1048576
```

それが`replica`の場合、プライマリ接続の詳細と、そのステータスが`up`か`down`かが表示されます:

```plaintext
# Replication
role:replica
master_host:10.133.1.58
master_port:6379
master_link_status:up
master_last_io_seconds_ago:1
master_sync_in_progress:0
replica_repl_offset:208096498
replica_priority:100
replica_read_only:1
connected_replicas:0
master_repl_offset:0
repl_backlog_active:0
repl_backlog_size:1048576
repl_backlog_first_byte_offset:0
repl_backlog_histlen:0
```

## Redisインスタンスでの高いCPU使用率 {#high-cpu-usage-on-redis-instance}

デフォルトでは、GitLabは600以上のSidekiqキューを使用し、それぞれがRedisリストとして保存されます。各Sidekiqスレッドは、長い文字列でリストされたすべてのキューを含む`BRPOP`コマンドを発行します。キューの数と`BRPOP`呼び出しのレートが増加するにつれて、RedisのCPU使用率が上昇します。お使いのGitLabインスタンスに多くのSidekiqプロセスがある場合、これによりRedisのCPU使用率が100%に近づく可能性があります。高いCPU使用率は、GitLabのパフォーマンスを著しく低下させます。

Sidekiqによって引き起こされるRedisのCPU使用率を削減するには、次の両方を行うことができます:

- Sidekiqキューの数を減らすために、[ルーティングルール](../sidekiq/processing_specific_job_classes.md#routing-rules)を使用します。
- GitLab 16.6以前を使用している場合、RedisのCPU使用率を改善するために[`SIDEKIQ_SEMI_RELIABLE_FETCH_TIMEOUT`環境変数](../environment_variables.md)を増やしてください。GitLab 16.7以降では、[値はデフォルトで5](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/139583)であり、これは十分であるはずです。

`SIDEKIQ_SEMI_RELIABLE_FETCH_TIMEOUT`オプションは、切断と接続によるオーバーヘッドを削減しますが、Sidekiqのシャットダウン遅延を増加させます。

## Sentinelのトラブルシューティング {#troubleshooting-sentinel}

`Redis::CannotConnectError: No sentinels available.`のようなエラーが発生した場合、設定ファイルに問題があるか、または[このイシュー](https://github.com/redis/redis-rb/issues/531)に関連している可能性があります。

Sentinelノードで定義したのと同じ値を`redis['master_name']`と`redis['master_password']`で定義していることを確認する必要があります。

Redisコネクタ`redis-rb`がSentinelと連携する動作は、やや直感的ではありません。この複雑さはLinuxパッケージ内で隠蔽しようとしていますが、それでもいくつかの追加設定が必要です。

お使いの設定が正しいことを確認するには:

1. GitLabアプリケーションサーバーにSSH接続します
1. Railsコンソールに入ります:

   ```shell
   # For Omnibus installations
   sudo gitlab-rails console

   # For source installations
   sudo -u git rails console -e production
   ```

1. コンソールで実行します:

   ```ruby
   redis = Gitlab::Redis::SharedState.redis
   redis.info
   ```

   この画面を開いたまま、以下に説明されているようにフェイルオーバーをトリガーするに進みます。

1. プライマリRedisでフェイルオーバーをトリガーするには、RedisサーバーにSSH接続し、実行します:

   ```shell
   # port must match your primary redis port, and the sleep time must be a few seconds bigger than defined one
    redis-cli -h localhost -p 6379 DEBUG sleep 20
   ```

   > [!warning]
   > このアクションはサービスに影響を与え、最大20秒間インスタンスを停止させます。成功すれば、その後回復するはずです。

1. 次に、最初のステップからRailsコンソールに戻って、実行します:

   ```ruby
   redis.info
   ```

   数秒の遅延（フェイルオーバー/再接続時間）の後、異なるポートが表示されるはずです。

## バンドルされていないRedisとセルフコンパイルインストールでのトラブルシューティング {#troubleshooting-a-non-bundled-redis-with-a-self-compiled-installation}

GitLabで`Redis::CannotConnectError: No sentinels available.`のようなエラーが発生した場合、設定ファイルに問題があるか、または[このアップストリームのイシュー](https://github.com/redis/redis-rb/issues/531)に関連している可能性があります。

`resque.yml`と`sentinel.conf`が正しく設定されていることを確認する必要があります。そうでない場合、`redis-rb`は正常に動作しません。

`sentinel.conf`で定義された`master-group-name`（`gitlab-redis`）は、GitLab（`resque.yml`）のホスト名として**must**使用する必要があります:

```conf
# sentinel.conf:
sentinel monitor gitlab-redis 10.0.0.1 6379 2
sentinel down-after-milliseconds gitlab-redis 10000
sentinel config-epoch gitlab-redis 0
sentinel leader-epoch gitlab-redis 0
```

```yaml
# resque.yaml
production:
  url: redis://:myredispassword@gitlab-redis/
  sentinels:
    -
      host: 10.0.0.1
      port: 26379  # point to sentinel, not to redis port
    -
      host: 10.0.0.2
      port: 26379  # point to sentinel, not to redis port
    -
      host: 10.0.0.3
      port: 26379  # point to sentinel, not to redis port
```

不明な点がある場合は、[Redis Sentinel](https://redis.io/docs/latest/operate/oss_and_stack/management/sentinel/)のドキュメントを参照してください。
