---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Linux 패키지를 사용한 Redis 복제 및 장애 조치
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

이 설명서는 Linux 패키지용입니다. 자체 번들로 제공되지 않은 Redis를 사용하려면 [Redis 복제 및 장애 조치 - 자체 인스턴스 제공](replication_and_failover_external.md)을 참조하세요.

Redis 용어에서 `primary`은 `master`라고 부릅니다. 이 문서에서는 `primary`을 `master` 대신 사용하며, `master`이 필요한 설정은 제외합니다.

[Redis](https://redis.io/)를 확장 가능한 환경에서 사용하려면 **프라이머리** x **Replica** 토폴로지와 장애 조치 절차를 감시하고 자동으로 시작하는 [Redis Sentinel](https://redis.io/docs/latest/operate/oss_and_stack/management/sentinel/) 서비스를 사용할 수 있습니다.

Sentinel과 함께 사용하면 Redis는 인증이 필요합니다. [Redis 보안](https://redis.io/docs/latest/operate/rc/security/) 설명서를 참조하세요. Redis 서비스를 보호하려면 Redis 비밀번호와 엄격한 방화벽 규칙의 조합을 사용하는 것을 권장합니다. GitLab으로 Redis를 구성하기 전에 토폴로지와 아키텍처를 완전히 이해하기 위해 [Redis Sentinel](https://redis.io/docs/latest/operate/oss_and_stack/management/sentinel/) 설명서를 읽어보시기를 강력히 권장합니다.

복제 토폴로지를 위해 Redis 및 Redis Sentinel을 설정하는 방법의 세부 사항을 다루기 전에 이 문서를 한 번 전체적으로 읽어서 구성 요소가 어떻게 연결되어 있는지 더 잘 이해하세요.

최소 `3`개의 독립적인 머신이 필요합니다: 물리적 머신 또는 서로 다른 물리적 머신에서 실행되는 VM입니다. 모든 프라이머리 및 레플리카 Redis 인스턴스가 서로 다른 머신에서 실행되어야 합니다. 머신을 이런 특정 방식으로 프로비저닝하지 못하면 공유 환경의 모든 이슈로 인해 전체 설정이 중단될 수 있습니다.

프라이머리 또는 레플리카 Redis 인스턴스와 함께 Sentinel을 실행해도 괜찮습니다. 같은 머신에는 두 개 이상의 Sentinel이 없어야 합니다.

기본 네트워크 토폴로지를 고려하여 Redis / Sentinel과 GitLab 인스턴스 간의 중복 연결이 있는지 확인해야 하며, 그렇지 않으면 네트워크가 단일 장애 지점이 됩니다.

확장 환경에서 Redis를 실행하려면 몇 가지가 필요합니다:

- 여러 Redis 인스턴스
- Redis를 **프라이머리** x **Replica** 토폴로지에서 실행합니다
- 여러 Sentinel 인스턴스
- 모든 Sentinel 및 Redis 인스턴스에 대한 애플리케이션 지원 및 가시성

Redis Sentinel은 HA 환경에서 가장 중요한 작업을 처리할 수 있으며, 최소한의 가동 중지 시간으로 서버를 온라인 상태로 유지하는 데 도움이 됩니다. Redis Sentinel:

- **프라이머리** 및 **Replicas** 인스턴스를 모니터링하여 사용 가능한지 확인합니다
- **프라이머리**가 실패할 때 **Replica**를 **프라이머리**로 승격합니다
- 실패한 **프라이머리**가 다시 온라인 상태가 되면 **프라이머리**를 **Replica**로 강등합니다(데이터 분할 방지)
- 애플리케이션에서 쿼리하여 항상 현재 **프라이머리** 서버에 연결할 수 있습니다

**프라이머리**가 응답하지 못할 때, 새 **프라이머리**에 대해 **Sentinel**을 쿼리하여 타임아웃을 처리하고 다시 연결하는 것은 애플리케이션(이 경우 GitLab)의 책임입니다.

Sentinel을 올바르게 설정하는 방법을 더 잘 이해하려면 [Redis Sentinel](https://redis.io/docs/latest/operate/oss_and_stack/management/sentinel/) 설명서를 먼저 읽으세요. 잘못 구성하면 데이터 손실이 발생하거나 전체 클러스터가 중단되어 장애 조치 노력이 무효화될 수 있습니다.

## 권장 설정 {#recommended-setup}

최소 설정을 위해 Linux 패키지를 `3`개의 **independent** 머신에 설치해야 하며, 둘 다 **Redis** 및 **Sentinel**을 포함해야 합니다:

- Redis 프라이머리 + Sentinel
- Redis 레플리카 + Sentinel
- Redis 레플리카 + Sentinel

노드의 개수와 위치가 확실하지 않거나 이해가 안 되면 [Redis 설정 개요](#redis-setup-overview) 와 [Sentinel 설정 개요](#sentinel-setup-overview)를 참조하세요.

더 많은 장애를 견딜 수 있는 권장 설정을 위해 Linux 패키지를 `5`개의 **independent** 머신에 설치해야 하며, 둘 다 **Redis** 및 **Sentinel**을 포함해야 합니다:

- Redis 프라이머리 + Sentinel
- Redis 레플리카 + Sentinel
- Redis 레플리카 + Sentinel
- Redis 레플리카 + Sentinel
- Redis 레플리카 + Sentinel

### Redis 설정 개요 {#redis-setup-overview}

최소 `3`개의 Redis 서버가 필요합니다: `1`개의 프라이머리, `2`개의 레플리카이며, 이들은 각각 독립적인 머신에 있어야 합니다.

추가 Redis 노드가 있으면 더 많은 노드가 다운되는 상황을 견디는 데 도움이 됩니다. 온라인 노드가 `2`개만 있을 때는 장애 조치가 시작되지 않습니다.

예를 들어 Redis 노드가 `6`개 있으면 최대 `3`개가 동시에 다운될 수 있습니다.

Sentinel 노드에는 다른 요구 사항이 있습니다. 동일한 Redis 머신에 호스팅하면 프로비저닝할 노드 수를 계산할 때 해당 제한을 고려해야 할 수 있습니다. [Sentinel 설정 개요](#sentinel-setup-overview) 설명서를 참조하세요.

모든 Redis 노드는 동일한 방식으로 구성되어야 하며 유사한 서버 사양을 갖추어야 하므로, 장애 조치 상황에서 모든 **Replica**는 Sentinel 서버에 의해 새로운 **프라이머리**로 승격될 수 있습니다.

복제에는 인증이 필요하므로 모든 Redis 노드와 Sentinel을 보호하기 위해 비밀번호를 정의해야 합니다. 모두 동일한 비밀번호를 공유하며, 모든 인스턴스는 네트워크를 통해 서로 통신할 수 있어야 합니다.

### Sentinel 설정 개요 {#sentinel-setup-overview}

Sentinel은 다른 Sentinel과 Redis 노드를 모니터링합니다. Sentinel이 Redis 노드가 응답하지 않는 것을 감지하면 노드의 상태를 다른 Sentinel에 알립니다. Sentinel은 _쿼럼_(노드가 다운되었다는 데 동의하는 최소 Sentinel 수)에 도달해야 장애 조치를 시작할 수 있습니다.

**quorum**이 충족되면 알려진 모든 Sentinel 노드의 **majority**가 사용 가능하고 도달 가능해야 하므로 Sentinel **leader**를 선출하여 다음과 같이 서비스 가용성을 복구하기 위한 모든 결정을 내릴 수 있습니다:

- 새로운 **프라이머리** 승격
- 다른 **Replicas**를 다시 구성하고 새로운 **프라이머리**를 가리키도록 합니다
- 새로운 **프라이머리**를 모든 다른 Sentinel 피어에 알립니다
- 이전 **프라이머리**를 다시 구성하고 온라인 상태가 되면 **Replica**로 강등합니다

최소 `3`개의 Redis Sentinel 서버가 필요하며, 각각은 독립적인 머신(독립적으로 실패한다고 예상되는)에 있어야 하며, 이상적으로는 다른 지리적 영역에 있어야 합니다.

다른 Redis 서버를 구성한 동일한 머신에 구성할 수 있지만, 전체 노드가 다운되면 Sentinel과 Redis 인스턴스가 모두 손실된다는 점을 이해해야 합니다.

sentinel의 개수는 이상적으로 항상 **odd**여야 장애 발생 시 합의 알고리즘이 효과적입니다.

`3`개 노드 토폴로지에서는 Sentinel 노드가 `1`개만 다운될 수 있습니다. Sentinel의 **majority**가 다운되면 네트워크 분할 보호가 파괴적인 작업을 방지하고 장애 조치가 **is not started**.

몇 가지 예를 들면:

- `5`개 또는 `6`개의 sentinel이 있으면 장애 조치가 시작되려면 최대 `2`개가 다운될 수 있습니다.
- `7`개의 sentinel이 있으면 최대 `3`개 노드가 다운될 수 있습니다.

**Leader** 선출은 **consensus**가 달성되지 않으면 투표 라운드에 실패할 수 있습니다. 이 경우 `sentinel['failover_timeout']`(밀리초 단위)에 정의된 시간 후에 새로운 시도가 이루어집니다.

> [!note]
> `sentinel['failover_timeout']`이 정의된 위치를 볼 수 있습니다.

`failover_timeout` 변수는 많은 서로 다른 사용 사례가 있습니다. 공식 설명서에 따르면:

- 특정 Sentinel에 의해 동일한 프라이머리에 대해 이전 장애 조치가 이미 시도된 후 장애 조치를 다시 시작하는 데 필요한 시간은 장애 조치 타임아웃의 2배입니다.

- Sentinel의 현재 구성에 따라 잘못된 프라이머리에 복제하는 레플리카가 올바른 프라이머리로 복제하도록 강제되는 데 필요한 시간은 정확히 장애 조치 타임아웃입니다(Sentinel이 잘못된 구성을 감지한 순간부터 계산).

- 진행 중인 장애 조치를 취소하는 데 필요한 시간으로, 아직 구성 변경이 이루어지지 않았습니다(아직 승격된 레플리카에서 인정하지 않은 REPLICAOF NO ONE).

- 진행 중인 장애 조치가 모든 레플리카가 새로운 프라이머리의 레플리카로 다시 구성될 때까지 기다리는 최대 시간입니다. 그러나 이 시간이 지난 후에도 레플리카는 여전히 Sentinel에 의해 다시 구성되지만 지정된 정확한 parallel-syncs 진행 상황이 아닙니다.

## Redis 구성 {#configuring-redis}

이는 새 Redis 인스턴스를 설치하고 설정하는 섹션입니다.

GitLab과 모든 구성 요소를 처음부터 설치했다고 가정합니다. 이미 Redis가 설치되어 있고 실행 중인 경우 [단일 머신 설치에서 전환하는 방법](#switching-from-an-existing-single-machine-installation)을 참조하세요.

> [!note]
> Redis 노드(프라이머리 및 레플리카 모두)는 `redis['password']`에 정의된 동일한 비밀번호가 필요합니다. 장애 조치 중 언제든지 Sentinel은 노드를 다시 구성하고 프라이머리에서 레플리카로, 또는 그 반대로 상태를 변경할 수 있습니다.

### 요구 사항 {#requirements}

Redis 설정의 요구 사항은 다음과 같습니다:

1. [권장 설정](#recommended-setup) 섹션에 지정된 대로 필요한 최소 인스턴스 수를 프로비저닝합니다.
1. Redis 또는 Redis Sentinel을 GitLab 애플리케이션이 실행 중인 동일한 머신에 설치하는 것은 **Do not**. 이는 HA 구성을 약화시킵니다. 그러나 Redis와 Sentinel을 동일한 머신에 설치하도록 선택할 수 있습니다.
1. 모든 Redis 노드는 Redis(`6379`) 및 Sentinel(`26379`) 포트를 통해 서로 통신할 수 있고 수신 연결을 허용해야 합니다(기본값을 변경하지 않는 한).
1. GitLab 애플리케이션을 호스팅하는 서버는 Redis 노드에 액세스할 수 있어야 합니다.
1. 외부 네트워크([인터넷](https://gitlab.com/gitlab-org/gitlab-foss/uploads/c4cc8cd353604bd80315f9384035ff9e/The_Internet_IT_Crowd.png))에서의 접근으로부터 노드를 보호하고 방화벽을 사용하세요.

### 기존 단일 머신 설치에서 전환 {#switching-from-an-existing-single-machine-installation}

이미 단일 머신 GitLab 설치가 실행 중인 경우 먼저 이 머신에서 복제한 후 내부의 Redis 인스턴스를 비활성화해야 합니다.

단일 머신 설치는 초기 **프라이머리**이며, `3`개의 다른 설치는 이 머신을 가리키도록 **Replica**로 구성되어야 합니다.

복제가 따라잡은 후 단일 머신 설치에서 서비스를 중지하여 **프라이머리**를 새 노드 중 하나로 회전합니다.

구성에서 필요한 변경을 한 다음 새 노드를 다시 시작하세요.

단일 설치에서 Redis를 비활성화하려면 `/etc/gitlab/gitlab.rb`을 편집하세요:

```ruby
redis['enable'] = false
```

먼저 복제하지 못하면 데이터(처리되지 않은 백그라운드 작업)가 손실될 수 있습니다.

### 1단계. 프라이머리 Redis 인스턴스 구성 {#step-1-configuring-the-primary-redis-instance}

1. **프라이머리** Redis 서버에 SSH로 연결하세요.
1. [Linux 패키지 다운로드 및 설치](https://about.gitlab.com/install/) \- GitLab 다운로드 페이지에서 **steps 1 and 2**를 사용하여 원하는 패키지를 설치하세요.
   - 현재 설치와 동일한 버전 및 유형(Community, Enterprise 에디션)의 올바른 Linux 패키지를 선택했는지 확인하세요.
   - 다운로드 페이지에서 다른 단계를 완료하지 마세요.

1. `/etc/gitlab/gitlab.rb`을 편집하고 내용을 추가합니다:

   ```ruby
   # Specify server role as 'redis_master_role'
   roles ['redis_master_role']

   # IP address pointing to a local IP that the other machines can reach to.
   # You can also set bind to '0.0.0.0' which listen in all interfaces.
   # If you really need to bind to an external accessible IP, make
   # sure you add extra firewall rules to prevent unauthorized access.
   redis['bind'] = '10.0.0.1'

   # Define a port so Redis can listen for TCP requests which allows other
   # machines to connect to it.
   redis['port'] = 6379

   # Set up password authentication for Redis (use the same password in all nodes).
   redis['password'] = 'redis-password-goes-here'
   ```

1. 프라이머리 GitLab 애플리케이션 서버만 마이그레이션을 처리해야 합니다. 업그레이드 시 데이터베이스 마이그레이션이 실행되지 않도록 하려면 `/etc/gitlab/gitlab.rb` 파일에 다음 구성을 추가하세요:

   ```ruby
   gitlab_rails['auto_migrate'] = false
   ```

1. 변경 사항이 적용되려면 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행합니다.

> [!note]
> sentinel 및 Redis 같은 여러 역할을 지정할 수 있습니다: `roles ['redis_sentinel_role', 'redis_master_role']`. [역할](https://docs.gitlab.com/omnibus/roles/)에 대해 자세히 알아보세요.

### 2단계. 레플리카 Redis 인스턴스 구성 {#step-2-configuring-the-replica-redis-instances}

1. **replica** Redis 서버에 SSH로 연결하세요.
1. [Linux 패키지 다운로드 및 설치](https://about.gitlab.com/install/) \- GitLab 다운로드 페이지에서 **steps 1 and 2**를 사용하여 원하는 패키지를 설치하세요.
   - 현재 설치와 동일한 버전 및 유형(Community, Enterprise 에디션)의 올바른 Linux 패키지를 선택했는지 확인하세요.
   - 다운로드 페이지에서 다른 단계를 완료하지 마세요.

1. `/etc/gitlab/gitlab.rb`을 편집하고 내용을 추가합니다:

   ```ruby
   # Specify server role as 'redis_replica_role'
   roles ['redis_replica_role']

   # IP address pointing to a local IP that the other machines can reach to.
   # You can also set bind to '0.0.0.0' which listen in all interfaces.
   # If you really need to bind to an external accessible IP, make
   # sure you add extra firewall rules to prevent unauthorized access.
   redis['bind'] = '10.0.0.2'

   # Define a port so Redis can listen for TCP requests which allows other
   # machines to connect to it.
   redis['port'] = 6379

   # The same password for Redis authentication you set up for the primary node.
   redis['password'] = 'redis-password-goes-here'

   # The IP of the primary Redis node.
   redis['master_ip'] = '10.0.0.1'

   # Port of primary Redis server, uncomment to change to non default. Defaults
   # to `6379`.
   #redis['master_port'] = 6379
   ```

1. 업그레이드 시 자동으로 재구성이 실행되지 않도록 하려면 다음을 실행하세요:

   ```shell
   sudo touch /etc/gitlab/skip-auto-reconfigure
   ```

1. 프라이머리 GitLab 애플리케이션 서버만 마이그레이션을 처리해야 합니다. 업그레이드 시 데이터베이스 마이그레이션이 실행되지 않도록 하려면 `/etc/gitlab/gitlab.rb` 파일에 다음 구성을 추가하세요:

   ```ruby
   gitlab_rails['auto_migrate'] = false
   ```

1. 변경 사항이 적용되려면 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행합니다.
1. 다른 모든 레플리카 노드에 대해 단계를 다시 진행하세요.

> [!note]
> sentinel 및 Redis 같은 여러 역할을 지정할 수 있습니다: `roles ['redis_sentinel_role', 'redis_master_role']`. [역할](https://docs.gitlab.com/omnibus/roles/)에 대해 자세히 알아보세요.

이 값들은 장애 조치 후 `/etc/gitlab/gitlab.rb`에서 다시 변경할 필요가 없습니다. 노드가 Sentinel에 의해 관리되고 `gitlab-ctl reconfigure` 후에도 구성이 동일한 Sentinel에 의해 복원되기 때문입니다.

### 3단계. Redis Sentinel 인스턴스 구성 {#step-3-configuring-the-redis-sentinel-instances}

{{< history >}}

- GitLab 16.1에서 Sentinel 비밀번호 인증 지원이 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/235938)되었습니다.

{{< /history >}}

이제 Redis 서버가 모두 설정되었으므로 Sentinel 서버를 구성해봅시다.

Redis 서버가 제대로 작동하고 복제 중인지 확실하지 않으면 [복제 문제 해결](troubleshooting.md#troubleshooting-redis-replication)을 읽고 Sentinel 설정을 진행하기 전에 문제를 해결하세요.

최소 `3`개의 Redis Sentinel 서버가 필요하며, 각각은 독립적인 머신에 있어야 합니다. 다른 Redis 서버를 구성한 동일한 머신에 구성할 수 있습니다.

GitLab Enterprise Edition을 사용하면 Linux 패키지를 사용하여 Sentinel 데몬으로 여러 머신을 설정할 수 있습니다.

1. Redis Sentinel을 호스팅하는 서버에 SSH로 연결하세요.
1. **You can omit this step if the Sentinels is hosted in the same node as the other Redis instances**.

   GitLab 다운로드 페이지에서 **steps 1 and 2**를 사용하여 [Linux Enterprise Edition 패키지 다운로드 및 설치](https://about.gitlab.com/install/)하세요.
   - GitLab 애플리케이션이 실행 중인 동일한 버전의 올바른 Linux 패키지를 선택했는지 확인하세요.
   - 다운로드 페이지에서 다른 단계를 완료하지 마세요.

1. `/etc/gitlab/gitlab.rb`을 편집하고 내용을 추가하세요(다른 Redis 인스턴스와 동일한 노드에 Sentinel을 설치하는 경우 일부 값이 아래에 중복될 수 있음):

   ```ruby
   roles ['redis_sentinel_role']

   # Must be the same in every sentinel node
   redis['master_name'] = 'gitlab-redis'

   # The same password for Redis authentication you set up for the primary node.
   redis['master_password'] = 'redis-password-goes-here'

   # The IP of the primary Redis node.
   redis['master_ip'] = '10.0.0.1'

   # Define a port so Redis can listen for TCP requests which allows other
   # machines to connect to it.
   redis['port'] = 6379

   # Port of primary Redis server, uncomment to change to non default. Defaults
   # to `6379`.
   #redis['master_port'] = 6379

   ## Configure Sentinel
   sentinel['bind'] = '10.0.0.1'

   ## Optional password for Sentinel authentication. Defaults to no password required.
   # sentinel['password'] = 'sentinel-password-goes here'

   # Port that Sentinel listens on, uncomment to change to non default. Defaults
   # to `26379`.
   # sentinel['port'] = 26379

   ## Quorum must reflect the amount of voting sentinels it take to start a failover.
   ## Value must NOT be greater than the amount of sentinels.
   ##
   ## The quorum can be used to tune Sentinel in two ways:
   ## 1. If a the quorum is set to a value smaller than the majority of Sentinels
   ##    we deploy, we are basically making Sentinel more sensible to primary failures,
   ##    triggering a failover as soon as even just a minority of Sentinels is no longer
   ##    able to talk with the primary.
   ## 1. If a quorum is set to a value greater than the majority of Sentinels, we are
   ##    making Sentinel able to failover only when there are a very large number (larger
   ##    than majority) of well connected Sentinels which agree about the primary being down.s
   sentinel['quorum'] = 2

   ## Consider unresponsive server down after x amount of ms.
   # sentinel['down_after_milliseconds'] = 10000

   ## Specifies the failover timeout in milliseconds. It is used in many ways:
   ##
   ## - The time needed to re-start a failover after a previous failover was
   ##   already tried against the same primary by a given Sentinel, is two
   ##   times the failover timeout.
   ##
   ## - The time needed for a replica replicating to a wrong primary according
   ##   to a Sentinel current configuration, to be forced to replicate
   ##   with the right primary, is exactly the failover timeout (counting since
   ##   the moment a Sentinel detected the misconfiguration).
   ##
   ## - The time needed to cancel a failover that is already in progress but
   ##   did not produced any configuration change (REPLICAOF NO ONE yet not
   ##   acknowledged by the promoted replica).
   ##
   ## - The maximum time a failover in progress waits for all the replica to be
   ##   reconfigured as replicas of the new primary. However even after this time
   ##   the replicas are reconfigured by the Sentinels anyway, but not with
   ##   the exact parallel-syncs progression as specified.
   # sentinel['failover_timeout'] = 60000
   ```

1. 업그레이드 시 데이터베이스 마이그레이션이 실행되지 않도록 하려면 다음을 실행하세요:

   ```shell
   sudo touch /etc/gitlab/skip-auto-reconfigure
   ```

   프라이머리 GitLab 애플리케이션 서버만 마이그레이션을 처리해야 합니다.

1. 변경 사항이 적용되려면 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행합니다.
1. 다른 모든 Sentinel 노드에 대해 단계를 다시 진행하세요.

### 4단계. GitLab 애플리케이션 구성 {#step-4-configuring-the-gitlab-application}

마지막 부분은 Redis Sentinel 서버와 인증 자격 증명에 대해 주 GitLab 애플리케이션 서버에 알리는 것입니다.

새로운 또는 기존 설치에서 언제든지 Sentinel 지원을 활성화하거나 비활성화할 수 있습니다. GitLab 애플리케이션 관점에서 필요한 것은 Sentinel 노드에 대한 올바른 자격 증명입니다.

모든 Sentinel 노드의 목록이 필요하지는 않지만, 장애 발생 시 나열된 것 중 최소한 하나에 액세스할 수 있어야 합니다.

> [!note]
> 다음 단계는 이상적으로 HA 설정을 위해 Redis 또는 Sentinel이 없어야 하는 GitLab 애플리케이션 서버에서 수행되어야 합니다.

1. GitLab 애플리케이션이 설치된 서버에 SSH로 연결하세요.
1. `/etc/gitlab/gitlab.rb`을 편집하고 다음 줄을 추가/변경하세요:

   ```ruby
   ## Must be the same in every sentinel node
   redis['master_name'] = 'gitlab-redis'

   ## The same password for Redis authentication you set up for the primary node.
   redis['master_password'] = 'redis-password-goes-here'

   ## A list of sentinels with `host` and `port`
   gitlab_rails['redis_sentinels'] = [
     {'host' => '10.0.0.1', 'port' => 26379},
     {'host' => '10.0.0.2', 'port' => 26379},
     {'host' => '10.0.0.3', 'port' => 26379}
   ]
   # gitlab_rails['redis_sentinels_password'] = 'sentinel-password-goes-here' # uncomment and set it to the same value as in sentinel['password']
   ```

1. 변경 사항이 적용되려면 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행합니다.

### 5단계. 모니터링 활성화 {#step-5-enable-monitoring}

모니터링을 활성화하면 **전체** Redis 서버에서 활성화되어야 합니다.

1. [`CONSUL_SERVER_NODES`](../postgresql/replication_and_failover.md#consul-information)를 수집했는지 확인하세요. 이는 Consul 서버 노드의 IP 주소 또는 DNS 레코드입니다(다음 단계를 위해). 이들은 `Y.Y.Y.Y consul1.gitlab.example.com Z.Z.Z.Z`으로 표시됩니다
1. `/etc/gitlab/gitlab.rb`을 생성/편집하고 다음 구성을 추가하세요:

   ```ruby
   # Enable service discovery for Prometheus
   consul['enable'] = true
   consul['monitoring_service_discovery'] =  true

   # Replace placeholders
   # Y.Y.Y.Y consul1.gitlab.example.com Z.Z.Z.Z
   # with the addresses of the Consul server nodes
   consul['configuration'] = {
      retry_join: %w(Y.Y.Y.Y consul1.gitlab.example.com Z.Z.Z.Z),
   }

   # Set the network addresses that the exporters listen on
   node_exporter['listen_address'] = '0.0.0.0:9100'
   redis_exporter['listen_address'] = '0.0.0.0:9121'
   ```

1. `sudo gitlab-ctl reconfigure`을 실행하여 구성을 컴파일하세요.

## 1개의 프라이머리, 2개의 레플리카, 3개의 Sentinel을 사용한 최소 구성의 예 {#example-of-a-minimal-configuration-with-1-primary-2-replicas-and-3-sentinels}

이 예에서는 모든 서버에 `10.0.0.x` 범위의 IP를 가진 내부 네트워크 인터페이스가 있고 이러한 IP를 사용하여 서로 연결할 수 있다고 가정합니다.

실제 사용에서는 다른 머신의 무단 액세스를 방지하고 외부(인터넷) 트래픽을 차단하도록 방화벽 규칙을 설정할 수도 있습니다.

**Redis** + **Sentinel** 토폴로지로 [Redis 설정 개요](#redis-setup-overview) 와 [Sentinel 설정 개요](#sentinel-setup-overview) 설명서에서 논의된 동일한 `3`개 노드를 사용합니다.

각 **machine**과 할당된 **IP**에 대한 목록과 설명은 다음과 같습니다:

- `10.0.0.1`:  Redis 프라이머리 + Sentinel 1
- `10.0.0.2`:  Redis 레플리카 1 + Sentinel 2
- `10.0.0.3`:  Redis 레플리카 2 + Sentinel 3
- `10.0.0.4`:  GitLab 애플리케이션

초기 구성 후 Sentinel 노드에 의해 장애 조치가 시작되면 Redis 노드가 다시 구성되고 **프라이머리**는 `redis.conf`에서 한 노드에서 다른 노드로 영구적으로 변경되며, 새 장애 조치가 다시 시작될 때까지 유지됩니다.

동일한 상황이 `sentinel.conf`에서도 발생합니다. 초기 실행 후 재정의되며, 새 sentinel 노드가 **프라이머리**를 감시하기 시작할 때 또는 장애 조치가 다른 **프라이머리** 노드를 승격할 때입니다.

### Redis 프라이머리 및 Sentinel 1을 위한 구성 예 {#example-configuration-for-redis-primary-and-sentinel-1}

`/etc/gitlab/gitlab.rb`에서:

```ruby
roles ['redis_sentinel_role', 'redis_master_role']
redis['bind'] = '10.0.0.1'
redis['port'] = 6379
redis['password'] = 'redis-password-goes-here'
redis['master_name'] = 'gitlab-redis' # must be the same in every sentinel node
redis['master_password'] = 'redis-password-goes-here' # the same value defined in redis['password'] in the primary instance
redis['master_ip'] = '10.0.0.1' # ip of the initial primary redis instance
#redis['master_port'] = 6379 # port of the initial primary redis instance, uncomment to change to non default
sentinel['bind'] = '10.0.0.1'
# sentinel['password'] = 'sentinel-password-goes-here' # must be the same in every sentinel node, uncomment to set a password
# sentinel['port'] = 26379 # uncomment to change default port
sentinel['quorum'] = 2
# sentinel['down_after_milliseconds'] = 10000
# sentinel['failover_timeout'] = 60000
```

변경 사항이 적용되려면 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행합니다.

### Redis 레플리카 1 및 Sentinel 2를 위한 구성 예 {#example-configuration-for-redis-replica-1-and-sentinel-2}

`/etc/gitlab/gitlab.rb`에서:

```ruby
roles ['redis_sentinel_role', 'redis_replica_role']
redis['bind'] = '10.0.0.2'
redis['port'] = 6379
redis['password'] = 'redis-password-goes-here'
redis['master_password'] = 'redis-password-goes-here'
redis['master_ip'] = '10.0.0.1' # IP of primary Redis server
#redis['master_port'] = 6379 # Port of primary Redis server, uncomment to change to non default
redis['master_name'] = 'gitlab-redis' # must be the same in every sentinel node
sentinel['bind'] = '10.0.0.2'
# sentinel['password'] = 'sentinel-password-goes-here' # must be the same in every sentinel node, uncomment to set a password
# sentinel['port'] = 26379 # uncomment to change default port
sentinel['quorum'] = 2
# sentinel['down_after_milliseconds'] = 10000
# sentinel['failover_timeout'] = 60000
```

변경 사항이 적용되려면 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행합니다.

### Redis 레플리카 2 및 Sentinel 3을 위한 구성 예 {#example-configuration-for-redis-replica-2-and-sentinel-3}

`/etc/gitlab/gitlab.rb`에서:

```ruby
roles ['redis_sentinel_role', 'redis_replica_role']
redis['bind'] = '10.0.0.3'
redis['port'] = 6379
redis['password'] = 'redis-password-goes-here'
redis['master_password'] = 'redis-password-goes-here'
redis['master_ip'] = '10.0.0.1' # IP of primary Redis server
#redis['master_port'] = 6379 # Port of primary Redis server, uncomment to change to non default
redis['master_name'] = 'gitlab-redis' # must be the same in every sentinel node
sentinel['bind'] = '10.0.0.3'
# sentinel['password'] = 'sentinel-password-goes-here' # must be the same in every sentinel node, uncomment to set a password
# sentinel['port'] = 26379 # uncomment to change default port
sentinel['quorum'] = 2
# sentinel['down_after_milliseconds'] = 10000
# sentinel['failover_timeout'] = 60000
```

변경 사항이 적용되려면 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행합니다.

### GitLab 애플리케이션을 위한 구성 예 {#example-configuration-for-the-gitlab-application}

`/etc/gitlab/gitlab.rb`에서:

```ruby
redis['master_name'] = 'gitlab-redis'
redis['master_password'] = 'redis-password-goes-here'
gitlab_rails['redis_sentinels'] = [
  {'host' => '10.0.0.1', 'port' => 26379},
  {'host' => '10.0.0.2', 'port' => 26379},
  {'host' => '10.0.0.3', 'port' => 26379}
]
# gitlab_rails['redis_sentinels_password'] = 'sentinel-password-goes-here' # uncomment and set it to the same value as in sentinel['password']
```

변경 사항이 적용되려면 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행합니다.

## 고급 구성 {#advanced-configuration}

이 섹션에서는 권장 및 최소 구성을 초과하는 구성 옵션을 다룹니다.

### 여러 Redis 클러스터 실행 {#running-multiple-redis-clusters}

Linux 패키지는 다양한 지속성 클래스에 대한 별도의 Redis 및 Sentinel 인스턴스 실행을 지원합니다.

| 클래스              | 목적 |
|--------------------|---------|
| `cache`            | 캐시된 데이터를 저장합니다. |
| `queues`           | Sidekiq 백그라운드 작업을 저장합니다. |
| `shared_state`     | 세션 관련 및 기타 지속 데이터를 저장합니다. |
| `actioncable`      | ActionCable용 Pub/Sub 대기열 백엔드입니다. |
| `trace_chunks`     | [CI 추적 청크](../cicd/job_logs.md#incremental-logging) 데이터를 저장합니다. |
| `rate_limiting`    | [속도 제한](../settings/user_and_ip_rate_limits.md) 상태를 저장합니다. |
| `sessions`         | 세션을 저장합니다. |
| `repository_cache` | 리포지토리에 특정한 캐시 데이터를 저장합니다. |

Sentinel과 함께 작동하도록 하려면:

1. 필요에 따라 [다양한 Redis/Sentinel을 구성](#configuring-redis)합니다.
1. 각 Rails 애플리케이션 인스턴스에 대해 `/etc/gitlab/gitlab.rb` 파일을 편집하세요:

   ```ruby
   gitlab_rails['redis_cache_instance'] = REDIS_CACHE_URL
   gitlab_rails['redis_queues_instance'] = REDIS_QUEUES_URL
   gitlab_rails['redis_shared_state_instance'] = REDIS_SHARED_STATE_URL
   gitlab_rails['redis_actioncable_instance'] = REDIS_ACTIONCABLE_URL
   gitlab_rails['redis_trace_chunks_instance'] = REDIS_TRACE_CHUNKS_URL
   gitlab_rails['redis_rate_limiting_instance'] = REDIS_RATE_LIMITING_URL
   gitlab_rails['redis_sessions_instance'] = REDIS_SESSIONS_URL
   gitlab_rails['redis_repository_cache_instance'] = REDIS_REPOSITORY_CACHE_URL

   # Configure the Sentinels
   gitlab_rails['redis_cache_sentinels'] = [
     { host: REDIS_CACHE_SENTINEL_HOST, port: 26379 },
     { host: REDIS_CACHE_SENTINEL_HOST2, port: 26379 }
   ]
   gitlab_rails['redis_queues_sentinels'] = [
     { host: REDIS_QUEUES_SENTINEL_HOST, port: 26379 },
     { host: REDIS_QUEUES_SENTINEL_HOST2, port: 26379 }
   ]
   gitlab_rails['redis_shared_state_sentinels'] = [
     { host: SHARED_STATE_SENTINEL_HOST, port: 26379 },
     { host: SHARED_STATE_SENTINEL_HOST2, port: 26379 }
   ]
   gitlab_rails['redis_actioncable_sentinels'] = [
     { host: ACTIONCABLE_SENTINEL_HOST, port: 26379 },
     { host: ACTIONCABLE_SENTINEL_HOST2, port: 26379 }
   ]
   gitlab_rails['redis_trace_chunks_sentinels'] = [
     { host: TRACE_CHUNKS_SENTINEL_HOST, port: 26379 },
     { host: TRACE_CHUNKS_SENTINEL_HOST2, port: 26379 }
   ]
   gitlab_rails['redis_rate_limiting_sentinels'] = [
     { host: RATE_LIMITING_SENTINEL_HOST, port: 26379 },
     { host: RATE_LIMITING_SENTINEL_HOST2, port: 26379 }
   ]
   gitlab_rails['redis_sessions_sentinels'] = [
     { host: SESSIONS_SENTINEL_HOST, port: 26379 },
     { host: SESSIONS_SENTINEL_HOST2, port: 26379 }
   ]
   gitlab_rails['redis_repository_cache_sentinels'] = [
     { host: REPOSITORY_CACHE_SENTINEL_HOST, port: 26379 },
     { host: REPOSITORY_CACHE_SENTINEL_HOST2, port: 26379 }
   ]

   # gitlab_rails['redis_cache_sentinels_password'] = 'sentinel-password-goes-here'
   # gitlab_rails['redis_queues_sentinels_password'] = 'sentinel-password-goes-here'
   # gitlab_rails['redis_shared_state_sentinels_password'] = 'sentinel-password-goes-here'
   # gitlab_rails['redis_actioncable_sentinels_password'] = 'sentinel-password-goes-here'
   # gitlab_rails['redis_trace_chunks_sentinels_password'] = 'sentinel-password-goes-here'
   # gitlab_rails['redis_rate_limiting_sentinels_password'] = 'sentinel-password-goes-here'
   # gitlab_rails['redis_sessions_sentinels_password'] = 'sentinel-password-goes-here'
   # gitlab_rails['redis_repository_cache_sentinels_password'] = 'sentinel-password-goes-here'
   ```

   - Redis URL은 `redis://:PASSWORD@SENTINEL_PRIMARY_NAME` 형식이어야 합니다:
     - `PASSWORD`은 Redis 인스턴스의 일반 텍스트 비밀번호입니다.
     - `SENTINEL_PRIMARY_NAME`은 `redis['master_name']`로 설정된 Sentinel 프라이머리 이름입니다(예: `gitlab-redis-cache`).

1. 파일을 저장하고 변경 사항을 적용하기 위해 GitLab을 재구성하세요:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

> [!note]
> 각 지속성 클래스에 대해 GitLab은 `gitlab_rails['redis_sentinels']`에 지정된 구성을 기본적으로 사용하며, 이전에 설명된 설정으로 재정의되지 않는 한입니다.

### 실행 중인 서비스 제어 {#control-running-services}

이전 예에서 구성 변경 수를 단순화하는 `redis_sentinel_role`과 `redis_master_role`를 사용했습니다.

더 많은 제어를 원하면 각각이 활성화될 때 자동으로 설정되는 항목은 다음과 같습니다:

```ruby
## Redis Sentinel Role
redis_sentinel_role['enable'] = true

# When Sentinel Role is enabled, the following services are also enabled
sentinel['enable'] = true

# The following services are disabled
redis['enable'] = false
bootstrap['enable'] = false
nginx['enable'] = false
postgresql['enable'] = false
gitlab_rails['enable'] = false
mailroom['enable'] = false

-------

## Redis primary/replica Role
redis_master_role['enable'] = true # enable only one of them
redis_replica_role['enable'] = true # enable only one of them

# When Redis primary or Replica role are enabled, the following services are
# enabled/disabled. If Redis and Sentinel roles are combined, both
# services are enabled.

# The following services are disabled
sentinel['enable'] = false
bootstrap['enable'] = false
nginx['enable'] = false
postgresql['enable'] = false
gitlab_rails['enable'] = false
mailroom['enable'] = false

# For Redis Replica role, also change this setting from default 'true' to 'false':
redis['master'] = false
```

[`gitlab_rails.rb`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/gitlab/libraries/gitlab_rails.rb)에 정의된 관련 속성을 찾을 수 있습니다.

### 시작 동작 제어 {#control-startup-behavior}

{{< history >}}

- GitLab 15.10에서 [도입](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/6646)되었습니다.

{{< /history >}}

번들로 제공되는 Redis 서비스가 부팅 시 시작되거나 구성 변경 후 재시작되지 않도록 하려면:

1. `/etc/gitlab/gitlab.rb`을 편집하세요:

   ```ruby
   redis['start_down'] = true
   ```

1. GitLab을 재구성하세요:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

새 레플리카 노드를 테스트해야 하는 경우 `start_down`을 `true`로 설정하고 노드를 수동으로 시작할 수 있습니다. 새 레플리카 노드가 Redis 클러스터에서 작동하는 것으로 확인된 후 `start_down`을 `false`로 설정하고 GitLab을 재구성하여 노드가 작동 중에 예상대로 시작되고 재시작되도록 하세요.

### 레플리카 구성 제어 {#control-replica-configuration}

{{< history >}}

- GitLab 15.10에서 [도입](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/6646)되었습니다.

{{< /history >}}

`replicaof` 줄이 Redis 구성 파일에서 렌더링되지 않도록 하려면:

1. `/etc/gitlab/gitlab.rb`을 편집하세요:

   ```ruby
   redis['set_replicaof'] = false
   ```

1. GitLab을 재구성하세요:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

이 설정은 다른 Redis 설정과 독립적으로 Redis 노드의 복제를 방지하는 데 사용할 수 있습니다.

## Redis 대신 Valkey 사용 {#use-valkey-instead-of-redis}

{{< history >}}

- GitLab 18.9에서 [베타](../../policy/development_stages_support.md#beta) 로 [도입](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9113)되었습니다.
- GitLab 19.0에서 [정식 버전(GA)으로 출시됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/585839).

{{< /history >}}

복제 및 장애 조치 설정에서 [Valkey](https://valkey.io/)를 Redis의 드롭인 대체제로 사용할 수 있습니다. Valkey는 Redis와 동일한 역할 및 구성 옵션을 사용합니다.

### Valkey 프라이머리 및 레플리카 노드 구성 {#configure-valkey-primary-and-replica-nodes}

각 노드(프라이머리 및 레플리카)에서 Redis에서 Valkey로 전환하려면 `/etc/gitlab/gitlab.rb`에 다음을 추가하세요:

```ruby
# Use the same Redis roles
roles ['redis_master_role']  # or 'redis_replica_role' for replicas

# Switch to Valkey
redis['backend'] = 'valkey'

# Use the same configuration options as for Redis
redis['bind'] = '10.0.0.1'
redis['port'] = 6379
redis['password'] = 'redis-password-goes-here'

gitlab_rails['auto_migrate'] = false
```

### Valkey용 Sentinel 구성 {#configure-sentinel-for-valkey}

각 Sentinel 노드에서 `/etc/gitlab/gitlab.rb`에 다음을 추가하세요:

```ruby
roles ['redis_sentinel_role']

# Switch redis backend to Valkey
# Then Sentinel will use the same backend
redis['backend'] = 'valkey'

# Sentinel configuration (same as for Redis)
redis['master_name'] = 'gitlab-redis'
redis['master_password'] = 'redis-password-goes-here'
redis['master_ip'] = '10.0.0.1'
redis['port'] = 6379

sentinel['bind'] = '10.0.0.1'
sentinel['quorum'] = 2
```

다른 모든 Sentinel 구성 옵션은 [Redis Sentinel 인스턴스 구성](#step-3-configuring-the-redis-sentinel-instances)에 설명된 것과 동일하게 유지됩니다.

### 알려진 이슈 {#known-issues}

- 알려진 [이슈 589642](https://gitlab.com/gitlab-org/gitlab/-/issues/589642) 때문에 Admin Area는 Valkey 버전을 잘못 보고합니다. 이 이슈는 설치된 Valkey 버전이나 작동 방식에 영향을 미치지 않습니다.

## TLS를 사용한 Redis 및 Sentinel 보안 {#secure-redis-and-sentinel-with-tls}

TLS를 사용하여 Redis 및 Sentinel 통신을 보호하는 방법에 대한 포괄적인 정보는 [TLS를 사용한 Redis 및 Sentinel 보안](tls.md)을 참조하세요.

## 문제 해결 {#troubleshooting}

[Redis 문제 해결 가이드](troubleshooting.md)를 참조하세요.

## 추가 참고 자료 {#further-reading}

자세히 알아보기:

1. [참조 아키텍처](../reference_architectures/_index.md)
1. [데이터베이스 구성](../postgresql/replication_and_failover.md)
1. [NFS 구성](../nfs.md)
1. [로드 밸런서 구성](../load_balancer.md)
