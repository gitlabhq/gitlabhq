---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Gitaly 모니터링
---

사용 가능한 로그와 [Prometheus 메트릭](../monitoring/prometheus/_index.md)을(를) 사용하여 Gitaly를 모니터링합니다.

메트릭 정의는 다음 위치에서 확인할 수 있습니다:

- Prometheus `/metrics` 엔드포인트(Gitaly용으로 구성됨)에서 직접 확인할 수 있습니다.
- Prometheus에 대해 구성된 Grafana 인스턴스에서 [Grafana Explore](https://grafana.com/docs/grafana/latest/explore/)를 사용합니다.

Gitaly는 요청의 동시성(적응형 또는 비적응형)을 기준으로 요청을 제한하도록 구성할 수 있습니다.

## Gitaly 동시성 제한 모니터링 {#monitor-gitaly-concurrency-limiting}

Gitaly 로그와 Prometheus를 사용하여 [동시성 대기 중인 요청](concurrency_limiting.md#limit-rpc-concurrency)의 특정 동작을 관찰할 수 있습니다.

[Gitaly 로그](../logs/_index.md#gitaly-logs)에서 팩-객체 동시성 제한과 관련된 로그를 다음과 같은 항목으로 식별할 수 있습니다:

| 로그 필드                        | 설명 |
|----------------------------------|-------------|
| `limit.concurrency_queue_length` | 진행 중인 호출의 RPC 유형에 특정한 큐의 현재 길이를 나타냅니다. 동시성 제한으로 인해 처리 대기 중인 요청 수에 대한 인사이트를 제공합니다. |
| `limit.concurrency_queue_ms`     | 동시 RPC 제한으로 인해 요청이 큐에서 대기한 기간(밀리초)을 나타냅니다. 이 필드는 동시성 제한이 요청 처리 시간에 미치는 영향을 이해하는 데 도움이 됩니다. |
| `limit.concurrency_dropped`      | 요청이 제한에 도달하여 삭제되면, 이 필드는 다음 이유 중 하나를 지정합니다: `max_time`(요청이 허용된 최대 시간보다 더 오래 큐에서 대기했음) 또는 `max_size`(큐가 최대 크기에 도달했음). |
| `limit.limiting_key`             | 제한에 사용되는 키를 식별합니다. |
| `limit.limiting_type`            | 제한되는 프로세스의 유형을 지정합니다. 이 경우 `per-rpc`이며, 동시성 제한이 RPC별 기준으로 적용됨을 나타냅니다. |

예를 들어:

```json
{
  "limit.concurrency_queue_length": 1,
  "limit.concurrency_queue_ms": 0,
  "limit.limiting_key": "@hashed/79/02/7902699be42c8a8e46fbbb450172651786b22c56a189f7625a6da49081b2451.git",
  "limit.limiting_type": "per-rpc"
}
```

Prometheus에서 다음 메트릭을 확인합니다:

- `gitaly_concurrency_limiting_in_progress`는 처리 중인 동시 요청의 수를 나타냅니다.
- `gitaly_concurrency_limiting_queued`는 동시성 제한에 도달하여 대기 중인 지정된 리포지토리의 RPC에 대한 요청 수를 나타냅니다.
- `gitaly_concurrency_limiting_acquiring_seconds`는 처리 전에 동시성 제한으로 인해 요청이 대기해야 하는 기간을 나타냅니다.
- `gitaly_requests_dropped_total`는 요청 제한으로 인해 삭제된 요청의 총 개수를 제공합니다. `reason` 레이블은 요청이 삭제된 이유를 나타냅니다:
  - `max_size`(동시성 큐 크기에 도달했음).
  - `max_time`(요청이 Gitaly에서 구성한 최대 큐 대기 시간을 초과했음).

## Gitaly 팩-객체 동시성 제한 모니터링 {#monitor-gitaly-pack-objects-concurrency-limiting}

Gitaly 로그와 Prometheus를 사용하여 [팩-객체 제한](concurrency_limiting.md#limit-pack-objects-concurrency)의 특정 동작을 관찰할 수 있습니다.

[Gitaly 로그](../logs/_index.md#gitaly-logs)에서 팩-객체 동시성 제한과 관련된 로그를 다음과 같은 항목으로 식별할 수 있습니다:

| 로그 필드                        | 설명 |
|:---------------------------------|:------------|
| `limit.concurrency_queue_length` | 팩-객체 프로세스의 큐 현재 길이입니다. 동시 프로세스 제한에 도달하여 처리 대기 중인 요청의 수를 나타냅니다. |
| `limit.concurrency_queue_ms`     | 요청이 큐에서 대기한 기간(밀리초)입니다. 동시성 제한으로 인해 요청이 대기해야 하는 기간을 나타냅니다. |
| `limit.limiting_key`             | 발신자의 원격 IP입니다. |
| `limit.limiting_type`            | 제한되는 프로세스의 유형입니다. 이 경우 `pack-objects`입니다. |

예제 구성:

```json
{
  "limit.concurrency_queue_length": 1,
  "limit.concurrency_queue_ms": 0,
  "limit.limiting_key": "1.2.3.4",
  "limit.limiting_type": "pack-objects"
}
```

Prometheus에서 다음 메트릭을 확인합니다:

- `gitaly_pack_objects_in_progress`는 동시에 처리 중인 팩-객체 프로세스의 수를 나타냅니다.
- `gitaly_pack_objects_queued`는 동시성 제한에 도달하여 대기 중인 팩-객체 프로세스에 대한 요청 수를 나타냅니다.
- `gitaly_pack_objects_acquiring_seconds`는 처리 전에 동시성 제한으로 인해 팩-객체 프로세스 요청이 대기해야 하는 기간을 나타냅니다.

## Gitaly 적응형 동시성 제한 모니터링 {#monitor-gitaly-adaptive-concurrency-limiting}

{{< history >}}

- GitLab 16.6에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/10734)되었습니다.

{{< /history >}}

Gitaly 로그와 Prometheus를 사용하여 [적응형 동시성 제한](concurrency_limiting.md#adaptive-concurrency-limiting)의 특정 동작을 관찰할 수 있습니다.

적응형 동시성 제한은 정적 동시성 제한의 확장이므로, [정적 동시성 제한](#monitor-gitaly-concurrency-limiting)에 적용되는 모든 메트릭 및 로그는 적응형 제한을 모니터링할 때도 관련이 있습니다. 또한 적응형 제한은 제한의 동적 조정을 모니터링하는 데 도움이 되는 여러 특정 메트릭을 도입합니다.

### 적응형 제한 로그 {#adaptive-limiting-logs}

[Gitaly 로그](../logs/_index.md#gitaly-logs)에서 현재 제한이 조정될 때 적응형 동시성 제한과 관련된 로그를 식별할 수 있습니다. 로그의 내용(`msg`)에서 "Multiplicative decrease" 및 "Additive increase" 메시지를 필터링할 수 있습니다.

이러한 디버그 로그는 디버그 심각도 수준에서만 사용 가능하며 상세할 수 있지만, 적응형 제한 조정에 대한 자세한 인사이트를 제공합니다.

| 로그 필드        | 설명 |
|:-----------------|:------------|
| `limit`          | 조정 중인 제한의 이름입니다. |
| `previous_limit` | 증가 또는 감소 전 이전 제한입니다. |
| `new_limit`      | 증가 또는 감소 후 새로운 제한입니다. |
| `watcher`        | 노드가 부하 상태임을 결정한 리소스 감시자입니다. 예: `CgroupCpu` 또는 `CgroupMemory`. |
| `reason`         | 제한 조정 뒤의 이유입니다. |
| `stats.*`        | 조정 결정 뒤의 일부 통계입니다. 이들은 디버깅 목적으로 사용됩니다. |

로그 예:

```json
{
  "msg": "Multiplicative decrease",
  "limit": "pack-objects",
  "new_limit": 14,
  "previous_limit": 29,
  "reason": "cgroup CPU throttled too much",
  "watcher": "CgroupCpu",
  "stats.time_diff": 15.0,
  "stats.throttled_duration": 13.0,
  "stat.sthrottled_threshold": 0.5
}
```

### 적응형 제한 메트릭 {#adaptive-limiting-metrics}

Prometheus에서 다음 메트릭을 확인합니다:

정적 및 적응형 제한 모두에 적용되는 일반 동시성 제한 메트릭:

- `gitaly_concurrency_limiting_in_progress` - 처리 중인 요청 수입니다.
- `gitaly_concurrency_limiting_queued` - 동시성 제한으로 인해 큐에서 대기 중인 요청 수입니다.
- `gitaly_concurrency_limiting_acquiring_seconds` - 처리 시작 전에 동시성 제한으로 인해 요청이 대기한 기간입니다.

적응형 동시성 제한 특정 메트릭:

- `gitaly_concurrency_limiting_current_limit` - 각 RPC 유형에 대한 적응형 동시성 제한의 현재 제한 값을 보여주는 게이지입니다. 이 메트릭에는 적응형 제한만 포함됩니다.
- `gitaly_concurrency_limiting_backoff_events_total` - 백오프 이벤트의 총 수를 나타내는 카운터로, 리소스 부하로 인해 제한이 감소하는 시기와 이유를 나타냅니다.
- `gitaly_concurrency_limiting_watcher_errors_total` - Gitaly가 리소스 데이터를 검색하지 못할 때 발생하는 오류를 추적하는 카운터로, Gitaly가 현재 리소스 상황을 평가하는 능력에 영향을 미칠 수 있습니다.

적응형 제한 문제를 조사할 때, 이러한 메트릭과 일반 동시성 제한 메트릭 및 로그를 연관시켜 시스템 동작의 전체 그림을 파악합니다.

## Gitaly cgroups 모니터링 {#monitor-gitaly-cgroups}

Prometheus를 사용하여 [제어 그룹(cgroups)](configure_gitaly.md#control-groups)의 상태를 관찰할 수 있습니다:

- `gitaly_cgroups_reclaim_attempts_total`(메모리 회수 시도가 발생한 총 횟수에 대한 게이지)입니다. 이 수는 서버가 재시작될 때마다 초기화됩니다.
- `gitaly_cgroups_cpu_usage`(cgroup당 CPU 사용량을 측정하는 게이지)입니다.
- `gitaly_cgroup_procs_total`(Gitaly가 cgroup의 제어 하에서 생성한 프로세스의 총 수를 측정하는 게이지)입니다.
- `gitaly_cgroup_cpu_cfs_periods_total`(다음 [`nr_periods`](https://docs.kernel.org/scheduler/sched-bwc.html#statistics)의 값에 대한 카운터)입니다.
- `gitaly_cgroup_cpu_cfs_throttled_periods_total`(다음 [`nr_throttled`](https://docs.kernel.org/scheduler/sched-bwc.html#statistics)의 값에 대한 카운터)입니다.
- `gitaly_cgroup_cpu_cfs_throttled_seconds_total`(초 단위로 다음 [`throttled_time`](https://docs.kernel.org/scheduler/sched-bwc.html#statistics)의 값에 대한 카운터)입니다.

## `pack-objects` 캐시 {#pack-objects-cache}

다음 [`pack-objects` 캐시](configure_gitaly.md#pack-objects-cache) 메트릭을 사용할 수 있습니다:

- `gitaly_pack_objects_cache_enabled`(캐시가 활성화되었을 때 `1`로 설정된 게이지)입니다. 사용 가능한 레이블: `dir` 및 `max_age`입니다.
- `gitaly_pack_objects_cache_lookups_total`(캐시 조회에 대한 카운터)입니다. 사용 가능한 레이블: `result`입니다.
- `gitaly_pack_objects_generated_bytes_total`(캐시에 쓴 바이트 수에 대한 카운터)입니다.
- `gitaly_pack_objects_served_bytes_total`(캐시에서 읽은 바이트 수에 대한 카운터)입니다.
- `gitaly_streamcache_filestore_disk_usage_bytes`(캐시 파일의 총 크기에 대한 게이지)입니다. 사용 가능한 레이블: `dir`입니다.
- `gitaly_streamcache_index_entries`(캐시의 항목 수에 대한 게이지)입니다. 사용 가능한 레이블: `dir`입니다.

이러한 메트릭 중 일부는 `gitaly_streamcache`로 시작하는 이유는 Gitaly의 `streamcache` 내부 라이브러리 패키지에 의해 생성되기 때문입니다.

예:

```plaintext
gitaly_pack_objects_cache_enabled{dir="/var/opt/gitlab/git-data/repositories/+gitaly/PackObjectsCache",max_age="300"} 1
gitaly_pack_objects_cache_lookups_total{result="hit"} 2
gitaly_pack_objects_cache_lookups_total{result="miss"} 1
gitaly_pack_objects_generated_bytes_total 2.618649e+07
gitaly_pack_objects_served_bytes_total 7.855947e+07
gitaly_streamcache_filestore_disk_usage_bytes{dir="/var/opt/gitlab/git-data/repositories/+gitaly/PackObjectsCache"} 2.6200152e+07
gitaly_streamcache_filestore_removed_total{dir="/var/opt/gitlab/git-data/repositories/+gitaly/PackObjectsCache"} 1
gitaly_streamcache_index_entries{dir="/var/opt/gitlab/git-data/repositories/+gitaly/PackObjectsCache"} 1
```

## Gitaly 서버 측 백업 모니터링 {#monitor-gitaly-server-side-backups}

{{< history >}}

- GitLab 16.7에서 [도입](https://gitlab.com/gitlab-org/gitaly/-/issues/5358)되었습니다.

{{< /history >}}

다음 메트릭으로 [서버 측 리포지토리 백업](configure_gitaly.md#configure-server-side-backups)을(를) 모니터링합니다:

- `gitaly_backup_latency_seconds`(서버 측 백업의 각 단계가 소요되는 시간(초)을 측정하는 히스토그램)입니다. 다른 단계는 `refs`, `bundle`, `custom_hooks`이며 각 단계에서 처리되는 데이터의 유형을 나타냅니다.
- `gitaly_backup_bundle_bytes`(Gitaly 백업 서비스에 의해 객체 스토리지로 푸시되는 Git 번들의 업로드 데이터 속도를 측정하는 히스토그램)입니다.

특히 GitLab 인스턴스에 대형 리포지토리가 포함된 경우 이러한 메트릭을 사용합니다.

## 쿼리 {#queries}

다음은 Gitaly를 모니터링하기 위한 몇 가지 쿼리입니다:

- 다음 Prometheus 쿼리를 사용하여 Gitaly가 프로덕션 환경을 제공하는 [연결 유형](tls_support.md)을(를) 관찰합니다:

  ```prometheus
  sum(rate(gitaly_connections_total[5m])) by (type)
  ```

- 다음 Prometheus 쿼리를 사용하여 GitLab 설치의 [인증 동작](tls_support.md#observe-type-of-gitaly-connections)을(를) 모니터링합니다:

  ```prometheus
  sum(rate(gitaly_authentications_total[5m])) by (enforced, status)
  ```

  인증이 올바르게 구성되었고 실시간 트래픽이 있는 시스템에서는 다음과 같은 내용을 볼 수 있습니다:

  ```prometheus
  {enforced="true",status="ok"}  4424.985419441742
  ```

  속도가 0인 다른 수도 있지만, 0이 아닌 수만 기록하면 됩니다.

  유일한 0이 아닌 수는 `enforced="true",status="ok"`를 포함해야 합니다. 다른 0이 아닌 수가 있으면 구성에 문제가 있는 것입니다.

  `status="ok"` 수는 현재 요청 속도를 반영합니다. 이전 예에서 Gitaly는 초당 약 4000개의 요청을 처리하고 있습니다.

- 다음 Prometheus 쿼리를 사용하여 프로덕션 환경에서 사용 중인 [Git 프로토콜 버전](../git_protocol.md)을(를) 관찰합니다:

  ```prometheus
  sum(rate(gitaly_git_protocol_requests_total[1m])) by (grpc_method,git_protocol,grpc_service)
  ```
