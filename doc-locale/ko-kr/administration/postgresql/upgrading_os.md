---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: PostgreSQL의 운영 체제 업그레이드
---

> [!warning]
> [Geo](../geo/_index.md)는 PostgreSQL 데이터베이스를 한 운영 체제에서 다른 운영 체제로 마이그레이션하는 데 사용할 수 없습니다. 이렇게 시도하면 보조 사이트가 100% 복제된 것으로 나타날 수 있지만 실제로는 일부 데이터가 복제되지 않아 데이터 손실이 발생합니다. Geo는 PostgreSQL 스트리밍 복제에 의존하기 때문이며, 이는 이 문서에 설명된 제한 사항으로 인해 문제가 발생합니다. [Geo 문제 해결 - OS 로케일 데이터 호환성 확인](../geo/replication/troubleshooting/common.md#check-os-locale-data-compatibility)도 참조하세요.

PostgreSQL이 실행되는 운영 체제를 업그레이드하면 [로케일 데이터의 변경으로 인해 데이터베이스 인덱스가 손상될 수 있습니다](https://wiki.postgresql.org/wiki/Locale_data_changes). 특히 `glibc` 2.28로의 업그레이드는 이 문제를 유발할 가능성이 높습니다. 이 문제를 방지하려면 다음 옵션 중 하나를 사용하여 마이그레이션하세요. 대략 복잡도 순입니다:

- 권장됩니다. [백업 및 복원](#backup-and-restore).
- 권장됩니다. [모든 인덱스 재구성](#rebuild-all-indexes).
- [영향을 받는 인덱스만 재구성](#rebuild-only-affected-indexes).

마이그레이션을 시도하기 전에 반드시 백업하고 프로덕션과 유사한 환경에서 마이그레이션 프로세스를 검증하세요. 다운타임 길이가 문제가 될 수 있으면 프로덕션과 유사한 환경에서 프로덕션 데이터의 복사본으로 다양한 접근 방식을 시간을 맞춰 고려하세요.

확장된 GitLab 환경을 실행 중이고 PostgreSQL이 실행되는 노드에 다른 서비스가 실행되지 않으면 PostgreSQL 노드의 운영 체제를 단독으로 업그레이드하는 것이 좋습니다. 복잡도와 위험을 줄이려면 프로시저를 다른 변경 사항과 함께 결합하지 마세요. 특히 해당 변경 사항이 Puma 또는 Sidekiq만 실행하는 노드의 운영 체제 업그레이드와 같이 다운타임이 필요하지 않은 경우에는 더욱 그렇습니다.

GitLab에서 이 문제를 해결하는 방법에 대한 자세한 정보는 [에픽 8573](https://gitlab.com/groups/gitlab-org/-/epics/8573)을 참조하세요.

## 백업 및 복원 {#backup-and-restore}

백업 및 복원은 인덱스를 포함한 전체 데이터베이스를 다시 생성합니다.

1. 예약된 다운타임 윈도우를 잡습니다. 모든 노드에서 불필요한 GitLab 서비스를 중지합니다:

   ```shell
   gitlab-ctl stop
   gitlab-ctl start postgresql
   ```

1. `pg_dump` 또는 [GitLab 백업 도구(모든 데이터 유형을 `db`로 제외)](../backup_restore/backup_gitlab.md#excluding-specific-data-from-the-backup)로 PostgreSQL 데이터베이스를 백업합니다(데이터베이스만 백업됨).
1. 모든 PostgreSQL 노드에서 OS를 업그레이드합니다.
1. 모든 PostgreSQL 노드에서 운영 체제를 업그레이드한 후 [GitLab 패키지 소스를 업데이트](../../update/package/_index.md)합니다.
1. 모든 PostgreSQL 노드에서 동일한 GitLab 버전의 새 GitLab 패키지를 설치합니다.
1. 백업에서 PostgreSQL 데이터베이스를 복원합니다.
1. 모든 노드에서 GitLab을 시작합니다.

장점:

- 간단합니다.
- 인덱스 및 테이블의 데이터베이스 블로트를 제거하여 디스크 사용량을 줄입니다.

단점:

- 다운타임은 데이터베이스 크기에 따라 증가하며 어느 시점에서 문제가 될 수 있습니다. 많은 요소에 따라 다르지만 데이터베이스가 100GB를 초과하면 약 24시간이 소요될 수 있습니다.

### 백업 및 복원(Geo 보조 사이트 포함) {#backup-and-restore-with-geo-secondary-sites}

1. 예약된 다운타임 윈도우를 잡습니다. 모든 사이트의 모든 노드에서 불필요한 GitLab 서비스를 중지합니다:

   ```shell
   gitlab-ctl stop
   gitlab-ctl start postgresql
   ```

1. 주 사이트에서 `pg_dump` 또는 [GitLab 백업 도구(모든 데이터 유형을 `db`로 제외)](../backup_restore/backup_gitlab.md#excluding-specific-data-from-the-backup)로 PostgreSQL 데이터베이스를 백업합니다(데이터베이스만 백업됨).
1. 모든 사이트의 모든 PostgreSQL 노드에서 OS를 업그레이드합니다.
1. 모든 사이트의 모든 PostgreSQL 노드에서 운영 체제를 업그레이드한 후 [GitLab 패키지 소스를 업데이트](../../update/package/_index.md)합니다.
1. 모든 사이트의 모든 PostgreSQL 노드에서 동일한 GitLab 버전의 새 GitLab 패키지를 설치합니다.
1. 주 사이트에서 백업에서 PostgreSQL 데이터베이스를 복원합니다.
1. 선택적으로 주 사이트 사용을 시작합니다. 보조 사이트를 웜 스탠바이로 사용할 수 없을 위험이 있습니다.
1. 보조 사이트에 대한 PostgreSQL 스트리밍 복제를 다시 설정합니다.
1. 보조 사이트가 사용자로부터 트래픽을 받으면 GitLab을 시작하기 전에 읽기 복제본 데이터베이스가 따라잡도록 합니다.
1. 모든 사이트의 모든 노드에서 GitLab을 시작합니다.

## 모든 인덱스 재구성 {#rebuild-all-indexes}

[모든 인덱스 재구성](https://www.postgresql.org/docs/16/sql-reindex.html).

1. 예약된 다운타임 윈도우를 잡습니다. 모든 노드에서 불필요한 GitLab 서비스를 중지합니다:

   ```shell
   gitlab-ctl stop
   gitlab-ctl start postgresql
   ```

1. 모든 PostgreSQL 노드에서 OS를 업그레이드합니다.
1. 모든 PostgreSQL 노드에서 운영 체제를 업그레이드한 후 [GitLab 패키지 소스를 업데이트](../../update/package/_index.md)합니다.
1. 모든 PostgreSQL 노드에서 동일한 GitLab 버전의 새 GitLab 패키지를 설치합니다.
1. [데이터베이스 콘솔](../troubleshooting/postgresql.md#start-a-database-console)에서 모든 인덱스를 재구성합니다:

   ```sql
   SET statement_timeout = 0;
   REINDEX DATABASE gitlabhq_production;
   ```

1. 데이터베이스를 재인덱싱한 후 모든 영향을 받는 데이터 정렬에 대해 버전을 새로 고쳐야 합니다. 현재 데이터 정렬 버전을 기록하도록 시스템 카탈로그를 업데이트합니다:

   ```sql
   ALTER DATABASE gitlabhq_production REFRESH COLLATION VERSION;
   ```

   `template1` 또는 `postgres`와 같은 시스템 데이터베이스도 PostgreSQL이 시작될 때 데이터 정렬 문제가 발생할 수 있습니다. 오류 메시지의 힌트를 확인하고 이러한 데이터베이스의 데이터 정렬도 새로 고칩니다.

1. 모든 노드에서 GitLab을 시작합니다.

장점:

- 간단합니다.
- 여러 요소에 따라 백업 및 복원보다 빠를 수 있습니다.
- 인덱스의 데이터베이스 블로트를 제거하여 디스크 사용량을 줄입니다.

단점:

- 다운타임은 데이터베이스 크기에 따라 증가하며 어느 시점에서 문제가 될 수 있습니다.

### 모든 인덱스 재구성(Geo 보조 사이트 포함) {#rebuild-all-indexes-with-geo-secondary-sites}

1. 예약된 다운타임 윈도우를 잡습니다. 모든 사이트의 모든 노드에서 불필요한 GitLab 서비스를 중지합니다:

   ```shell
   gitlab-ctl stop
   gitlab-ctl start postgresql
   ```

1. 모든 PostgreSQL 노드에서 OS를 업그레이드합니다.
1. 모든 PostgreSQL 노드에서 운영 체제를 업그레이드한 후 [GitLab 패키지 소스를 업데이트](../../update/package/_index.md)합니다.
1. 모든 PostgreSQL 노드에서 동일한 GitLab 버전의 새 GitLab 패키지를 설치합니다.
1. 주 사이트에서 [데이터베이스 콘솔](../troubleshooting/postgresql.md#start-a-database-console)로 모든 인덱스를 재구성합니다:

   ```sql
   SET statement_timeout = 0;
   REINDEX DATABASE gitlabhq_production;
   ```

1. 데이터베이스를 재인덱싱한 후 모든 영향을 받는 데이터 정렬에 대해 버전을 새로 고쳐야 합니다. 현재 데이터 정렬 버전을 기록하도록 시스템 카탈로그를 업데이트합니다:

   ```sql
   ALTER DATABASE <database_name> REFRESH COLLATION VERSION;
   ```

1. 보조 사이트가 사용자로부터 트래픽을 받으면 GitLab을 시작하기 전에 읽기 복제본 데이터베이스가 따라잡도록 합니다.
1. 모든 사이트의 모든 노드에서 GitLab을 시작합니다.

## 영향을 받는 인덱스만 재구성 {#rebuild-only-affected-indexes}

이는 GitLab.com에 사용되는 접근 방식과 유사합니다. 이 프로세스와 다양한 유형의 인덱스가 처리된 방식에 대해 자세히 알아보려면 [PostgreSQL 데이터베이스 클러스터의 운영 체제 업그레이드](https://about.gitlab.com/blog/upgrading-database-os/)에 대한 블로그 게시물을 참조하세요.

1. 예약된 다운타임 윈도우를 잡습니다. 모든 노드에서 불필요한 GitLab 서비스를 중지합니다:

   ```shell
   gitlab-ctl stop
   gitlab-ctl start postgresql
   ```

1. 모든 PostgreSQL 노드에서 OS를 업그레이드합니다.
1. 모든 PostgreSQL 노드에서 운영 체제를 업그레이드한 후 [GitLab 패키지 소스를 업데이트](../../update/package/_index.md)합니다.
1. 모든 PostgreSQL 노드에서 동일한 GitLab 버전의 새 GitLab 패키지를 설치합니다.
1. [영향을 받는 인덱스 결정](https://wiki.postgresql.org/wiki/Locale_data_changes#What_indexes_are_affected).
1. [데이터베이스 콘솔](../troubleshooting/postgresql.md#start-a-database-console)에서 영향을 받는 각 인덱스를 재인덱싱합니다:

   ```sql
   SET statement_timeout = 0;
   REINDEX INDEX <index name> CONCURRENTLY;
   ```

1. 잘못된 인덱스를 재인덱싱한 후 데이터 정렬을 새로 고쳐야 합니다. 현재 데이터 정렬 버전을 기록하도록 시스템 카탈로그를 업데이트합니다:

   ```sql
   ALTER DATABASE <database_name> REFRESH COLLATION VERSION;
   ```

1. 모든 노드에서 GitLab을 시작합니다.

장점:

- 다운타임은 영향을 받지 않는 인덱스를 재구성하는 데 사용되지 않습니다.

단점:

- 실수할 가능성이 더 많습니다.
- 마이그레이션 중 예상치 못한 문제를 처리하려면 PostgreSQL에 대한 전문 지식이 필요합니다.
- 데이터베이스 블로트를 유지합니다.

### 영향을 받는 인덱스만 재구성(Geo 보조 사이트 포함) {#rebuild-only-affected-indexes-with-geo-secondary-sites}

1. 예약된 다운타임 윈도우를 잡습니다. 모든 사이트의 모든 노드에서 불필요한 GitLab 서비스를 중지합니다:

   ```shell
   gitlab-ctl stop
   gitlab-ctl start postgresql
   ```

1. 모든 PostgreSQL 노드에서 OS를 업그레이드합니다.
1. 모든 PostgreSQL 노드에서 운영 체제를 업그레이드한 후 [GitLab 패키지 소스를 업데이트](../../update/package/_index.md)합니다.
1. 모든 PostgreSQL 노드에서 동일한 GitLab 버전의 새 GitLab 패키지를 설치합니다.
1. [영향을 받는 인덱스 결정](https://wiki.postgresql.org/wiki/Locale_data_changes#What_indexes_are_affected).
1. 주 사이트에서 [데이터베이스 콘솔](../troubleshooting/postgresql.md#start-a-database-console)로 영향을 받는 각 인덱스를 재인덱싱합니다:

   ```sql
   SET statement_timeout = 0;
   REINDEX INDEX <index name> CONCURRENTLY;
   ```

1. 잘못된 인덱스를 재인덱싱한 후 데이터 정렬을 새로 고쳐야 합니다. 현재 데이터 정렬 버전을 기록하도록 시스템 카탈로그를 업데이트합니다:

   ```sql
   ALTER DATABASE <database_name> REFRESH COLLATION VERSION;
   ```

1. 기존 PostgreSQL 스트리밍 복제는 재인덱스 변경 사항을 읽기 복제본 데이터베이스로 복제해야 합니다.
1. 모든 사이트의 모든 노드에서 GitLab을 시작합니다.

## `glibc` 버전 확인 {#checking-glibc-versions}

`glibc`의 버전을 확인하려면 `ldd --version`를 실행하세요.

다음 표는 다양한 운영 체제에 대해 제공되는 `glibc` 버전을 보여줍니다:

| 운영 체제    | `glibc` 버전 |
|---------------------|-----------------|
| CentOS 7            | 2.17            |
| RedHat Enterprise 8 | 2.28            |
| RedHat Enterprise 9 | 2.34            |
| Ubuntu 18.04        | 2.27            |
| Ubuntu 20.04        | 2.31            |
| Ubuntu 22.04        | 2.35            |
| Ubuntu 24.04        | 2.39            |

예를 들어 CentOS 7에서 RedHat Enterprise 8로 업그레이드한다고 가정합니다. 이 경우 이 업그레이드된 운영 체제에서 PostgreSQL을 사용하려면 언급된 두 가지 접근 방식 중 하나를 사용해야 합니다. `glibc`이(가) 2.17에서 2.28로 업그레이드되기 때문입니다. 데이터 정렬 변경을 제대로 처리하지 못하면 GitLab에서 태그를 사용하여 작업을 선택하지 않는 러너 등 심각한 오류가 발생합니다.

반면에 PostgreSQL이 이미 `glibc` 2.28 이상에서 문제 없이 실행 중이었다면 인덱스는 추가 조치 없이 계속 작동해야 합니다. 예를 들어 RedHat Enterprise 8(`glibc` 2.28)에서 PostgreSQL을 한동안 실행 중이고 RedHat Enterprise 9(`glibc` 2.34)로 업그레이드하려는 경우 데이터 정렬 관련 문제가 없어야 합니다.

### `glibc` 데이터 정렬 버전 확인 {#verifying-glibc-collation-versions}

PostgreSQL 13 이상의 경우 이 SQL 쿼리를 사용하여 데이터베이스 데이터 정렬 버전이 시스템과 일치하는지 확인할 수 있습니다:

```sql
SELECT collname AS COLLATION_NAME,
       collversion AS VERSION,
       pg_collation_actual_version(oid) AS actual_version
FROM pg_collation
WHERE collprovider = 'c';
```

### 데이터 정렬 예 일치 {#matching-collation-example}

예를 들어 Ubuntu 22.04 시스템에서 올바르게 인덱싱된 시스템의 출력은 다음과 같습니다:

```sql
gitlabhq_production=# SELECT collname AS COLLATION_NAME,
       collversion AS VERSION,
       pg_collation_actual_version(oid) AS actual_version
FROM pg_collation
WHERE collprovider = 'c';
 collation_name | version | actual_version
----------------+---------+----------------
 C              |         |
 POSIX          |         |
 ucs_basic      |         |
 C.utf8         |         |
 en_US.utf8     | 2.35    | 2.35
 en_US          | 2.35    | 2.35
(6 rows)
```

### 데이터 정렬 예 불일치 {#mismatched-collation-example}

반면에 Ubuntu 18.04에서 22.04로 재인덱싱 없이 업그레이드한 경우 다음과 같이 표시될 수 있습니다:

```sql
gitlabhq_production=# SELECT collname AS COLLATION_NAME,
       collversion AS VERSION,
       pg_collation_actual_version(oid) AS actual_version
FROM pg_collation
WHERE collprovider = 'c';
 collation_name | version | actual_version
----------------+---------+----------------
 C              |         |
 POSIX          |         |
 ucs_basic      |         |
 C.utf8         |         |
 en_US.utf8     | 2.27    | 2.35
 en_US          | 2.27    | 2.35
(6 rows)
```

## 스트리밍 복제 {#streaming-replication}

손상된 인덱스 문제는 PostgreSQL 스트리밍 복제에 영향을 미칩니다. 다른 로케일 데이터가 있는 복제본에 대한 읽기를 허용하기 전에 [모든 인덱스 재구성](#rebuild-all-indexes) 또는 [영향을 받는 인덱스만 재구성](#rebuild-only-affected-indexes)해야 합니다.

## 추가 Geo 변형 {#additional-geo-variations}

이전에 문서화된 업그레이드 프로시저는 확정되지 않습니다. Geo를 사용하면 중복 인프라가 존재하기 때문에 잠재적으로 더 많은 옵션이 있습니다. 사용 사례에 맞게 수정하는 것을 고려할 수 있지만 추가된 복잡도와 비교하여 신중하게 고려하세요. 다음은 몇 가지 예입니다:

주 사이트 및 다른 보조 사이트의 OS 업그레이드 중 재해 발생 시 보조 사이트를 웜 스탠바이로 예약합니다:

1. 보조 사이트의 데이터를 주 사이트의 변경 사항으로부터 격리합니다:  보조 사이트를 일시 중지합니다.
1. 주 사이트에서 OS 업그레이드를 수행합니다.
1. OS 업그레이드가 실패하고 주 사이트를 복구할 수 없으면 보조 사이트를 승격하고 사용자를 이동한 후 나중에 다시 시도합니다. 이렇게 하면 최신 상태의 보조 사이트가 없게 됩니다.

OS 업그레이드 중에 사용자에게 GitLab에 대한 읽기 전용 액세스를 제공합니다(부분 다운타임):

1. 주 사이트에서 중지 대신 [유지 보수 모드](../maintenance_mode/_index.md)를 활성화합니다.
1. 보조 사이트를 승격하지만 아직 사용자를 이동하지 마세요.
1. 승격된 사이트에서 OS 업그레이드를 수행합니다.
1. 이전 주 사이트 대신 승격된 사이트로 사용자를 이동합니다.
1. 이전 주 사이트를 새 보조 사이트로 설정합니다.

> [!warning]
> 보조 사이트가 이미 데이터베이스의 읽기 복제본을 가지고 있지만 승격 전에 운영 체제를 업그레이드할 수 없습니다. 시도하면 손상된 인덱스로 인해 보조 사이트가 일부 Git 리포지토리 또는 파일의 복제를 놓칠 수 있습니다. [스트리밍 복제](#streaming-replication)를 참조하세요.
