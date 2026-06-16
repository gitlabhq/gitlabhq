---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Gitaly 클러스터(Praefect) 모니터링
---

Gitaly 클러스터(Praefect)를 모니터링하려면 Prometheus 메트릭을 사용할 수 있습니다. 메트릭을 수집할 수 있는 두 개의 별도 메트릭 엔드포인트를 사용할 수 있습니다:

- 기본 `/metrics` 엔드포인트입니다.
- 데이터베이스 쿼리가 필요한 메트릭을 포함하는 `/db_metrics`입니다.

## 기본 Prometheus `/metrics` 엔드포인트 {#default-prometheus-metrics-endpoint}

`/metrics` 엔드포인트에서 사용할 수 있는 메트릭은 다음과 같습니다:

- `gitaly_praefect_read_distribution`: [읽기 분배](_index.md#distributed-reads)를 추적하는 카운터입니다. 두 개의 레이블이 있습니다:

  - `virtual_storage`.
  - `storage`.

  이는 이 Praefect 인스턴스에 정의된 구성을 반영합니다.

- `gitaly_praefect_replication_latency_bucket`: 복제 작업이 시작된 후 복제가 완료되는 데 걸리는 시간을 측정하는 히스토그램입니다.
- `gitaly_praefect_replication_delay_bucket`: 복제 작업이 생성되는 시점과 시작되는 시점 사이에 경과하는 시간을 측정하는 히스토그램입니다.
- `gitaly_praefect_connections_total`: Praefect에 대한 총 연결 수입니다.
- `gitaly_praefect_method_types`: 노드당 접근자 및 변경자 RPC의 개수입니다.

[강력한 일관성](_index.md#strong-consistency)을 모니터링하려면 다음 Prometheus 메트릭을 사용할 수 있습니다:

- `gitaly_praefect_transactions_total`: 생성되고 투표된 트랜잭션의 수입니다.
- `gitaly_praefect_subtransactions_per_transaction_total`: 노드가 단일 트랜잭션에 대해 투표를 한 횟수입니다. 단일 트랜잭션에서 여러 참조가 업데이트되는 경우 여러 번 발생할 수 있습니다.
- `gitaly_praefect_voters_per_transaction_total`: 트랜잭션에 참여하는 Gitaly 노드의 수입니다.
- `gitaly_praefect_transactions_delay_seconds`: 트랜잭션이 커밋될 때까지 대기하여 도입되는 서버 측 지연입니다.
- `gitaly_hook_transaction_voting_delay_seconds`: 트랜잭션이 커밋될 때까지 대기하여 도입되는 클라이언트 측 지연입니다.

[리포지토리 검증](configure.md#repository-verification)을 모니터링하려면 다음 Prometheus 메트릭을 사용합니다:

- `gitaly_praefect_verification_jobs_dequeued_total`: 워커가 선택한 검증 작업의 수입니다.
- `gitaly_praefect_verification_jobs_completed_total`: 워커가 완료한 검증 작업의 수입니다. `result` 레이블은 작업의 최종 결과를 나타냅니다:
  - `valid`은 예상 복제본이 스토리지에 존재했음을 나타냅니다.
  - `invalid`은 예상된 복제본이 스토리지에 존재하지 않았음을 나타냅니다.
  - `error`은 작업이 실패했으며 재시도해야 함을 나타냅니다.
- `gitaly_praefect_stale_verification_leases_released_total`: 해제된 부실한 검증 임대의 수입니다.

또한 [Praefect 로그](../../logs/_index.md#praefect-logs)를 모니터링할 수 있습니다.

## 데이터베이스 메트릭 `/db_metrics` 엔드포인트 {#database-metrics-db_metrics-endpoint}

`/db_metrics` 엔드포인트에서 사용할 수 있는 메트릭은 다음과 같습니다:

- `gitaly_praefect_unavailable_repositories`: 정상적이고 최신 상태의 복제본이 없는 리포지토리의 수입니다.
- `gitaly_praefect_replication_queue_depth`: 복제 큐의 작업 수입니다.
- `gitaly_praefect_verification_queue_depth`: 검증 대기 중인 복제본의 총 수입니다.
