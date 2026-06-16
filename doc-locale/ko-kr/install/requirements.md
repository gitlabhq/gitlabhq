---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 설치를 위한 사전 요구 사항입니다.
title: GitLab 설치 요구 사항
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab은 특정 설치 요구 사항이 있습니다.

## 저장소 {#storage}

필요한 저장소 공간은 주로 GitLab에서 보유하려는 리포지토리의 크기에 따라 다릅니다. 일반적으로 모든 리포지토리를 합친 만큼 최소한의 여유 공간이 있어야 합니다.

Linux 패키지는 설치를 위해 약 2.5GB의 저장소 공간이 필요합니다. PostgreSQL, 로그, 임시 파일 및 운영 체제 오버헤드와 함께 고려할 때, 리포지토리 데이터가 없는 기본 GitLab 설치를 위해 최소 40GB의 디스크 공간을 계획합니다. 저장소 유연성을 위해 논리 볼륨 관리를 통해 하드 드라이브를 마운트하는 것을 고려합니다. 응답 시간을 줄이기 위해 최소 7,200 RPM의 하드 드라이브 또는 솔리드 스테이트 드라이브가 있어야 합니다.

파일 시스템 성능이 GitLab의 전체 성능에 영향을 미칠 수 있으므로 [클라우드 기반 파일 시스템을 저장소에 사용하지 않아야](../administration/nfs.md#avoid-using-cloud-based-file-systems) 합니다.

## CPU {#cpu}

CPU 요구 사항은 사용자 수와 예상 워크로드에 따라 다릅니다. 워크로드에는 사용자의 활동, 자동화 및 미러링 사용, 리포지토리 크기가 포함됩니다.

초당 최대 20개의 요청 또는 1,000명의 사용자의 경우 8개의 vCPU가 있어야 합니다. 사용자가 더 많거나 워크로드가 높은 경우 [참조 아키텍처](../administration/reference_architectures/_index.md)를 참조합니다.

## 메모리 {#memory}

메모리 요구 사항은 사용자 수와 예상 워크로드에 따라 다릅니다. 워크로드에는 사용자의 활동, 자동화 및 미러링 사용, 리포지토리 크기가 포함됩니다.

초당 최대 20개의 요청 또는 1,000명의 사용자의 경우 16GB의 메모리가 있어야 합니다. 사용자가 더 많거나 워크로드가 높은 경우 [참조 아키텍처](../administration/reference_architectures/_index.md)를 참조합니다.

경우에 따라 GitLab은 최소 8GB의 메모리로 실행할 수 있습니다. 자세한 내용은 [메모리가 제한된 환경에서 GitLab 실행](https://docs.gitlab.com/omnibus/settings/memory_constrained_envs/)을 참조합니다.

## PostgreSQL {#postgresql}

[PostgreSQL](https://www.postgresql.org/)은 유일하게 지원되는 데이터베이스이며 Linux 패키지에 번들로 제공됩니다. [외부 PostgreSQL 데이터베이스](https://docs.gitlab.com/omnibus/settings/database/#using-a-non-packaged-postgresql-database-management-server) 를 사용할 수도 있습니다 [올바르게 구성되어야](#postgresql-settings) 합니다.

### 지원되는 버전 {#supported-versions}

다음 GitLab 버전의 경우 이러한 PostgreSQL 버전을 사용합니다:

| GitLab 버전 | Helm 차트 버전 | 최소 PostgreSQL 버전 | 최대 PostgreSQL 버전 |
| -------------- | ------------------ | -------------------------- | -------------------------- |
| 19.x           | 10.x               | 17.x                       | 17.x                       |
| 18.x           | 9.x                | [16.5](https://gitlab.com/gitlab-org/gitlab/-/issues/508672) | 17.x ([GitLab 17.10 이상에서 테스트됨](https://gitlab.com/gitlab-org/gitlab/-/issues/521159)) |
| 17.x           | 8.x                | [14.14](https://gitlab.com/gitlab-org/gitlab/-/issues/508672) | 16.x ([GitLab 16.10 이상에서 테스트됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145298)) |
| 16.x           | 7.x                | 13.6                       | 15.x ([GitLab 16.1 이상에서 테스트됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119344)) |

경미한 PostgreSQL 릴리스는 [버그 및 보안 수정만 포함](https://www.postgresql.org/support/versioning/)합니다. PostgreSQL의 알려진 이슈를 피하기 위해 항상 최신 경미한 버전을 사용합니다. 자세한 내용은 [이슈 364763](https://gitlab.com/gitlab-org/gitlab/-/issues/364763)을 참조합니다.

지정된 것보다 최신의 PostgreSQL 주요 버전을 사용하려면 [Linux 패키지에 번들로 제공되는 최신 버전](http://gitlab-org.gitlab.io/omnibus-gitlab/licenses.html)이 있는지 확인합니다.

### 저장소 요구 사항 {#storage-requirements}

[사용자 수](../administration/reference_architectures/_index.md)에 따라 PostgreSQL 서버는 다음을 가져야 합니다:

- 대부분의 GitLab 인스턴스의 경우 최소 5~10GB의 저장소입니다.
- GitLab Ultimate의 경우 최소 12GB의 저장소입니다(1GB의 취약성 데이터를 가져와야 함).

### 확장 {#extensions}

확장을 설치하려면 PostgreSQL은 슈퍼유저 권한이 필요합니다. 지침을 보려면 [PostgreSQL 확장 관리](../administration/postgresql/extensions.md)를 참조합니다.

| 확장            | 최소 GitLab 버전 | 유형        | 데이터베이스 |
|----------------------|------------------------|-------------|----------|
| `amcheck`            | 18.4                   | 필수    | 메인 |
| `btree_gist`         | 13.1                   | 필수    | 메인 |
| `pg_trgm`            | 8.6                    | 필수    | 메인 |
| `plpgsql`            | 11.7                   | 필수    | 메인, [Geo 보조 추적 데이터베이스](../administration/geo/_index.md) (최소 버전 9.0) |
| `pg_stat_statements` | -                      | 권장 | 모두 |

### GitLab Geo {#gitlab-geo}

[GitLab Geo](../administration/geo/_index.md) 의 경우 Linux 패키지 또는 [검증된 클라우드 제공자](../administration/reference_architectures/_index.md#recommended-cloud-providers-and-services)를 사용하여 GitLab을 설치합니다. 다른 외부 데이터베이스와의 호환성은 보장되지 않습니다.

자세한 내용은 [Geo 실행을 위한 요구 사항](../administration/geo/_index.md#requirements-for-running-geo)을 참조합니다.

### 로케일 호환성 {#locale-compatibility}

`glibc`에서 로케일 데이터를 변경하면 PostgreSQL 데이터베이스 파일이 다른 운영 체제 간에 더 이상 완전히 호환되지 않습니다. 인덱스 손상을 방지하려면 다음을 수행할 때 [로케일 호환성을 확인](../administration/geo/replication/troubleshooting/common.md#check-os-locale-data-compatibility)합니다:

- 서버 간에 PostgreSQL 바이너리 데이터를 이동합니다.
- Linux 배포판을 업그레이드합니다.
- 타사 컨테이너 이미지를 업데이트하거나 변경합니다.

자세한 내용은 [PostgreSQL용 운영 체제 업그레이드](../administration/postgresql/upgrading_os.md)를 참조합니다.

### GitLab 스키마 {#gitlab-schemas}

GitLab, [Geo](../administration/geo/_index.md) , [Gitaly Cluster(Praefect)](../administration/gitaly/praefect/_index.md) 또는 기타 구성 요소를 위해 데이터베이스를 독점적으로 생성하거나 사용합니다. 다음을 따를 때를 제외하고 데이터베이스, 스키마, 사용자 또는 기타 속성을 생성하거나 수정하지 않습니다:

- GitLab 설명서의 절차
- GitLab Support 또는 엔지니어의 지시

주 GitLab 애플리케이션은 세 개의 스키마를 사용합니다:

- 기본 `public` 스키마
- `gitlab_partitions_static` (자동으로 생성됨)
- `gitlab_partitions_dynamic` (자동으로 생성됨)

Rails 데이터베이스 마이그레이션 중에 GitLab은 스키마 또는 테이블을 생성하거나 수정할 수 있습니다. 데이터베이스 마이그레이션은 GitLab 코드베이스의 스키마 정의에 대해 테스트됩니다. 스키마를 수정하면 [GitLab 업그레이드](../update/_index.md)가 실패할 수 있습니다.

### PostgreSQL 설정 {#postgresql-settings}

다음은 외부적으로 관리되는 PostgreSQL 인스턴스의 필수 설정입니다.

| 조정 가능한 설정        | 필수 값 | 추가 정보 |
|:-----------------------|:---------------|:-----------------|
| `work_mem`             | 최소 `8 MB`  | 이 값은 Linux 패키지 기본값입니다. 대규모 배포에서 쿼리가 임시 파일을 생성하면 이 설정을 늘려야 합니다. |
| `maintenance_work_mem` | 최소 `64 MB` | 더 큰 데이터베이스 서버의 경우 [더 필요합니다](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8377#note_1728173087). |
| `max_connections`      | 최소 `400`   | GitLab 구성 요소를 기반으로 계산합니다. 자세한 지침을 보려면 [PostgreSQL 조정](../administration/postgresql/tune.md) 페이지를 참조합니다. |
| `shared_buffers`       | 최소 `2 GB`  | 더 큰 데이터베이스 서버의 경우 더 필요합니다. Linux 패키지 기본값은 서버 RAM의 25%로 설정됩니다. |
| `statement_timeout`    | 15000~60000 | 명령문 시간 초과는 잠금 및 데이터베이스가 새 클라이언트를 거부하는 이슈를 방지합니다. 15~60초(15000~60000밀리초) 범위의 값을 사용합니다. 여기서 1분은 Puma 랙 시간 초과 설정과 일치합니다. |
| `hot_standby_feedback` | `on` | 여러 노드와 [데이터베이스 로드 밸런싱](../administration/postgresql/database_load_balancing.md#configuring-database-load-balancing)이 구성된 경우 모든 복제본 노드에 `hot_standby_feedback`가 활성화되어 있는지 확인하여 지연 축적을 방지합니다. |

모든 데이터베이스가 아닌 특정 데이터베이스에 대해 일부 PostgreSQL 설정을 구성할 수 있습니다.

- 동일한 서버에서 여러 데이터베이스를 호스팅할 때 특정 데이터베이스로 구성을 제한할 수 있습니다.
- 구성을 적용할 위치에 대한 지침을 보려면 데이터베이스 관리자 또는 공급업체에 문의합니다.
- GCP Cloud SQL의 경우 특정 데이터베이스 또는 사용자에 대해 `statement_timeout`을 설정할 수 있지만 [데이터베이스 플래그로](https://cloud.google.com/sql/docs/postgres/flags#list-flags-postgres)는 설정할 수 없습니다. 예를 들어: `ALTER DATABASE gitlab SET statement_timeout = '60s';`

## Puma {#puma}

권장 [Puma](https://puma.io/) 설정은 [설치](install_methods.md)에 따라 다릅니다. 기본적으로 Linux 패키지는 권장 설정을 사용합니다.

Puma 설정을 조정하려면:

- Linux 패키지의 경우 [Puma 설정](../administration/operations/puma.md)을 참조합니다.
- GitLab Helm 차트의 경우 [`webservice` 차트](https://docs.gitlab.com/charts/charts/gitlab/webservice/)를 참조합니다.

### 작업자 {#workers}

권장 Puma 작업자 수는 주로 CPU 및 메모리 용량에 따라 다릅니다. 기본적으로 Linux 패키지는 권장 작업자 수를 사용합니다. 이 수가 계산되는 방식에 대한 자세한 내용은 [`puma.rb`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/files/gitlab-cookbooks/gitlab/libraries/puma.rb?ref_type=heads#L46-69)를 참조합니다.

노드는 절대 2개 미만의 Puma 작업자를 가져야 하지 않습니다. 예를 들어 노드는 다음을 가져야 합니다:

- 2개 CPU 코어 및 8GB 메모리용 2개의 작업자
- 4개 CPU 코어 및 4GB 메모리용 2개의 작업자
- 4개 CPU 코어 및 8GB 메모리용 4개의 작업자
- 8개 CPU 코어 및 8GB 메모리용 6개의 작업자
- 8개 CPU 코어 및 16GB 메모리용 8개의 작업자

기본적으로 각 Puma 작업자는 1.2GB의 메모리로 제한됩니다. [이 설정을 조정](../administration/operations/puma.md#tuning-memory-use)할 수 있습니다 `/etc/gitlab/gitlab.rb`.

충분한 CPU 및 메모리 용량이 있으면 Puma 작업자 수를 늘릴 수도 있습니다. 더 많은 작업자는 응답 시간을 단축하고 병렬 요청을 처리하는 능력을 향상합니다. [설치](install_methods.md)에 최적의 작업자 수를 확인하기 위해 테스트를 실행합니다.

### 스레드 {#threads}

권장 Puma 스레드 수는 총 시스템 메모리에 따라 다릅니다. 노드는 다음을 사용해야 합니다:

- 최대 2GB 메모리가 있는 운영 체제의 경우 1개의 스레드
- 2GB보다 많은 메모리가 있는 운영 체제의 경우 4개의 스레드

더 많은 스레드는 과도한 스왑을 발생시키고 성능을 저하시킵니다.

## Redis {#redis}

[Redis](https://redis.io/) 또는 [Valkey](https://valkey.io/)는 모든 사용자 세션과 배경 작업을 저장하며 평균적으로 사용자당 약 25KB가 필요합니다.

Redis 7.2 또는 Valkey 7.2가 필요합니다. 수명 종료 날짜에 대한 자세한 내용은 [Redis 설명서](https://redis.io/docs/latest/operate/oss_and_stack/install/version-mgmt/)를 참조합니다.

- 독립 실행형 인스턴스(고가용성 포함 또는 미포함)를 사용합니다. Redis 클러스터는 지원되지 않습니다.
- [제거 정책](../administration/redis/replication_and_failover_external.md#setting-the-eviction-policy)을 적절히 설정합니다.

## Sidekiq {#sidekiq}

[Sidekiq](https://sidekiq.org/)은 배경 작업을 위해 다중 스레드 프로세스를 사용합니다. 이 프로세스는 초기에 200MB 이상의 메모리를 사용하며 메모리 누수로 인해 시간이 지남에 따라 증가할 수 있습니다.

10,000명 이상의 청구 가능한 사용자가 있는 매우 활동적인 서버에서 Sidekiq 프로세스는 1GB 이상의 메모리를 사용할 수 있습니다.

## Prometheus {#prometheus}

기본적으로 [Prometheus](https://prometheus.io)와 관련 내보내기는 GitLab을 모니터링하기 위해 활성화됩니다. 이러한 프로세스는 약 200MB의 메모리를 사용합니다.

자세한 내용은 [Prometheus를 사용한 GitLab 모니터링](../administration/monitoring/prometheus/_index.md)을 참조합니다.

## 지원되는 웹 브라우저 {#supported-web-browsers}

GitLab은 다음의 웹 브라우저를 지원합니다:

- [Mozilla Firefox](https://www.mozilla.org/en-US/firefox/new/)
- [Google Chrome](https://www.google.com/chrome/)
- [Chromium](https://www.chromium.org/getting-involved/dev-channel/)
- [Apple Safari](https://www.apple.com/safari/)
- [Microsoft Edge](https://www.microsoft.com/en-us/edge?form=MA13QK)

GitLab은 다음을 지원합니다:

- 이러한 브라우저의 가장 최근의 2개 주요 버전
- 지원되는 주요 버전의 현재 경미한 버전

이러한 브라우저에서 JavaScript를 비활성화한 상태로 GitLab을 실행하는 것은 지원되지 않습니다.

## 관련 항목 {#related-topics}

- [GitLab 러너 설치](https://docs.gitlab.com/runner/install/)
- [설치 보안](../security/_index.md)
