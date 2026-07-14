---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: PostgreSQL
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

이 페이지에는 GitLab 지원팀이 문제 해결 시 사용하는 PostgreSQL 정보가 포함되어 있습니다. GitLab은 지원팀이 수집한 지식을 누구나 활용할 수 있도록 이 정보를 공개합니다.

> [!warning]
> 여기에 설명된 일부 절차는 GitLab 인스턴스를 손상시킬 수 있습니다. 위험을 감수하고 사용하세요.

[유료 요금제](https://about.gitlab.com/pricing/) 를 사용 중이고 이 명령어 사용 방법을 잘 모르는 경우, 발생한 문제 해결을 위해 [지원팀에 문의](https://about.gitlab.com/support/)하세요.

## 데이터베이스 콘솔 시작 {#start-a-database-console}

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

권장 대상:

- 단일 노드 인스턴스
- 확장되거나 하이브리드인 환경, Patroni 노드에서(일반적으로 리더 노드)
- 확장되거나 하이브리드인 환경, PostgreSQL 서비스가 실행 중인 서버에서

```shell
sudo gitlab-psql
```

단일 노드 인스턴스 또는 웹이나 Sidekiq 노드에서는 Rails 데이터베이스 콘솔도 사용할 수 있지만, 초기화 시간이 더 오래 걸립니다:

```shell
sudo gitlab-rails dbconsole --database main
```

{{< /tab >}}

{{< tab title="Docker" >}}

```shell
docker exec -it <container-id> gitlab-psql
```

{{< /tab >}}

{{< tab title="자체 컴파일됨(소스)" >}}

`psql`의 일부인 [PostgreSQL 설치](../../install/self_compiled/_index.md#7-database)에 포함된 명령어를 사용합니다.

```shell
sudo -u git -H psql -d gitlabhq_production
```

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

- 하이브리드 환경을 실행 중이고 PostgreSQL이 Linux 패키지 설치(Omnibus)에서 실행되는 경우, 권장되는 방법은 해당 서버에서 데이터베이스 콘솔을 로컬로 사용하는 것입니다. Linux 패키지 세부 사항을 참조하세요.
- 외부 타사 PostgreSQL 서비스에 포함된 콘솔을 사용합니다.
- 도구 상자 포드에서 `gitlab-rails dbconsole`을 실행합니다.
  - 세부 사항은 [Kubernetes 치트 시트](https://docs.gitlab.com/charts/troubleshooting/kubernetes_cheat_sheet/#gitlab-specific-kubernetes-information)를 참조하세요.

> [!note]
> 클라우드 네이티브 배포가 관리형 PostgreSQL 서비스(예: AWS RDS)를 사용하는 경우, 데이터베이스 구성 파일을 직접 수정할 수 없습니다. 대신 클라우드 서비스의 매개변수 그룹 또는 구성 인터페이스를 통해 PostgreSQL 매개변수를 구성합니다.

{{< /tab >}}

{{< /tabs >}}

콘솔을 종료하려면 `quit`을 입력합니다.

## 기타 GitLab PostgreSQL 설명서 {#other-gitlab-postgresql-documentation}

이 섹션은 GitLab 설명서의 다른 위치에 있는 정보로의 링크입니다.

### 절차 {#procedures}

- [Linux 패키지 설치를 위한 데이터베이스 절차](https://docs.gitlab.com/omnibus/settings/database/)(다음 포함):
  - SSL: 활성화, 비활성화 및 검증
  - WAL(Write Ahead Log) 아카이빙 활성화
  - 외부(Omnibus가 아닌) PostgreSQL 설치 사용 및 백업
  - TCP/IP에서 수신 대기, 소켓뿐만 아니라 또는 대신
  - 다른 위치에 데이터 저장
  - GitLab 데이터베이스 파괴적으로 재시드
  - 패키지된 PostgreSQL 업데이트에 대한 지침, 자동으로 발생하는 것을 중지하는 방법 포함
- [외부 PostgreSQL에 대한 정보](../postgresql/external.md)
- [외부 PostgreSQL을 사용하여 Geo 실행](../geo/setup/external_database.md)
- [HA로 구성된 PostgreSQL 실행 시 업그레이드](https://docs.gitlab.com/omnibus/settings/database/#upgrading-a-gitlab-ha-cluster)
- [CI 러너](../../ci/services/postgres.md) 내에서 PostgreSQL 사용
- Linux 패키지 개발 설명서에서 Linux 패키지 설치의 PostgreSQL 버전 관리
- [PostgreSQL 확장](../postgresql/replication_and_failover.md)
  - [문제 해결](../postgresql/replication_and_failover_troubleshooting.md) `gitlab-ctl patroni check-leader` 및 PgBouncer 오류 포함
- 개발자 데이터베이스 설명서, 일부는 프로덕션 사용에 적합하지 않습니다. 다음 포함:
  - EXPLAIN 계획 이해

## 지원 항목 {#support-topics}

### 데이터베이스 교착 상태 {#database-deadlocks}

참조:

- [푸시로 인스턴스가 폭주하면 교착 상태가 발생할 수 있습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/33650) GitLab 코드가 비정상적인 상황에서 이러한 유형의 예상치 못한 영향을 미칠 수 있는 방식에 대한 컨텍스트로 제공됩니다.

```plaintext
ERROR: deadlock detected
```

문제 [\#30528](https://gitlab.com/gitlab-org/gitlab/-/issues/30528)에서 세 가지 적용 가능한 타임아웃이 확인되었으며, 권장되는 설정은 다음과 같습니다:

```ini
deadlock_timeout = 5s
statement_timeout = 15s
idle_in_transaction_session_timeout = 60s
```

문제 [\#30528](https://gitlab.com/gitlab-org/gitlab/-/issues/30528)에서 인용:

<!-- vale gitlab_base.FutureTense = NO -->

> "교착 상태가 발생하고 짧은 시간 후 트랜잭션을 중단하여 해결하면, 이미 보유한 재시도 메커니즘이 교착 상태에 있는 작업을 다시 시도하게 되며, 연달아 여러 번 교착 상태가 발생할 가능성은 낮습니다."

<!-- vale gitlab_base.FutureTense = YES -->

> [!note]
> 지원팀의 타임아웃 재구성에 대한 일반적인 접근 방식(HTTP 스택에도 적용됨)은 이를 임시 해결 방법으로 수행하는 것이 수용 가능하다는 것입니다. 이것이 고객을 위해 GitLab을 사용 가능하게 만들면, 문제를 더 완전히 이해하고, 핫픽스를 구현하거나, 근본 원인을 해결하는 다른 변경을 수행할 시간을 버는 것입니다. 일반적으로 근본 원인이 해결된 후에는 타임아웃을 합리적인 기본값으로 복구해야 합니다.

이 경우, 개발팀에서 받은 지침은 `deadlock_timeout` 또는 `statement_timeout`를 제거하되 세 번째 설정은 60초로 유지하는 것입니다. `idle_in_transaction`를 설정하면 세션이 잠재적으로 며칠 동안 중지되는 것으로부터 데이터베이스를 보호합니다. [이 타임아웃을 GitLab.com에 도입하는 것과 관련된 문제](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/1053)에 대한 더 많은 논의가 있습니다.

PostgreSQL 기본값:

- `statement_timeout = 0` (안 함)
- `idle_in_transaction_session_timeout = 0` (안 함)

문제 [\#30528](https://gitlab.com/gitlab-org/gitlab/-/issues/30528)의 의견은 이 두 가지를 모든 Linux 패키지 설치에 대해 최소 몇 분으로 설정해야 함을 나타냅니다(무한정 중지되지 않도록). 그러나 `statement_timeout`의 15초는 매우 짧으며, 기본 인프라가 매우 우수한 경우에만 효과가 있습니다.

현재 설정을 확인하세요:

```shell
sudo gitlab-rails runner "c = ApplicationRecord.connection ; puts c.execute('SHOW statement_timeout').to_a ;
puts c.execute('SHOW deadlock_timeout').to_a ;
puts c.execute('SHOW idle_in_transaction_session_timeout').to_a ;"
```

응답하는 데 시간이 조금 걸릴 수 있습니다.

```ruby
{"statement_timeout"=>"1min"}
{"deadlock_timeout"=>"0"}
{"idle_in_transaction_session_timeout"=>"1min"}
```

이 설정은 `/etc/gitlab/gitlab.rb`에서 다음과 같이 업데이트할 수 있습니다:

```ruby
postgresql['deadlock_timeout'] = '5s'
postgresql['statement_timeout'] = '15s'
postgresql['idle_in_transaction_session_timeout'] = '60s'
```

저장된 후 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)하여 변경 사항을 적용하세요.

> [!note]
> 이것은 Linux 패키지 설정입니다. 고객의 PostgreSQL 설치 또는 Amazon RDS와 같은 외부 데이터베이스를 사용하는 경우, 이러한 값이 설정되지 않으며 외부에서 설정해야 합니다.

### 명령문 타임아웃 임시 변경 {#temporarily-changing-the-statement-timeout}

> [!warning]
> [PgBouncer](../postgresql/pgbouncer.md)가 활성화되면 다음 조언이 적용되지 않습니다. 변경된 타임아웃이 의도된 것보다 더 많은 트랜잭션에 영향을 미칠 수 있기 때문입니다.

경우에 따라 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)을 하지 않고 다른 명령문 타임아웃을 설정하려고 할 수 있으며, 이 경우 Puma와 Sidekiq이 다시 시작됩니다.

예를 들어, 백업이 [백업 명령](../backup_restore/_index.md#back-up-gitlab)의 출력에 다음 오류와 함께 실패할 수 있습니다. 명령문 타임아웃이 너무 짧기 때문입니다:

```plaintext
pg_dump: error: Error message from server: server closed the connection unexpectedly
```

[PostgreSQL 로그](../logs/_index.md#postgresql-logs)에서 다음 오류도 볼 수 있습니다:

```plaintext
canceling statement due to statement timeout
```

#### Linux 패키지 설치 {#for-linux-package-installations}

명령문 타임아웃을 임시로 변경하려면:

1. `/var/opt/gitlab/gitlab-rails/etc/database.yml`을 편집기에서 엽니다.
1. `statement_timeout`의 값을 `0`로 설정합니다. 이는 무제한 명령문 타임아웃을 설정합니다.
1. [새 Rails 콘솔 세션에서 확인](../operations/rails_console.md#using-the-rails-runner)하여 이 값이 사용되는지 확인합니다:

   ```shell
   sudo gitlab-rails runner "ActiveRecord::Base.connection_db_config[:variables]"
   ```

1. 다른 타임아웃이 필요한 작업을 수행합니다(예: 백업 또는 Rails 명령).
1. `/var/opt/gitlab/gitlab-rails/etc/database.yml`의 편집을 되돌립니다.

#### 클라우드 네이티브 배포 {#for-cloud-native-deployments}

AWS RDS, Azure Database for PostgreSQL 또는 Google Cloud SQL과 같은 관리형 PostgreSQL 서비스를 사용하는 클라우드 네이티브 배포의 경우, 데이터베이스 구성 파일을 직접 수정할 수 없습니다. 대신 클라우드 서비스의 매개변수 그룹 또는 구성 인터페이스를 통해 `statement_timeout` 매개변수를 구성합니다:

- **AWS RDS**:  데이터베이스 인스턴스와 연결된 매개변수 그룹을 수정하고 `statement_timeout`를 `0`(무제한)으로 설정합니다.
- **Azure Database for PostgreSQL**:  Azure 포털에서 서버 매개변수를 업데이트하고 `statement_timeout`를 `0`으로 설정합니다.
- **Google Cloud SQL**:  데이터베이스 플래그를 수정하고 `statement_timeout`를 `0`으로 설정합니다.

매개변수 그룹 또는 구성을 변경한 후 변경 사항을 적용하려면 데이터베이스 인스턴스를 다시 부팅해야 할 수 있습니다. 특정 지침은 클라우드 제공자의 설명서를 참조하세요.

### (RE)INDEX 진행 상황 보고서 관찰 {#observe-reindex-progress-report}

경우에 따라 `CREATE INDEX` 또는 `REINDEX` 작업의 진행 상황을 관찰하려고 할 수 있습니다. 예를 들어, `CREATE INDEX` 또는 `REINDEX` 작업이 활성화되어 있는지 확인하거나 작업이 어느 단계에 있는지 확인할 수 있습니다.

전제 조건:

- PostgreSQL 버전 12 이상을 사용해야 합니다.

`CREATE INDEX` 또는 `REINDEX` 작업을 관찰하려면:

- 기본 제공 [`pg_stat_progress_create_index` 보기](https://www.postgresql.org/docs/16/progress-reporting.html#CREATE-INDEX-PROGRESS-REPORTING)를 사용합니다.

예를 들어, 데이터베이스 콘솔 세션에서 다음 명령을 실행합니다:

```sql
SELECT * FROM  pg_stat_progress_create_index \watch 0.2
```

사람이 읽을 수 있는 출력 생성 및 로그 파일에 데이터 쓰기에 대해 자세히 알아보려면 [이 스니펫](https://gitlab.com/-/snippets/3750940)을 참조하세요.

## 문제 해결 {#troubleshooting}

### 데이터베이스 연결이 거부됨 {#database-connection-is-refused}

다음 오류가 발생하면 `max_connections`이 안정적인 연결을 보장할 정도로 높은지 확인하세요.

```shell
connection to server at "xxx.xxx.xxx.xxx", port 5432 failed: Connection refused
      Is the server running on that host and accepting TCP/IP connections?
```

```shell
psql: error: connection to server on socket "/var/opt/gitlab/postgresql/.s.PGSQL.5432" failed:
FATAL:  sorry, too many clients already
```

`max_connections`을 조정하려면 [여러 데이터베이스 연결 구성](https://docs.gitlab.com/omnibus/settings/database/#configuring-multiple-database-connections)을 참조하세요.

### 데이터베이스가 래핑어라운드 데이터 손실을 피하기 위해 명령을 수락하지 않음 {#database-is-not-accepting-commands-to-avoid-wraparound-data-loss}

이 오류는 `autovacuum`이 실행을 완료하지 못했음을 의미할 가능성이 높습니다:

```plaintext
ERROR:  database is not accepting commands to avoid wraparound data loss in database "gitlabhq_production"
```

또는

```plaintext
 ERROR:  failed to re-find parent key in index "XXX" for deletion target page XXX
```

오류를 해결하려면 `VACUUM`을 수동으로 실행합니다:

1. `gitlab-ctl stop` 명령으로 GitLab을 중지합니다.
1. 다음 명령으로 데이터베이스를 단일 사용자 모드로 전환합니다:

   ```shell
   /opt/gitlab/embedded/bin/postgres --single -D /var/opt/gitlab/postgresql/data gitlabhq_production
   ```

1. `backend>` 프롬프트에서 `VACUUM;`을 실행합니다. 이 명령은 완료하는 데 몇 분이 걸릴 수 있습니다.
1. 명령이 완료될 때까지 기다린 후 <kbd>Control</kbd> + <kbd>D</kbd>를 눌러 종료합니다.
1. `gitlab-ctl start` 명령으로 GitLab을 시작합니다.

### GitLab 데이터베이스 요구 사항 {#gitlab-database-requirements}

[데이터베이스 요구 사항](../../install/requirements.md#postgresql) 을 확인하고 [필수 확장 목록](../../install/requirements.md#extensions)을 검토하여 설치하세요.

### `production/sidekiq` 로그의 직렬화 오류 {#serialization-errors-in-the-productionsidekiq-log}

`production/sidekiq` 로그에서 이와 같은 오류를 받으면 문제를 해결하기 위해 [`default_transaction_isolation`을 읽기 커밋으로 설정](https://docs.gitlab.com/omnibus/settings/database/#set-default_transaction_isolation-into-read-committed)하는 것에 대해 읽으세요:

```plaintext
ActiveRecord::StatementInvalid PG::TRSerializationFailure: ERROR:  could not serialize access due to concurrent update
```

### PostgreSQL 복제 슬롯 오류 {#postgresql-replication-slot-errors}

이와 같은 오류를 받으면 PostgreSQL HA [복제 슬롯 오류](https://docs.gitlab.com/omnibus/settings/database/#troubleshooting-upgrades-in-an-ha-cluster)를 해결하는 방법에 대해 읽으세요:

```plaintext
pg_basebackup: could not create temporary replication slot "pg_basebackup_12345": ERROR:  all replication slots are in use
HINT:  Free one or increase max_replication_slots.
```

### Geo 복제 오류 {#geo-replication-errors}

이와 같은 오류를 받으면 [Geo 복제 오류](../geo/replication/troubleshooting/postgresql_replication.md)를 해결하는 방법에 대해 읽으세요:

```plaintext
ERROR: replication slots can only be used if max_replication_slots > 0

FATAL: could not start WAL streaming: ERROR: replication slot "geo_secondary_my_domain_com" does not exist

Command exceeded allowed execution time

PANIC: could not write to file 'pg_xlog/xlogtemp.123': No space left on device
```

### Geo 구성 및 일반적인 오류 검토 {#review-geo-configuration-and-common-errors}

Geo 관련 문제를 해결할 때는 다음을 수행해야 합니다:

- [일반적인 Geo 오류](../geo/replication/troubleshooting/common.md#fixing-common-errors)를 검토하세요.
- [Geo 구성을 검토](../geo/replication/troubleshooting/_index.md)하세요(다음 포함):
  - 호스트 및 포트를 다시 구성합니다.
  - 사용자 및 비밀번호 매핑을 검토하고 수정합니다.

### `pg_dump`과 `psql` 버전의 불일치 {#mismatch-in-pg_dump-and-psql-versions}

이와 같은 오류를 받으면 [비패키지 PostgreSQL 데이터베이스 백업 및 복원](https://docs.gitlab.com/omnibus/settings/database/#backup-and-restore-a-non-packaged-postgresql-database) 방법에 대해 읽으세요:

```plaintext
Dumping PostgreSQL database gitlabhq_production ... pg_dump: error: server version: 13.3; pg_dump version: 14.2
pg_dump: error: aborting because of server version mismatch
```

### 확장 `btree_gist`이 허용 목록에 없음 {#extension-btree_gist-is-not-allow-listed}

Azure Database for PostgreSQL - 유연한 서버에 PostgreSQL을 배포하면 다음 오류가 발생할 수 있습니다:

```plaintext
extension "btree_gist" is not allow-listed for "azure_pg_admin" users in Azure Database for PostgreSQL
```

이 오류를 해결하려면 설치 전에 [확장을 허용 목록에 추가](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-extensions#how-to-use-postgresql-extensions)하세요.
