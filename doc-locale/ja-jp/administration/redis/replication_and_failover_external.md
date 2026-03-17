---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Redisのレプリケーションとフェイルオーバー（独自のインスタンスの提供）
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

クラウドプロバイダーでGitLabをホスティングしている場合、オプションでRedisのマネージドサービスを使用できます。たとえば、AWSはRedisを実行するElastiCacheを提供しています。

あるいは、Linuxパッケージとは別に独自のRedisインスタンスを管理することも選択できます。

## 要件 {#requirements}

以下は、独自のRedisインスタンスを提供する際の要件です:

- [要件ページ](../../install/requirements.md)で、必要な最低限のRedisバージョンを確認してください。
- スタンドアロンRedisまたはSentinelを使用したRedis HAがサポートされています。Redisクラスターはサポートされていません。
- AWS ElastiCacheなどのクラウドプロバイダーが提供するマネージドRedisは問題なく動作します。これらのサービスがHAをサポートしている場合、Redis Clusterタイプでは**not**ことを確認してください。

RedisノードのIPアドレスまたはホスト名、ポート、およびパスワード（必要な場合）をメモしてください。

## クラウドプロバイダーのマネージドサービスとしてのRedis {#redis-as-a-managed-service-in-a-cloud-provider}

1. [要件](#requirements)に従ってRedisをセットアップしてください。
1. `/etc/gitlab/gitlab.rb`ファイルで、外部Redisサービスに適した接続詳細を使用してGitLabアプリケーションサーバーを設定します:

   単一のRedisインスタンスを使用する場合:

   ```ruby
   redis['enable'] = false

   gitlab_rails['redis_host'] = '<redis_instance_url>'
   gitlab_rails['redis_port'] = '<redis_instance_port>'

   # Required if Redis authentication is configured on the Redis node
   gitlab_rails['redis_password'] = '<redis_password>'

   # Set to true if instance is using Redis SSL
   gitlab_rails['redis_ssl'] = true
   ```

   Redisキャッシュと永続インスタンスを分けて使用する場合:

   ```ruby
   redis['enable'] = false

   # Default Redis connection
   gitlab_rails['redis_host'] = '<redis_persistent_instance_url>'
   gitlab_rails['redis_port'] = '<redis_persistent_instance_port>'
   gitlab_rails['redis_password'] = '<redis_persistent_password>'

   # Set to true if instance is using Redis SSL
   gitlab_rails['redis_ssl'] = true

   # Redis Cache connection
   # Replace `redis://` with `rediss://` if using SSL
   gitlab_rails['redis_cache_instance'] = 'redis://:<redis_cache_password>@<redis_cache_instance_url>:<redis_cache_instance_port>'
   ```

1. 変更を有効にするには、再設定してください:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### エビクションポリシーの設定 {#setting-the-eviction-policy}

単一のRedisインスタンスを実行している場合、エビクションポリシーは`noeviction`に設定する必要があります。

Redisキャッシュと永続インスタンスを分けて実行している場合、キャッシュは[最小利用頻度キャッシュ](https://redis.io/docs/latest/operate/rs/databases/memory-performance/eviction-policy/)（LRU）として`allkeys-lru`で設定し、永続は`noeviction`に設定する必要があります。

これを設定するかどうかはクラウドプロバイダーやサービスによって異なりますが、一般的に以下の設定と値でキャッシュを設定します:

- `maxmemory-policy` = `allkeys-lru`
- `maxmemory-samples` = `5`

## 独自のRedisサーバーを使用したRedisのレプリケーションとフェイルオーバー {#redis-replication-and-failover-with-your-own-redis-servers}

これは、Redisを独自にインストールし、Linuxパッケージにバンドルされているものを使用しない場合に、スケーラブルなRedisセットアップを設定するためのドキュメントです。ただし、LinuxパッケージはGitLab向けに特別に最適化されており、最新のサポートバージョンへのRedisのアップグレードも担当しているため、その使用を強くお勧めします。

また、[設定ファイルのドキュメント](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/README.md)に概説されている高度なRedis設定に従って、`/home/git/gitlab/config/resque.yml`へのすべての参照をオーバーライドすることも選択できることに注意してください。

LinuxパッケージのRedis HAに関する[レプリケーションとフェイルオーバー](replication_and_failover.md)のドキュメントを読むことの重要性は、いくら強調してもしすぎることはありません。これは、Redisの設定に非常に貴重な情報を提供しているためです。このガイドに進む前に、それを読んでください。

新しいRedisインスタンスをセットアップする前に、いくつかの要件があります:

- このガイドのすべてのRedisサーバーは、ソケットではなくTCP接続を使用するように設定する必要があります。RedisでTCP接続を使用するように設定するには、Redis設定ファイルで`bind`と`port`の両方を定義する必要があります。すべてのインターフェース（`0.0.0.0`）にバインドするか、目的のインターフェースのIP（たとえば、内部ネットワークからのもの）を指定できます。
- Redis 3.2以降、外部接続を受信するにはパスワード（`requirepass`）を定義する必要があります。
- SentinelでRedisを使用している場合、同じインスタンスでレプリカパスワード定義（`masterauth`）にも同じパスワードを定義する必要があります。

さらに、[Linuxパッケージを使用したRedisのレプリケーションとフェイルオーバー](replication_and_failover.md#requirements)に記載されている前提条件を読んでください。

### ステップ1.プライマリRedisインスタンスの設定 {#step-1-configuring-the-primary-redis-instance}

RedisプライマリインスタンスのIPが`10.0.0.1`であると仮定します:

1. [Redisをインストール](../../install/self_compiled/_index.md#8-redis)します。
1. `/etc/redis/redis.conf`を編集します。

   ```conf
   ## Define a `bind` address pointing to a local IP that your other machines
   ## can reach you. If you really need to bind to an external accessible IP, make
   ## sure you add extra firewall rules to prevent unauthorized access:
   bind 10.0.0.1

   ## Define a `port` to force redis to listen on TCP so other machines can
   ## connect to it (default port is `6379`).
   port 6379

   ## Set up password authentication (use the same password in all nodes).
   ## The password should be defined equal for both `requirepass` and `masterauth`
   ## when setting up Redis to use with Sentinel.
   requirepass redis-password-goes-here
   masterauth redis-password-goes-here
   ```

1. 変更を有効にするには、Redisサービスを再起動します。

### ステップ2.レプリカRedisインスタンスの設定 {#step-2-configuring-the-replica-redis-instances}

RedisレプリカインスタンスのIPが`10.0.0.2`であると仮定します:

1. [Redisをインストール](../../install/self_compiled/_index.md#8-redis)します。
1. `/etc/redis/redis.conf`を編集します。

   ```conf
   ## Define a `bind` address pointing to a local IP that your other machines
   ## can reach you. If you really need to bind to an external accessible IP, make
   ## sure you add extra firewall rules to prevent unauthorized access:
   bind 10.0.0.2

   ## Define a `port` to force redis to listen on TCP so other machines can
   ## connect to it (default port is `6379`).
   port 6379

   ## Set up password authentication (use the same password in all nodes).
   ## The password should be defined equal for both `requirepass` and `masterauth`
   ## when setting up Redis to use with Sentinel.
   requirepass redis-password-goes-here
   masterauth redis-password-goes-here

   ## Define `replicaof` pointing to the Redis primary instance with IP and port.
   replicaof 10.0.0.1 6379
   ```

1. 変更を有効にするには、Redisサービスを再起動します。
1. 他のすべてのレプリカノードについても、これらの手順を繰り返します。

### ステップ3.Redis Sentinelインスタンスの設定 {#step-3-configuring-the-redis-sentinel-instances}

Sentinelは特殊なタイプのRedisサーバーです。これは、`redis.conf`で定義できる基本的な設定オプションのほとんどを継承し、特定のものは`sentinel`プレフィックスで始まります。

Redis SentinelがRedisプライマリと同じインスタンスにIP `10.0.0.1`でインストールされていると仮定します（一部の設定はプライマリと重複する可能性があります）:

1. [Redis Sentinelをインストール](https://redis.io/docs/latest/operate/oss_and_stack/management/sentinel/)します。
1. `/etc/redis/sentinel.conf`を編集します。

   ```conf
   ## Define a `bind` address pointing to a local IP that your other machines
   ## can reach you. If you really need to bind to an external accessible IP, make
   ## sure you add extra firewall rules to prevent unauthorized access:
   bind 10.0.0.1

   ## Define a `port` to force Sentinel to listen on TCP so other machines can
   ## connect to it (default port is `6379`).
   port 26379

   ## Set up password authentication (use the same password in all nodes).
   ## The password should be defined equal for both `requirepass` and `masterauth`
   ## when setting up Redis to use with Sentinel.
   requirepass redis-password-goes-here
   masterauth redis-password-goes-here

   ## Define with `sentinel auth-pass` the same shared password you have
   ## defined for both Redis primary and replicas instances.
   sentinel auth-pass gitlab-redis redis-password-goes-here

   ## Define with `sentinel monitor` the IP and port of the Redis
   ## primary node, and the quorum required to start a failover.
   sentinel monitor gitlab-redis 10.0.0.1 6379 2

   ## Define with `sentinel down-after-milliseconds` the time in `ms`
   ## that an unresponsive server is considered down.
   sentinel down-after-milliseconds gitlab-redis 10000

   ## Define a value for `sentinel failover_timeout` in `ms`. This has multiple
   ## meanings:
   ##
   ## * The time needed to re-start a failover after a previous failover was
   ##   already tried against the same primary by a given Sentinel, is two
   ##   times the failover timeout.
   ##
   ## * The time needed for a replica replicating to a wrong primary according
   ##   to a Sentinel current configuration, to be forced to replicate
   ##   with the right primary, is exactly the failover timeout (counting since
   ##   the moment a Sentinel detected the misconfiguration).
   ##
   ## * The time needed to cancel a failover that is already in progress but
   ##   did not produced any configuration change (REPLICAOF NO ONE yet not
   ##   acknowledged by the promoted replica).
   ##
   ## * The maximum time a failover in progress waits for all the replicas to be
   ##   reconfigured as replicas of the new primary. However even after this time
   ##   the replicas are reconfigured by the Sentinels anyway, but not with
   ##   the exact parallel-syncs progression as specified.
   sentinel failover_timeout 30000
   ```

1. 変更を有効にするには、Redisサービスを再起動します。
1. 他のすべてのSentinelノードについても、これらの手順を繰り返します。

### ステップ4.GitLabアプリケーションの設定 {#step-4-configuring-the-gitlab-application}

Sentinelサポートは、新規または既存のインストールでいつでも有効または無効にできます。GitLabアプリケーションの観点から見ると、必要なのはSentinelノードの正しい認証情報だけです。

すべてのSentinelノードのリストは必要ありませんが、フェイルオーバーが発生した場合、リストされているノードの少なくとも1つにアクセスする必要があります。

以下の手順は、RedisまたはSentinelが同じマシンにないことが理想的なGitLabアプリケーションサーバーで実行する必要があります:

1. [`resque.yml.example`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/resque.yml.example)の例に従って`/home/git/gitlab/config/resque.yml`を編集し、Sentinel行のコメントを解除して、正しいサーバー認証情報を指すようにします:

   ```yaml
   # resque.yaml
   production:
     url: redis://:redis-password-goes-here@gitlab-redis/
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

1. 変更を反映させるため、[GitLabを再起動](../restart_gitlab.md#self-compiled-installations)します。

## 1つのプライマリ、2つのレプリカ、3つのSentinelを持つ最小設定の例 {#example-of-minimal-configuration-with-1-primary-2-replicas-and-3-sentinels}

この例では、すべてのサーバーが`10.0.0.x`範囲のIPを持つ内部ネットワークインターフェースを持ち、これらのIPを使用して相互に接続できると仮定します。

実際の使用では、他のマシンからの不正アクセスを防ぐためのファイアウォールルールを設定し、外部からのトラフィック（[インターネット](https://gitlab.com/gitlab-org/gitlab-foss/uploads/c4cc8cd353604bd80315f9384035ff9e/The_Internet_IT_Crowd.png)）をブロックすることもあります。

この例では、**Sentinel 1**は**Redis Primary**と同じマシンに、**Sentinel 2**は**Replica 1**と同じマシンに、**Sentinel 3**は**Replica 2**と同じマシンに設定されています。

各**machine**とその割り当てられた**IP**のリストと説明は次のとおりです:

- `10.0.0.1`: Redisプライマリ + Sentinel 1
- `10.0.0.2`: Redis Replica 1 + Sentinel 2
- `10.0.0.3`: Redis Replica 2 + Sentinel 3
- `10.0.0.4`: GitLabアプリケーション

初期設定後、Sentinelノードによってフェイルオーバーが開始された場合、Redisノードは再設定され、新しいフェイルオーバーが再度開始されるまで、**プライマリ**は（`redis.conf`内を含め）あるノードから別のノードへ永続的に変更されます。

初期実行後、新しいSentinelノードが**プライマリ**の監視を開始した後、またはフェイルオーバーが異なる**プライマリ**ノードをプロモートした場合、`sentinel.conf`についても同じことが起こり、オーバーライドされます。

### RedisプライマリとSentinel 1の設定例 {#example-configuration-for-redis-primary-and-sentinel-1}

1. `/etc/redis/redis.conf`で次を行います:

   ```conf
   bind 10.0.0.1
   port 6379
   requirepass redis-password-goes-here
   masterauth redis-password-goes-here
   ```

1. `/etc/redis/sentinel.conf`で次を行います:

   ```conf
   bind 10.0.0.1
   port 26379
   sentinel auth-pass gitlab-redis redis-password-goes-here
   sentinel monitor gitlab-redis 10.0.0.1 6379 2
   sentinel down-after-milliseconds gitlab-redis 10000
   sentinel failover_timeout 30000
   ```

1. 変更を有効にするには、Redisサービスを再起動します。

### Redis Replica 1とSentinel 2の設定例 {#example-configuration-for-redis-replica-1-and-sentinel-2}

1. `/etc/redis/redis.conf`で次を行います:

   ```conf
   bind 10.0.0.2
   port 6379
   requirepass redis-password-goes-here
   masterauth redis-password-goes-here
   replicaof 10.0.0.1 6379
   ```

1. `/etc/redis/sentinel.conf`で次を行います:

   ```conf
   bind 10.0.0.2
   port 26379
   sentinel auth-pass gitlab-redis redis-password-goes-here
   sentinel monitor gitlab-redis 10.0.0.1 6379 2
   sentinel down-after-milliseconds gitlab-redis 10000
   sentinel failover_timeout 30000
   ```

1. 変更を有効にするには、Redisサービスを再起動します。

### Redis Replica 2とSentinel 3の設定例 {#example-configuration-for-redis-replica-2-and-sentinel-3}

1. `/etc/redis/redis.conf`で次を行います:

   ```conf
   bind 10.0.0.3
   port 6379
   requirepass redis-password-goes-here
   masterauth redis-password-goes-here
   replicaof 10.0.0.1 6379
   ```

1. `/etc/redis/sentinel.conf`で次を行います:

   ```conf
   bind 10.0.0.3
   port 26379
   sentinel auth-pass gitlab-redis redis-password-goes-here
   sentinel monitor gitlab-redis 10.0.0.1 6379 2
   sentinel down-after-milliseconds gitlab-redis 10000
   sentinel failover_timeout 30000
   ```

1. 変更を有効にするには、Redisサービスを再起動します。

### GitLabアプリケーションの設定例 {#example-configuration-of-the-gitlab-application}

1. `/home/git/gitlab/config/resque.yml`を編集します。

   ```yaml
   production:
     url: redis://:redis-password-goes-here@gitlab-redis/
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

1. 変更を反映させるため、[GitLabを再起動](../restart_gitlab.md#self-compiled-installations)します。

## トラブルシューティング {#troubleshooting}

[Redisトラブルシューティングガイド](troubleshooting.md)を参照してください。
