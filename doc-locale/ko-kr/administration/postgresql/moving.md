---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 데이터베이스를 다른 PostgreSQL 인스턴스로 이동하기
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

데이터베이스를 한 PostgreSQL 인스턴스에서 다른 인스턴스로 이동해야 하는 경우가 있습니다. 예를 들어, AWS Aurora를 사용 중이며 Database Load Balancing을 활성화할 준비가 되어 있다면 데이터베이스를 RDS for PostgreSQL로 이동해야 합니다.

데이터베이스를 한 인스턴스에서 다른 인스턴스로 이동하려면:

1. 소스 및 대상 PostgreSQL 엔드포인트 정보를 수집합니다:

   ```shell
   SRC_PGHOST=<source postgresql host>
   SRC_PGUSER=<source postgresql user>

   DST_PGHOST=<destination postgresql host>
   DST_PGUSER=<destination postgresql user>
   ```

1. GitLab을 중지합니다:

   ```shell
   sudo gitlab-ctl stop
   ```

1. 소스에서 데이터베이스를 덤프합니다:

   ```shell
   /opt/gitlab/embedded/bin/pg_dump -h $SRC_PGHOST -U $SRC_PGUSER -c -C -f gitlabhq_production.sql gitlabhq_production
   /opt/gitlab/embedded/bin/pg_dump -h $SRC_PGHOST -U $SRC_PGUSER -c -C -f praefect_production.sql praefect_production
   ```

   > [!note]
   > `pg_dump`를 수행한 후 복원할 때 드물게 데이터베이스 성능 문제가 발생할 수 있습니다. 이는 `pg_dump`가 [쿼리 계획을 결정하기 위해 옵티마이저에서 사용하는 통계](https://www.postgresql.org/docs/16/app-pgdump.html)를 포함하지 않기 때문에 발생할 수 있습니다. 복원 후 성능이 저하되면 문제가 되는 쿼리를 찾은 후 쿼리에 사용되는 테이블에서 ANALYZE를 실행하여 문제를 해결합니다.

1. 데이터베이스를 대상으로 복원합니다(이렇게 하면 같은 이름의 기존 데이터베이스가 덮어씌워집니다):

   ```shell
   /opt/gitlab/embedded/bin/psql -h $DST_PGHOST -U $DST_PGUSER -f praefect_production.sql postgres
   /opt/gitlab/embedded/bin/psql -h $DST_PGHOST -U $DST_PGUSER -f gitlabhq_production.sql postgres
   ```

1. 선택사항. PgBouncer를 사용하지 않는 데이터베이스에서 PgBouncer를 사용하는 데이터베이스로 마이그레이션하는 경우 애플리케이션 데이터베이스(일반적으로 `gitlabhq_production`)에 [`pg_shadow_lookup` 함수](../gitaly/praefect/configure.md#manual-database-setup)를 수동으로 추가해야 합니다.
1. GitLab 애플리케이션 서버를 `/etc/gitlab/gitlab.rb` 파일의 대상 PostgreSQL 인스턴스에 대한 적절한 연결 정보로 구성합니다:

   ```ruby
   gitlab_rails['db_host'] = '<destination postgresql host>'
   ```

   GitLab 다중 노드 설정에 대한 자세한 내용은 [참조 아키텍처](../reference_architectures/_index.md)를 참조합니다.

1. 변경 사항을 적용하려면 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. GitLab을 다시 시작합니다:

   ```shell
   sudo gitlab-ctl start
   ```
