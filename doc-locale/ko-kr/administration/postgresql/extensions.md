---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: PostgreSQL 확장 관리
description: GitLab Self-Managed에 필요한 PostgreSQL 확장 및 권장 확장을 설치합니다.
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab은 모든 데이터베이스에 특정 PostgreSQL 확장을 요구합니다. 필요한 확장과 최소 GitLab 버전 목록은 [PostgreSQL 요구 사항](../../install/requirements.md#extensions)을 참조하세요.

확장을 설치하려면 PostgreSQL에 슈퍼사용자 권한이 필요합니다. GitLab 데이터베이스 사용자는 일반적으로 슈퍼사용자가 아니므로 GitLab을 업그레이드하기 전에 확장을 수동으로 설치해야 합니다.

## 필요한 확장 설치 {#install-required-extensions}

1. 슈퍼사용자를 사용하여 GitLab PostgreSQL 데이터베이스에 연결합니다. 예를 들면 다음과 같습니다:

   ```shell
   sudo gitlab-psql -d gitlabhq_production
   ```

1. 확장(`btree_gist`, 이 예에서)을 [`CREATE EXTENSION`](https://www.postgresql.org/docs/16/sql-createextension.html)을 사용하여 설치합니다:

   ```sql
   CREATE EXTENSION IF NOT EXISTS btree_gist
   ```

1. 설치된 확장을 확인합니다:

   ```shell
   gitlabhq_production=# \dx
   ```

일부 시스템에서는 특정 확장을 사용할 수 있도록 추가 패키지(`postgresql-contrib`, 예를 들어)를 설치해야 할 수도 있습니다.

## pg_stat_statements 활성화 {#enable-pg_stat_statements}

`pg_stat_statements`은 느린 데이터베이스 쿼리를 문제 해결할 때 권장됩니다. 활성화하려면 슈퍼사용자 권한과 PostgreSQL 재시작이 필요합니다.

1. `pg_stat_statements`을 `postgresql.conf`의 `shared_preload_libraries`에 추가합니다. Linux 패키지 설치의 경우 `/etc/gitlab/gitlab.rb`에 다음을 추가합니다:

   ```ruby
   postgresql['shared_preload_libraries'] = 'pg_stat_statements'
   ```

1. PostgreSQL을 재시작합니다.
1. 슈퍼사용자로서 확장을 생성합니다:

   ```sql
   CREATE EXTENSION IF NOT EXISTS pg_stat_statements
   ```

더 자세한 내용은 [선택적 쿼리 통계 데이터 활성화](../raketasks/maintenance.md#enable-optional-query-statistics-data)를 참조하세요.

## 문제 해결 {#troubleshooting}

PostgreSQL 확장으로 작업할 때 다음 문제가 발생할 수 있습니다.

### 확장이 없어서 마이그레이션이 실패함 {#migration-fails-because-an-extension-is-missing}

확장이 없어서 데이터베이스 마이그레이션이 실패한 경우 슈퍼사용자로서 수동으로 설치한 다음 마이그레이션을 다시 실행합니다:

```shell
sudo gitlab-rake db:migrate
```
