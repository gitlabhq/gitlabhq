---
stage: Data access
group: Durability
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Redisのレプリケーションとフェイルオーバーにより、独自のインスタンスを提供します
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabをクラウドプロバイダーでホストしている場合、オプションでRedisのマネージドサービスを使用できます。たとえば、AWSはRedisを実行するElastiCacheを提供しています。

または、Linuxパッケージとは別に、独自のRedisインスタンスを管理することもできます。

## 要件 {#requirements}

以下は、独自のRedisインスタンスを提供するための要件です:

- [要件ページ](../../install/requirements.md)で必要なRedisの最小バージョンを確認してください。
- スタンドアロンRedisまたはSentinelによるRedisHigh Availabilityがサポートされています。Redisクラスターはサポートされていません。
- AWS ElastiCacheなどのクラウドプロバイダーからのマネージドRedisは正常に動作します。これらのサービスがHigh Availabilityをサポートしている場合は、Redisクラスタータイプ**ではない**ことを確認してください。

RedisノードのIPアドレスまたはホスト名、ポート、およびパスワード（必要な場合）をメモしておきます。

## クラウドプロバイダーでのマネージドサービスとしてのRedis {#redis-as-a-managed-service-in-a-cloud-provider}

1. [要件](#requirements)に従ってRedisを設定します。
1. `/etc/gitlab/gitlab.rb`ファイルで、外部Redisサービスのための適切な接続詳細でGitLabアプリケーションサーバーを設定します:

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

   個別のRedisキャッシュと永続的なインスタンスを使用する場合:

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

1. 変更を有効にするには、再構成してください:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### 削除ポリシーの設定 {#setting-the-eviction-policy}

単一のRedisインスタンスを実行している場合、削除ポリシーは`noeviction`に設定する必要があります。

個別のRedisキャッシュと永続的なインスタンスを実行している場合、キャッシュは[Least Recently Used cache](https://redis.io/docs/latest/operate/rs/databases/memory-performance/eviction-policy/)（LRU）として`allkeys-lru`で設定し、永続的は`noeviction`に設定する必要があります。

この設定はクラウドプロバイダーまたはサービスによって異なりますが、一般的に次の設定と値はキャッシュを設定します:

- `maxmemory-policy` = `allkeys-lru`
- `maxmemory-samples` = `5`

## 独自のRedisサーバーによるRedisレプリケーションとフェイルオーバー {#redis-replication-and-failover-with-your-own-redis-servers}

これは、Linuxパッケージに付属しているバンドルを使用せずに、Redisを自分でインストールした場合にスケーラブルなRedis設定を構成するためのドキュメントです。ただし、Linuxパッケージを使用すると、GitLab用に最適化され、サポートされている最新バージョンにRedisをアップグレードするため、強くお勧めします。

また、[設定ファイルドキュメント](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/README.md)に概説されている高度なRedis設定に従って、`/home/git/gitlab/config/resque.yml`へのすべての参照をオーバーライドすることもできます。

LinuxパッケージRedis HAの[レプリケーションとフェイルオーバー](replication_and_failover.md)に関するドキュメントを読むことの重要性をいくら強調してもしすぎることはありません。これはRedisの設定に非常に貴重な情報を提供するからです。このガイドに進む前に読んでください。

新しいRedisインスタンスのセットアップに進む前に、いくつかの要件を以下に示します:

- このガイドのすべてのRedisサーバーは、ソケットの代わりにTCP接続を使用するように設定する必要があります。TCP接続を使用するようにRedisを設定するには、Redis設定ファイルで`bind`と`port`の両方を定義する必要があります。すべてのインターフェース（`0.0.0.0`）にバインドするか、目的のインターフェースのIP（たとえば、内部ネットワークからのもの）を指定できます。
- Redis 3.2以降では、外部接続を受信するにはパスワード（`requirepass`）を定義する必要があります。
- RedisとSentinelを使用している場合は、同じインスタンス内のレプリカパスワード定義（`masterauth`）にも同じパスワードを定義する必要があります。

さらに、[Linuxパッケージを使用したRedisレプリケーションとフェイルオーバー](replication_and_failover.md#requirements)で説明されている前提条件をお読みください。

### ステップ1.プライマリRedisインスタンスの設定 {#step-1-configuring-the-primary-redis-instance}

RedisプライマリインスタンスのIPが`10.0.0.1`であると仮定します:

1. [Redisをインストール](../../install/self_compiled/_index.md#8-redis)。
1. `/etc/redis/redis.conf`を編集します: 

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

1. [Redisをインストール](../../install/self_compiled/_index.md#8-redis)。
1. `/etc/redis/redis.conf`を編集します: 

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
1. 他のすべてのレプリカノードに対して、手順を繰り返します。

### ステップ3.Redis Sentinelインスタンスの設定 {#step-3-configuring-the-redis-sentinel-instances}

Sentinelは、特別なタイプのRedisサーバーです。これは、`redis.conf`で定義できる基本的な設定オプションのほとんどを継承し、特定のオプションは`sentinel`のプレフィックスで始まります。

Redis Sentinelが、IP `10.0.0.1`を持つRedisプライマリと同じインスタンスにインストールされていると仮定します（一部の設定はプライマリとオーバーラップする可能性があります）:

1. [Redis Sentinelをインストール](https://redis.io/docs/latest/operate/oss_and_stack/management/sentinel/)。
1. `/etc/redis/sentinel.conf`を編集します: 

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
1. 他のすべてのSentinelノードに対して、手順を繰り返します。

### ステップ4.GitLabアプリケーションの設定 {#step-4-configuring-the-gitlab-application}

新規または既存のインストールで、Sentinelサポートをいつでも有効または無効にできます。GitLabアプリケーションの観点からは、必要なのはSentinelノードの正しい認証情報だけです。

すべてのSentinelノードのリストは必要ありませんが、フェイルオーバーが発生した場合に、リストされている少なくとも1つにアクセスする必要があります。

次の手順は、理想的には同じマシンにRedisまたはSentinelがないGitLabアプリケーションサーバーで実行する必要があります:

1. [`resque.yml.example`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/resque.yml.example)の例に従って`/home/git/gitlab/config/resque.yml`を編集し、正しいサーバー認証情報を指すSentinel行のコメントを外します:

   ```yaml
   # resque.yaml
   production:
   url: `redis://:redis-password-goes-here@gitlab-redis/`
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

## プライマリ1つ、レプリカ2つ、Sentinel3つによる最小設定の例 {#example-of-minimal-configuration-with-1-primary-2-replicas-and-3-sentinels}

この例では、すべてのサーバーに`10.0.0.x`の範囲のIPを持つ内部ネットワークインターフェースがあり、これらのIPを使用して相互に接続できることを前提としています。

実際の使用では、他のマシンからの不正アクセスを防ぐためにファイアウォールルールを設定し、外部からのトラフィック（[インターネット](https://gitlab.com/gitlab-org/gitlab-foss/uploads/c4cc8cd353604bd80315f9384035ff9e/The_Internet_IT_Crowd.png)）をブロックします。

この例では、**Sentinel 1**は**Redis Primary**（Redisプライマリ）と同じマシンに、**Sentinel 2**は**Replica 1**（レプリカ1）と同じマシンに、**Sentinel 3**は**Replica 2**（レプリカ2）と同じマシンに設定されています。

各**machine**（マシン）と割り当てられた**IP**のリストと説明を次に示します:

- `10.0.0.1`: Redisプライマリ+ Sentinel 1
- `10.0.0.2`: Redisレプリカ1 + Sentinel 2
- `10.0.0.3`: Redisレプリカ2 + Sentinel 3
- `10.0.0.4`: GitLabアプリケーション

初期設定後、Sentinelノードによってフェイルオーバーが開始された場合、Redisノードは再設定され、新しいフェイルオーバーが再度開始されるまで、**プライマリ**は（`redis.conf`を含む）あるノードから別のノードに完全に変更されます。

新しいSentinelノードが**プライマリ**の監視を開始した後、またはフェイルオーバーが別の**プライマリ**ノードをプロモートした後、初期実行後にオーバーライドされる`sentinel.conf`でも同じことが起こります。

### RedisプライマリおよびSentinel 1の設定例 {#example-configuration-for-redis-primary-and-sentinel-1}

1. `/etc/redis/redis.conf`で:

   ```conf
   bind 10.0.0.1
   port 6379
   requirepass redis-password-goes-here
   masterauth redis-password-goes-here
   ```

1. `/etc/redis/sentinel.conf`で:

   ```conf
   bind 10.0.0.1
   port 26379
   sentinel auth-pass gitlab-redis redis-password-goes-here
   sentinel monitor gitlab-redis 10.0.0.1 6379 2
   sentinel down-after-milliseconds gitlab-redis 10000
   sentinel failover_timeout 30000
   ```

1. 変更を有効にするには、Redisサービスを再起動します。

### Redisレプリカ1およびSentinel 2の設定例 {#example-configuration-for-redis-replica-1-and-sentinel-2}

1. `/etc/redis/redis.conf`で:

   ```conf
   bind 10.0.0.2
   port 6379
   requirepass redis-password-goes-here
   masterauth redis-password-goes-here
   replicaof 10.0.0.1 6379
   ```

1. `/etc/redis/sentinel.conf`で:

   ```conf
   bind 10.0.0.2
   port 26379
   sentinel auth-pass gitlab-redis redis-password-goes-here
   sentinel monitor gitlab-redis 10.0.0.1 6379 2
   sentinel down-after-milliseconds gitlab-redis 10000
   sentinel failover_timeout 30000
   ```

1. 変更を有効にするには、Redisサービスを再起動します。

### Redisレプリカ2およびSentinel 3の設定例 {#example-configuration-for-redis-replica-2-and-sentinel-3}

1. `/etc/redis/redis.conf`で:

   ```conf
   bind 10.0.0.3
   port 6379
   requirepass redis-password-goes-here
   masterauth redis-password-goes-here
   replicaof 10.0.0.1 6379
   ```

1. `/etc/redis/sentinel.conf`で:

   ```conf
   bind 10.0.0.3
   port 26379
   sentinel auth-pass gitlab-redis redis-password-goes-here
   sentinel monitor gitlab-redis 10.0.0.1 6379 2
   sentinel down-after-milliseconds gitlab-redis 10000
   sentinel failover_timeout 30000
   ```

1. 変更を有効にするには、Redisサービスを再起動します。

### GitLabアプリケーションの設定の例 {#example-configuration-of-the-gitlab-application}

1. `/home/git/gitlab/config/resque.yml`を編集します: 

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
