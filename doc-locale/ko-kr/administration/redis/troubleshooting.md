---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Redis 문제 해결
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

HA 설정이 예상대로 작동하려면 많은 이동식 부분을 신중하게 관리해야 합니다.

아래의 문제 해결을 진행하기 전에 방화벽 규칙을 확인하세요:

- Redis 머신
  - `6379`에서 TCP 연결 수락
  - TCP `6379`를 통해 다른 Redis 머신에 연결
- Sentinel 머신
  - `26379`에서 TCP 연결 수락
  - TCP `26379`를 통해 다른 Sentinel 머신에 연결
  - TCP `6379`를 통해 Redis 머신에 연결

## 기본 Redis 활동 확인 {#basic-redis-activity-check}

기본 Redis 활동 확인으로 Redis 문제 해결을 시작하세요:

1. GitLab 서버에서 터미널을 열 수 있습니다.
1. `gitlab-redis-cli --stat`를 실행하고 실행 중인 출력을 관찰하세요.
1. GitLab UI로 이동하여 몇 페이지를 탐색합니다. 그룹 또는 프로젝트 개요, 이슈, 또는 리포지토리의 파일과 같은 모든 페이지가 작동합니다.
1. `stat` 출력을 다시 확인하고 탐색할 때 `keys`, `clients`, `requests`, 및 `connections`의 값이 증가하는지 확인하세요. 숫자가 증가하면 기본 Redis 기능이 작동하고 있으며 GitLab이 연결할 수 있습니다.

## Redis 복제 문제 해결 {#troubleshooting-redis-replication}

`redis-cli` 애플리케이션을 사용하여 각 서버에 연결하고 `info replication` 명령을 보내면 모든 것이 올바른지 확인할 수 있습니다.

```shell
/opt/gitlab/embedded/bin/redis-cli -h <redis-host-or-ip> -a '<redis-password>' info replication
```

`Primary` Redis에 연결되면 연결된 `replicas`의 수와 각각의 연결 세부 정보 목록이 표시됩니다:

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

`replica`이면 기본 연결의 세부 정보와 `up` 또는 `down`인지 확인할 수 있습니다:

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

## Redis 인스턴스의 높은 CPU 사용량 {#high-cpu-usage-on-redis-instance}

기본적으로 GitLab은 600개 이상의 Sidekiq 큐를 사용하며, 각각 Redis 목록으로 저장됩니다. 각 Sidekiq 스레드는 긴 문자열에 나열된 모든 큐를 포함하는 `BRPOP` 명령을 발행합니다. Redis CPU 사용률은 큐의 수와 `BRPOP` 호출의 빈도가 증가함에 따라 증가합니다. GitLab 인스턴스에 많은 Sidekiq 프로세스가 있으면 Redis CPU 사용률이 100%에 가까워질 수 있습니다. 높은 CPU 사용률은 GitLab 성능을 크게 저하시킵니다.

Sidekiq으로 인한 Redis의 CPU 사용량을 줄이기 위해 다음을 수행할 수 있습니다:

- [라우팅 규칙](../sidekiq/processing_specific_job_classes.md#routing-rules)을 사용하여 Sidekiq 큐의 수를 줄이세요.
- GitLab 16.6 이전 버전을 사용하는 경우 [`SIDEKIQ_SEMI_RELIABLE_FETCH_TIMEOUT` 환경 변수](../environment_variables.md)를 증가시켜 Redis의 CPU 사용량을 개선하세요. GitLab 16.7 이상에서는 [기본값이 5](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/139583)이며, 이는 충분해야 합니다.

`SIDEKIQ_SEMI_RELIABLE_FETCH_TIMEOUT` 옵션은 연결 해제 및 연결로 인한 오버헤드를 줄이지만 Sidekiq의 종료 지연을 증가시킵니다.

## Sentinel 문제 해결 {#troubleshooting-sentinel}

`Redis::CannotConnectError: No sentinels available.`와 같은 오류가 발생하면 구성 파일에 이슈가 있거나 [이 이슈](https://github.com/redis/redis-rb/issues/531)와 관련이 있을 수 있습니다.

`redis['master_name']` 및 `redis['master_password']`에서 sentinel 노드에 정의한 것과 동일한 값을 정의하고 있는지 확인해야 합니다.

Redis 커넥터 `redis-rb`가 sentinel과 작동하는 방식은 다소 직관적이지 않습니다. Linux 패키지의 복잡성을 숨기려고 시도하지만 여전히 몇 가지 추가 구성이 필요합니다.

구성이 올바른지 확인하려면:

1. GitLab 애플리케이션 서버에 SSH 연결
1. Rails 콘솔 입력:

   ```shell
   # For Omnibus installations
   sudo gitlab-rails console

   # For source installations
   sudo -u git rails console -e production
   ```

1. 콘솔에서 실행:

   ```ruby
   redis = Gitlab::Redis::SharedState.redis
   redis.info
   ```

   이 화면을 열어 두고 아래 설명된 대로 장애 조치를 트리거하세요.

1. 기본 Redis에서 장애 조치를 트리거하려면 Redis 서버에 SSH 연결하고 실행하세요:

   ```shell
   # port must match your primary redis port, and the sleep time must be a few seconds bigger than defined one
    redis-cli -h localhost -p 6379 DEBUG sleep 20
   ```

   > [!warning]
   > 이 작업은 서비스에 영향을 주며 인스턴스를 최대 20초 동안 종료합니다. 성공하면 이후에 복구되어야 합니다.

1. 그런 다음 첫 번째 단계에서 Rails 콘솔로 돌아가서 실행하세요:

   ```ruby
   redis.info
   ```

   몇 초 지연 후 다른 포트가 표시되어야 합니다(장애 조치/재연결 시간).

## 자체 컴파일된 설치를 사용하는 비번들 Redis 문제 해결 {#troubleshooting-a-non-bundled-redis-with-a-self-compiled-installation}

GitLab에서 `Redis::CannotConnectError: No sentinels available.`과 같은 오류가 발생하면 구성 파일에 이슈가 있거나 [이 업스트림 이슈](https://github.com/redis/redis-rb/issues/531)와 관련이 있을 수 있습니다.

`resque.yml` 및 `sentinel.conf`이 올바르게 구성되었는지 확인해야 합니다. 그렇지 않으면 `redis-rb`이 제대로 작동하지 않습니다.

(`sentinel.conf`)에 정의된 `master-group-name` (`gitlab-redis`)는 GitLab (`resque.yml`)의 호스트명으로 **must** 사용되어야 합니다:

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

의심스러울 때는 [Redis Sentinel](https://redis.io/docs/latest/operate/oss_and_stack/management/sentinel/) 문서를 읽으세요.
