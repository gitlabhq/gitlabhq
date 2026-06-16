---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 외부 PostgreSQL 데이터베이스 업그레이드
---

PostgreSQL 데이터베이스 엔진을 업그레이드할 때는 PostgreSQL 커뮤니티와 클라우드 제공자가 권장하는 모든 단계를 따르는 것이 중요합니다. PostgreSQL 데이터베이스에는 두 가지 유형의 업그레이드가 있습니다:

- 부 버전 업그레이드:  이는 버그 및 보안 수정만 포함합니다. 기존 애플리케이션 데이터베이스 모델과 항상 이전 버전과 호환됩니다.

  부 버전 업그레이드 프로세스는 PostgreSQL 바이너리를 교체하고 데이터베이스 서비스를 다시 시작하는 것으로 구성됩니다. 데이터 디렉터리는 변경되지 않습니다.

- 주 버전 업그레이드:  내부 저장소 형식과 데이터베이스 카탈로그를 변경합니다. 결과적으로 쿼리 옵티마이저에서 사용하는 개체 통계 [는 새 버전으로 전송되지 않으며](https://www.postgresql.org/docs/16/pgupgrade.html) `ANALYZE`로 다시 빌드해야 합니다.

  문서화된 주 버전 업그레이드 프로세스를 따르지 않으면 데이터베이스 성능 저하 및 데이터베이스 서버의 높은 CPU 사용으로 이어지는 경우가 많습니다.

모든 주요 클라우드 제공자는 `pg_upgrade` 유틸리티를 사용하여 데이터베이스 인스턴스의 제자리 주 버전 업그레이드를 지원합니다. 그러나 성능 저하 또는 데이터베이스 중단의 위험을 줄이기 위해 업그레이드 전후 단계를 따라야 합니다.

외부 데이터베이스 플랫폼의 주 버전 업그레이드 단계를 주의 깊게 읽으세요:

- [Amazon RDS for PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_UpgradeDBInstance.PostgreSQL.html#USER_UpgradeDBInstance.PostgreSQL.MajorVersion.Process)
- [Azure Database for PostgreSQL Flexible Server](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-major-version-upgrade)
- [Google Cloud SQL for PostgreSQL](https://cloud.google.com/sql/docs/postgres/upgrade-major-db-version-inplace)
- [PostgreSQL 커뮤니티 `pg_upgrade`](https://www.postgresql.org/docs/16/pgupgrade.html)

## 주 버전 업그레이드 후 항상 데이터베이스를 `ANALYZE`하기 {#always-analyze-your-database-after-a-major-version-upgrade}

주 버전 업그레이드 후 `pg_statistic` 테이블을 새로 고치기 위해 [`ANALYZE` 작업](https://www.postgresql.org/docs/16/sql-analyze.html) 을 실행해야 하며, 옵티마이저 통계는 [`pg_upgrade`에서 전송되지 않기](https://www.postgresql.org/docs/16/pgupgrade.html) 때문입니다. 업그레이드된 PostgreSQL 서비스/인스턴스/클러스터의 모든 데이터베이스에 대해 이를 수행해야 합니다.

유지 보수 기간을 계획할 때 `ANALYZE` 기간을 포함해야 하며, 이 작업은 GitLab 성능을 크게 저하시킬 수 있기 때문입니다.

`ANALYZE` 작업을 빠르게 하려면 [`vacuumdb` 유틸리티](https://www.postgresql.org/docs/16/app-vacuumdb.html)를 `--analyze-only --jobs=njobs`와 함께 사용하여 `ANALYZE` 명령을 병렬로 실행하고 `njobs` 명령을 동시에 실행합니다.
