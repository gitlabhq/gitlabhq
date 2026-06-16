---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: PostgreSQL 튜닝
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

다음과 같은 경우에 PostgreSQL을 튜닝합니다:

- 다른 GitLab 구성 요소가 데이터베이스에 영향을 주는 방식으로 재구성되거나 확장된 경우
- GitLab 환경의 성능이 저하된 경우
- GitLab에서 [외부 PostgreSQL 서비스](external.md)를 사용하는 경우

이 정보를 GitLab의 [필수 PostgreSQL 설정](../../install/requirements.md#postgresql-settings)과 함께 사용합니다.

## 데이터베이스 연결 계획 {#plan-your-database-connections}

> [!note]
> GitLab 버전 16.0 이상에서는 `main` 및 `ci` 테이블에 [두 세트의 데이터베이스 연결](https://docs.gitlab.com/omnibus/settings/database/#configuring-multiple-database-connections)을 사용합니다. 이는 동일한 PostgreSQL 데이터베이스가 두 테이블 세트를 모두 제공하는 경우에도 연결 사용량이 두 배가 됩니다.

GitLab은 여러 구성 요소에서 데이터베이스 연결을 사용합니다. 적절한 연결 계획은 데이터베이스 연결 소진 및 성능 문제를 방지합니다.

각 GitLab 구성 요소는 구성에 따라 데이터베이스 연결을 사용합니다. Sidekiq과 Puma는 초기화 시 PostgreSQL에 대한 연결 풀을 설정합니다. 연결 스파이크 또는 수요가 일시적으로 증가하는 경우 풀의 연결 수가 나중에 증가할 수 있습니다:

- 환경 변수 `DB_POOL_HEADROOM`을(를) 사용하여 데이터베이스 풀 헤드룸을 구성합니다.
- PostgreSQL을 튜닝할 때는 풀 헤드룸을 계획하지만 변경하지 마세요. 더 많은 용량을 사용할 수 있으면 GitLab 배포가 더 높은 수요에 더 잘 대응합니다: Sidekiq 또는 Puma 워커를 더 배포합니다.

### Puma {#puma}

```plaintext
Puma connections = puma['worker_processes'] × (puma['max_threads'] + DB_POOL_HEADROOM)
```

기본값:

- `puma['worker_processes']`은(는) CPU 코어 수에 따릅니다.
- `puma['max_threads']`은(는) `4`입니다.
- `DB_POOL_HEADROOM`은(는) `10`입니다.

작업자당 계산:  각 Puma 워커는 4개의 스레드 + 10개의 헤드룸을 사용하여 총 14개의 연결을 가집니다.

기본 계산(8개 vCPU 기준):  8개 워커 × 워커당 14개 연결 = 총 112개의 Puma 연결

### Sidekiq {#sidekiq}

```plaintext
Sidekiq connections = Number of Sidekiq processes × (sidekiq['concurrency'] + 1 + DB_POOL_HEADROOM)
```

기본값:

- Sidekiq 프로세스의 수는 `1`입니다.
- `sidekiq['concurrency']`은(는) `20`입니다.
- `DB_POOL_HEADROOM`은(는) `10`입니다.

기본 계산:  1개의 Sidekiq 프로세스 × (20개 동시성 + 1 + 10개 헤드룸) = 총 31개의 Sidekiq 연결

### Geo Log Cursor (Geo 설치만 해당) {#geo-log-cursor-geo-installations-only}

[Geo Log Cursor](../../development/geo.md#geo-log-cursor-daemon) 데몬은 보조 사이트의 모든 GitLab Rails 노드에서 실행됩니다.

```plaintext
Geo log cursor connections = 1 + DB_POOL_HEADROOM
```

기본 계산:  1 + 10개 헤드룸 = 총 11개의 Geo 연결

### 총 연결 요구 사항 {#total-connection-requirements}

단일 노드 설치의 경우:

```plaintext
Total connections = 2 × (Puma + Sidekiq + Geo)
```

다중 노드 설치의 경우 각 구성 요소를 실행하는 노드의 수를 곱합니다:

```plaintext
Total connections = 2 × ((Puma × Rails nodes) + (Sidekiq × Sidekiq nodes) + (Geo × secondary Rails nodes))
```

2를 곱하면 GitLab 16.0 이상의 [이중 데이터베이스 연결](https://docs.gitlab.com/omnibus/settings/database/#configuring-multiple-database-connections)이 반영됩니다.

Geo 설치의 경우:

- 주 사이트:  `Geo = 0`을(를) 사용합니다. Geo Log Cursor는 주 사이트에서 실행되지 않습니다.
- 보조 사이트:  하나의 보조 사이트에 대한 Geo Log Cursor 데이터베이스 연결을 계산하고 모든 보조 사이트에 동일한 계산을 적용합니다.
- 각 Geo 사이트는 자체 데이터베이스에 연결되므로 여러 Geo 사이트에서 연결을 합산할 필요가 없습니다.
- `max_connections`을(를) 주 PostgreSQL 데이터베이스와 모든 복제본 데이터베이스에서 동일한 값으로 설정하여 모든 Geo 사이트에서 가장 높은 연결 요구 사항을 사용합니다.

### 예제 {#examples}

#### 단일 노드 설치 {#single-node-installation}

이 예제는 [20 RPS(초당 요청 수) 또는 1000명의 사용자](../reference_architectures/1k_users.md)에 대한 GitLab 참조 아키텍처를 기반으로 합니다:

| 구성 요소 | 노드 | 구성             | 구성 요소당 연결 | 구성 요소 합계, 이중 데이터베이스 |
|-----------|-------|---------------------------|---------------------------|---------------------------------|
| Puma      | 1     | 각 8명의 워커, 4개의 스레드 | 워커당 14개             | 224                             |
| Sidekiq   | 1     | 1개 프로세스, 20개 동시성 | 프로세스당 31개            | 62                              |
| 합계     |       |                           |                           | 286                             |

#### 다중 노드 설치 {#multi-node-installation}

이 예제는 [40 RPS(초당 요청 수) 또는 2000명의 사용자](../reference_architectures/2k_users.md)에 대한 GitLab 참조 아키텍처를 기반으로 합니다:

| 구성 요소 | 노드 | 구성                      | 구성 요소당 연결 | 구성 요소 합계, 이중 데이터베이스 |
|-----------|-------|------------------------------------|---------------------------|--------------------------------|
| Puma      | 2     | 노드당 8명의 워커, 각 4개의 스레드 | 워커당 14개             | 448                            |
| Sidekiq   | 1     | 4개 프로세스, 각 20개 동시성   | 프로세스당 31개            | 248                            |
| 합계     |       |                                    |                           | 696                            |

#### Geo가 포함된 단일 노드 설치 {#single-node-installation-with-geo}

이 예제는 [20 RPS(초당 요청 수) 또는 1000명의 사용자](../reference_architectures/1k_users.md)에 대한 GitLab 참조 아키텍처를 기반으로 합니다.

| Geo 사이트당 구성 요소                | 노드 | 구성             | 구성 요소당 연결 | 구성 요소 합계, 이중 데이터베이스 |
|---------------------------------------|-------|---------------------------|---------------------------|--------------------------------|
| Puma                                  | 1     | 각 8명의 워커, 4개의 스레드 | 워커당 14개             | 224                            |
| Sidekiq                               | 1     | 1개 프로세스, 20개 동시성 | 프로세스당 31개            | 62                             |
| Geo Log Cursor (보조 사이트만 해당) | 1     | 1개 프로세스                 | 프로세스당 11개            | 22                             |
| 합계                                 |       |                           |                           | 308                            |

#### Geo가 포함된 다중 노드 설치 {#multi-node-installation-with-geo}

이 예제는 [40 RPS(초당 요청 수) 또는 2000명의 사용자](../reference_architectures/2k_users.md)에 대한 GitLab 참조 아키텍처를 기반으로 합니다:

| Geo 사이트당 구성 요소                | 노드 | 구성                      | 구성 요소당 연결 | 구성 요소 합계, 이중 데이터베이스 |
|---------------------------------------|-------|------------------------------------|---------------------------|--------------------------------|
| Puma                                  | 2     | 노드당 8명의 워커, 각 4개의 스레드 | 워커당 14개             | 448                            |
| Sidekiq                               | 1     | 4개 프로세스, 각 20개 동시성   | 프로세스당 31개            | 248                            |
| Geo Log Cursor (보조 사이트만 해당) | 2     | Rails 노드당 1개 프로세스           | 프로세스당 11개            | 44                             |
| 합계                                 |       |                                    |                           | 740                            |
