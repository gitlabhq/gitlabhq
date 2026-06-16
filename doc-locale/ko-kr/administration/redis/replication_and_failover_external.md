---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 자신의 Redis 인스턴스를 제공하여 Redis 복제 및 장애 조치
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

클라우드 공급자에서 GitLab을 호스팅하는 경우, Redis를 위한 관리형 서비스를 선택적으로 사용할 수 있습니다. 예를 들어, AWS는 Redis를 실행하는 ElastiCache를 제공합니다.

또는 Linux 패키지와 별도로 자신의 Redis 인스턴스를 관리할 수 있습니다.

## 요구 사항 {#requirements}

자신의 Redis 인스턴스를 제공하기 위한 요구 사항은 다음과 같습니다:

- [요구 사항 페이지](../../install/requirements.md)에서 필요한 최소 Redis 버전을 확인합니다.
- 독립 실행형 Redis 또는 Sentinel을 포함한 Redis 고가용성이 지원됩니다. Redis Cluster는 지원되지 않습니다.
- AWS ElastiCache와 같은 클라우드 공급자의 관리형 Redis는 정상적으로 작동합니다. 이러한 서비스에서 고가용성을 지원하는 경우, **not** Redis Cluster 유형이어야 합니다.

Redis 노드의 IP 주소 또는 호스트 이름, 포트 및 암호(필요한 경우)를 기록합니다.

## 클라우드 공급자의 관리형 서비스로서의 Redis {#redis-as-a-managed-service-in-a-cloud-provider}

1. [요구 사항](#requirements)에 따라 Redis를 설정합니다.
1. 외부 Redis 서비스에 대한 적절한 연결 세부 정보를 사용하여 `/etc/gitlab/gitlab.rb` 파일에서 GitLab 애플리케이션 서버를 구성합니다:

   단일 Redis 인스턴스를 사용하는 경우:

   ```ruby
   redis['enable'] = false

   gitlab_rails['redis_host'] = '<redis_instance_url>'
   gitlab_rails['redis_port'] = '<redis_instance_port>'

   # Required if Redis authentication is configured on the Redis node
   gitlab_rails['redis_password'] = '<redis_password>'

   # Set to true if instance is using Redis SSL
   gitlab_rails['redis_ssl'] = true
   ```

   별도의 Redis 캐시 및 영구 인스턴스를 사용하는 경우:

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

1. 변경 사항을 적용하도록 다시 구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### 제거 정책 설정 {#setting-the-eviction-policy}

단일 Redis 인스턴스를 실행할 때는 제거 정책을 `noeviction`로 설정해야 합니다.

별도의 Redis 캐시 및 영구 인스턴스를 실행하는 경우, 캐시는 [Least Recently Used 캐시](https://redis.io/docs/latest/operate/rs/databases/memory-performance/eviction-policy/)(LRU)로 `allkeys-lru`를 사용하여 구성되어야 하며 영구는 `noeviction`로 설정되어야 합니다.

이를 구성하는 것은 클라우드 공급자 또는 서비스에 따라 다르지만, 일반적으로 다음 설정 및 값이 캐시를 구성합니다:

- `maxmemory-policy` = `allkeys-lru`
- `maxmemory-samples` = `5`

## 자신의 Redis 서버를 사용한 Redis 복제 및 장애 조치 {#redis-replication-and-failover-with-your-own-redis-servers}

이것은 Linux 패키지와 함께 제공되는 번들 Redis를 사용하지 않고 자신이 Redis를 모두 설치했을 때 확장 가능한 Redis 설정을 구성하기 위한 설명서입니다. 하지만 우리는 GitLab을 위해 이들을 특별히 최적화하고 Redis를 최신 지원 버전으로 업그레이드하므로 Linux 패키지를 사용하는 것이 매우 권장됩니다.

`/home/git/gitlab/config/resque.yml`에 대한 모든 참조를 재정의하도록 선택할 수 있습니다. [구성 파일 설명서](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/README.md)에 설명된 고급 Redis 설정에 따릅니다.

Linux 패키지 Redis HA의 [복제 및 장애 조치](replication_and_failover.md) 설명서를 읽는 것의 중요성을 강조할 수 없습니다. Redis 구성에 귀중한 정보를 제공하기 때문입니다. 이 가이드를 진행하기 전에 읽으십시오.

새 Redis 인스턴스 설정을 진행하기 전에 다음과 같은 요구 사항이 있습니다:

- 이 가이드의 모든 Redis 서버는 소켓 대신 TCP 연결을 사용하도록 구성되어야 합니다. Redis가 TCP 연결을 사용하도록 구성하려면 Redis 구성 파일에서 `bind` 및 `port`를 모두 정의해야 합니다. 모든 인터페이스(`0.0.0.0`)에 바인드하거나 원하는 인터페이스의 IP를 지정할 수 있습니다(예: 내부 네트워크의 IP).
- Redis 3.2 이후로는 외부 연결을 수신하기 위해 암호를 정의해야 합니다(`requirepass`).
- Sentinel과 함께 Redis를 사용하는 경우, 같은 인스턴스에서 복제 암호 정의(`masterauth`)에 동일한 암호를 정의해야 합니다.

추가로, [Linux 패키지를 사용한 Redis 복제 및 장애 조치](replication_and_failover.md#requirements)에서 설명한 필수 조건을 읽으십시오.

### 1단계. 프라이머리 Redis 인스턴스 구성 {#step-1-configuring-the-primary-redis-instance}

Redis 프라이머리 인스턴스 IP가 `10.0.0.1`라고 가정합니다:

1. [Redis 설치](../../install/self_compiled/_index.md#8-redis).
1. `/etc/redis/redis.conf`을 편집하세요:

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

1. 변경 사항을 적용하려면 Redis 서비스를 다시 시작합니다.

### 2단계. 레플리카 Redis 인스턴스 구성 {#step-2-configuring-the-replica-redis-instances}

Redis 복제 인스턴스 IP가 `10.0.0.2`라고 가정합니다:

1. [Redis 설치](../../install/self_compiled/_index.md#8-redis).
1. `/etc/redis/redis.conf`을 편집하세요:

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

1. 변경 사항을 적용하려면 Redis 서비스를 다시 시작합니다.
1. 다른 모든 레플리카 노드에 대해 단계를 다시 진행하세요.

### 3단계. Redis Sentinel 인스턴스 구성 {#step-3-configuring-the-redis-sentinel-instances}

Sentinel은 특별한 유형의 Redis 서버입니다. `redis.conf`에서 정의할 수 있는 대부분의 기본 구성 옵션을 상속하며, `sentinel` 접두사로 시작하는 특정 옵션이 있습니다.

Redis Sentinel이 IP `10.0.0.1`인 Redis 프라이머리와 동일한 인스턴스에 설치되어 있다고 가정합니다(일부 설정은 프라이머리와 겹칠 수 있음):

1. [Redis Sentinel 설치](https://redis.io/docs/latest/operate/oss_and_stack/management/sentinel/).
1. `/etc/redis/sentinel.conf`을 편집하세요:

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

1. 변경 사항을 적용하려면 Redis 서비스를 다시 시작합니다.
1. 다른 모든 Sentinel 노드에 대해 단계를 다시 진행하세요.

### 4단계. GitLab 애플리케이션 구성 {#step-4-configuring-the-gitlab-application}

새로운 또는 기존 설치에서 언제든지 Sentinel 지원을 활성화하거나 비활성화할 수 있습니다. GitLab 애플리케이션 관점에서 필요한 것은 Sentinel 노드에 대한 올바른 자격 증명입니다.

모든 Sentinel 노드의 목록이 필요하지는 않지만, 장애 발생 시 나열된 노드 중 최소한 하나에 액세스해야 합니다.

다음 단계는 이상적으로 Redis 또는 Sentinel이 동일한 머신에 있지 않아야 하는 GitLab 애플리케이션 서버에서 수행됩니다:

1. `/home/git/gitlab/config/resque.yml`을 [`resque.yml.example`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/resque.yml.example)의 예제에 따라 편집하고 Sentinel 줄의 주석을 제거하며 올바른 서버 자격 증명을 가리킵니다:

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

1. [GitLab 다시 시작](../restart_gitlab.md#self-compiled-installations) 변경 사항을 적용합니다.

## 1개의 프라이머리, 2개의 복제 및 3개의 Sentinel을 사용한 최소 구성의 예 {#example-of-minimal-configuration-with-1-primary-2-replicas-and-3-sentinels}

이 예에서는 모든 서버에 `10.0.0.x` 범위의 IP를 가진 내부 네트워크 인터페이스가 있고 이러한 IP를 사용하여 서로 연결할 수 있다고 가정합니다.

실제 사용에서는 방화벽 규칙을 설정하여 다른 머신의 무단 액세스를 방지하고 외부([인터넷](https://gitlab.com/gitlab-org/gitlab-foss/uploads/c4cc8cd353604bd80315f9384035ff9e/The_Internet_IT_Crowd.png))의 트래픽을 차단합니다.

이 예에서, **Sentinel 1**은 **Redis Primary**와 동일한 머신에 구성되고, **Sentinel 2**는 **Replica 1**과 동일한 머신에 있으며, **Sentinel 3**은 **Replica 2**와 동일한 머신에 있습니다.

각 **machine**과 할당된 **IP**에 대한 목록과 설명은 다음과 같습니다:

- `10.0.0.1`:  Redis 프라이머리 + Sentinel 1
- `10.0.0.2`:  Redis 레플리카 1 + Sentinel 2
- `10.0.0.3`:  Redis 레플리카 2 + Sentinel 3
- `10.0.0.4`:  GitLab 애플리케이션

초기 구성 후 Sentinel 노드에 의해 장애 조치가 시작되면 Redis 노드가 다시 구성되고 **프라이머리**는 `redis.conf`에서 한 노드에서 다른 노드로 영구적으로 변경되며, 새 장애 조치가 다시 시작될 때까지 유지됩니다.

동일한 상황이 `sentinel.conf`에서도 발생합니다. 초기 실행 후 재정의되며, 새 sentinel 노드가 **프라이머리**를 감시하기 시작할 때 또는 장애 조치가 다른 **프라이머리** 노드를 승격할 때입니다.

### Redis 프라이머리 및 Sentinel 1을 위한 구성 예 {#example-configuration-for-redis-primary-and-sentinel-1}

1. `/etc/redis/redis.conf`에서:

   ```conf
   bind 10.0.0.1
   port 6379
   requirepass redis-password-goes-here
   masterauth redis-password-goes-here
   ```

1. `/etc/redis/sentinel.conf`에서:

   ```conf
   bind 10.0.0.1
   port 26379
   sentinel auth-pass gitlab-redis redis-password-goes-here
   sentinel monitor gitlab-redis 10.0.0.1 6379 2
   sentinel down-after-milliseconds gitlab-redis 10000
   sentinel failover_timeout 30000
   ```

1. 변경 사항을 적용하려면 Redis 서비스를 다시 시작합니다.

### Redis 레플리카 1 및 Sentinel 2를 위한 구성 예 {#example-configuration-for-redis-replica-1-and-sentinel-2}

1. `/etc/redis/redis.conf`에서:

   ```conf
   bind 10.0.0.2
   port 6379
   requirepass redis-password-goes-here
   masterauth redis-password-goes-here
   replicaof 10.0.0.1 6379
   ```

1. `/etc/redis/sentinel.conf`에서:

   ```conf
   bind 10.0.0.2
   port 26379
   sentinel auth-pass gitlab-redis redis-password-goes-here
   sentinel monitor gitlab-redis 10.0.0.1 6379 2
   sentinel down-after-milliseconds gitlab-redis 10000
   sentinel failover_timeout 30000
   ```

1. 변경 사항을 적용하려면 Redis 서비스를 다시 시작합니다.

### Redis 레플리카 2 및 Sentinel 3을 위한 구성 예 {#example-configuration-for-redis-replica-2-and-sentinel-3}

1. `/etc/redis/redis.conf`에서:

   ```conf
   bind 10.0.0.3
   port 6379
   requirepass redis-password-goes-here
   masterauth redis-password-goes-here
   replicaof 10.0.0.1 6379
   ```

1. `/etc/redis/sentinel.conf`에서:

   ```conf
   bind 10.0.0.3
   port 26379
   sentinel auth-pass gitlab-redis redis-password-goes-here
   sentinel monitor gitlab-redis 10.0.0.1 6379 2
   sentinel down-after-milliseconds gitlab-redis 10000
   sentinel failover_timeout 30000
   ```

1. 변경 사항을 적용하려면 Redis 서비스를 다시 시작합니다.

### GitLab 애플리케이션의 예제 구성 {#example-configuration-of-the-gitlab-application}

1. `/home/git/gitlab/config/resque.yml`을 편집하세요:

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

1. [GitLab 다시 시작](../restart_gitlab.md#self-compiled-installations) 변경 사항을 적용합니다.

## 문제 해결 {#troubleshooting}

[Redis 문제 해결 가이드](troubleshooting.md)를 참조하세요.
