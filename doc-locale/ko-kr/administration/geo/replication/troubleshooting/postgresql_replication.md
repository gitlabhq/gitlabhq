---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Geo PostgreSQL 복제 문제 해결
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

다음 섹션에서는 복제 오류 메시지 (`Database replication working? ... no`로 표시됨)를 수정하기 위한 문제 해결 단계를 설명합니다. 자세한 내용은 [`geo:check` 출력](common.md#health-check-rake-task)을 참조하세요. 여기의 지침은 주로 단일 노드 Geo Linux 패키지 배포를 가정하며 다양한 환경에 맞게 조정해야 할 수 있습니다.

## 비활성 복제 슬롯 제거 {#removing-an-inactive-replication-slot}

복제 슬롯은 슬롯에 연결된 복제 클라이언트(세컨더리 사이트)가 연결을 해제할 때 '비활성'으로 표시됩니다. 비활성 복제 슬롯으로 인해 WAL 파일이 보유되는데, 이는 클라이언트가 다시 연결할 때 클라이언트에게 전송되고 슬롯이 다시 활성화됩니다. 세컨더리 사이트가 다시 연결할 수 없으면 다음 단계를 따라 해당하는 비활성 복제 슬롯을 제거하세요:

1. Geo 프라이머리 사이트의 데이터베이스 노드에서 [PostgreSQL 콘솔 세션 시작](https://docs.gitlab.com/omnibus/settings/database/#connecting-to-the-postgresql-database):

   ```shell
   sudo gitlab-psql -d gitlabhq_production
   ```

   > [!note]
   > `gitlab-rails dbconsole` 사용은 복제 슬롯을 관리하려면 슈퍼유저 권한이 필요하므로 작동하지 않습니다.

1. 복제 슬롯을 보고 비활성이면 제거하세요:

   ```sql
   SELECT * FROM pg_replication_slots;
   ```

   `active`이(가) `f`인 슬롯은 비활성입니다.

- 이 슬롯이 활성이어야 하면 해당 슬롯을 사용하여 구성된 **세컨더리** 사이트가 있기 때문입니다:
  - [PostgreSQL 로그](../../../logs/_index.md#postgresql-logs)를 확인하여 **세컨더리** 사이트에서 복제가 실행되지 않는 이유를 확인하세요.
  - 세컨더리 사이트가 더 이상 연결할 수 없으면:

    1. PostgreSQL 콘솔 세션을 사용하여 슬롯을 제거하세요:

       ```sql
       SELECT pg_drop_replication_slot('<name_of_inactive_slot>');
       ```

    1. [복제 프로세스 다시 시작](../../setup/database.md#step-3-initiate-the-replication-process)하여 복제 슬롯을 올바르게 다시 생성하세요.

- 더 이상 슬롯을 사용하지 않으면 (예: Geo가 더 이상 활성화되지 않음) [해당 Geo 사이트 제거](../remove_geo_site.md) 단계를 따르세요.

## 메시지: `WARNING: oldest xmin is far in the past`과(와) `pg_wal` 크기 증가 {#message-warning-oldest-xmin-is-far-in-the-past-and-pg_wal-size-growing}

복제 슬롯이 비활성이면 슬롯에 해당하는 `pg_wal` 로그가 영구적으로 예약됩니다 (또는 슬롯이 다시 활성화될 때까지). 이로 인해 지속적인 디스크 사용량 증가가 발생하고 다음 메시지가 [PostgreSQL 로그](../../../logs/_index.md#postgresql-logs)에 반복적으로 표시됩니다:

```plaintext
WARNING: oldest xmin is far in the past
HINT: Close open transactions soon to avoid wraparound problems.
You might also need to commit or roll back old prepared transactions, or drop stale replication slots.
```

이 문제를 해결하려면 [비활성 복제 슬롯을 제거](#removing-an-inactive-replication-slot)하고 복제를 다시 시작해야 합니다.

## 메시지: `ERROR:  replication slots can only be used if max_replication_slots > 0`? {#message-error--replication-slots-can-only-be-used-if-max_replication_slots--0}

이것은 `max_replication_slots` PostgreSQL 변수를 **프라이머리** 데이터베이스에 설정해야 함을 의미합니다. 이 설정은 기본값이 1입니다. **세컨더리** 사이트가 더 많으면 이 값을 증가해야 할 수 있습니다.

이 설정이 적용되도록 PostgreSQL을 반드시 다시 시작하세요. [PostgreSQL 복제 설정](../../setup/database.md#postgresql-replication) 안내서를 참조하여 자세한 내용을 확인하세요.

## 메시지: `replication slot "geo_secondary_my_domain_com" does not exist` {#message-replication-slot-geo_secondary_my_domain_com-does-not-exist}

이 오류는 PostgreSQL이 **세컨더리** 사이트의 해당 이름에 대한 복제 슬롯을 갖고 있지 않을 때 발생합니다:

```plaintext
FATAL:  could not start WAL streaming: ERROR:  replication slot "geo_secondary_my_domain_com" does not exist
```

[복제 프로세스](../../setup/database.md)를 **세컨더리** 사이트에서 다시 실행할 수 있습니다.

## 메시지: `Command exceeded allowed execution time` (복제 설정 중)? {#message-command-exceeded-allowed-execution-time-when-setting-up-replication}

이는 [복제 프로세스 시작](../../setup/database.md#step-3-initiate-the-replication-process)하는 동안 **세컨더리** 사이트에서 발생할 수 있으며, 초기 데이터 세트가 너무 커서 기본 시간 초과 (30분) 내에 복제할 수 없음을 나타냅니다.

`gitlab-ctl replicate-geo-database`을(를) 다시 실행하지만 `--backup-timeout`에 더 큰 값을 포함하세요:

```shell
sudo gitlab-ctl \
   replicate-geo-database \
   --host=<primary_node_hostname> \
   --slot-name=<secondary_slot_name> \
   --backup-timeout=21600
```

이렇게 하면 초기 복제가 기본 30분이 아닌 최대 6시간을 완료할 수 있습니다. 설치에 필요에 따라 조정하세요.

## 메시지: `PANIC: could not write to file 'pg_xlog/xlogtemp.123': No space left on device` {#message-panic-could-not-write-to-file-pg_xlogxlogtemp123-no-space-left-on-device}

**프라이머리** 데이터베이스에 사용하지 않는 복제 슬롯이 있는지 확인하세요. 이로 인해 `pg_xlog`에 많은 양의 로그 데이터가 쌓일 수 있습니다.

[비활성 슬롯 제거](#removing-an-inactive-replication-slot)는 `pg_xlog`에서 사용되는 공간의 양을 줄일 수 있습니다.

## 메시지: `ERROR: canceling statement due to conflict with recovery` {#message-error-canceling-statement-due-to-conflict-with-recovery}

이 오류 메시지는 일반적인 사용 중에 드물게 발생하며 시스템은 복구할 수 있을 정도로 회복력이 있습니다.

그러나 특정 조건 하에서 세컨더리의 일부 데이터베이스 쿼리가 과도하게 오래 실행될 수 있으며, 이로 인해 이 오류 메시지의 빈도가 증가합니다. 이는 모든 복제에서 취소되어 일부 쿼리가 완료되지 않는 상황으로 이어질 수 있습니다.

이러한 장시간 실행되는 쿼리는 [향후에 제거될 예정](https://gitlab.com/gitlab-org/gitlab/-/issues/34269) 이지만 임시방편으로 [`hot_standby_feedback` 활성화](https://www.postgresql.org/docs/16/hot-standby.html#HOT-STANDBY-CONFLICT)를 권장합니다. 이로 인해 **프라이머리** 사이트에서 `VACUUM`가 최근 삭제된 행을 제거하는 것을 방지하므로 블로트 가능성이 증가합니다. 그러나 GitLab.com의 프로덕션 환경에서 성공적으로 사용되었습니다.

`hot_standby_feedback`을(를) 활성화하려면 **세컨더리** 사이트의 `/etc/gitlab/gitlab.rb`에 다음을 추가하세요:

```ruby
postgresql['hot_standby_feedback'] = 'on'
```

그 다음 GitLab을 재설정하세요:

```shell
sudo gitlab-ctl reconfigure
```

이 문제를 해결하는 데 도움이 되도록 [이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/4489)에 댓글 달기를 고려하세요.

## 메시지: `server certificate for "PostgreSQL" does not match host name` {#message-server-certificate-for-postgresql-does-not-match-host-name}

이 오류가 표시되면:

```plaintext
FATAL:  could not connect to the primary server: server certificate for "PostgreSQL" does not match host name
```

이는 Linux 패키지가 자동으로 생성하는 PostgreSQL 인증서에 일반 이름 `PostgreSQL`이(가) 포함되어 있지만 복제가 다른 호스트에 연결 중이고 GitLab이 기본적으로 `verify-full` SSL 모드를 사용하려고 시도하기 때문에 발생합니다.

이 문제를 해결하려면 다음 중 하나를 수행할 수 있습니다:

- `replicate-geo-database` 명령과 함께 `--sslmode=verify-ca` 인수를 사용하세요.
- 이미 복제된 데이터베이스의 경우 `/var/opt/gitlab/postgresql/data/gitlab-geo.conf`에서 `sslmode=verify-full`을(를) `sslmode=verify-ca`(으)로 변경하고 `gitlab-ctl restart postgresql`을(를) 실행하세요.
- [PostgreSQL용 SSL 구성](https://docs.gitlab.com/omnibus/settings/database/#configuring-ssl) (자동 생성된 인증서 대신 데이터베이스 연결에 사용되는 호스트 이름을 포함하는 사용자 정의 인증서 포함).

## 메시지: `LOG:  invalid CIDR mask in address` {#message-log--invalid-cidr-mask-in-address}

이는 `postgresql['md5_auth_cidr_addresses']`에서 잘못된 형식의 주소에서 발생합니다.

```plaintext
2020-03-20_23:59:57.60499 LOG:  invalid CIDR mask in address "***"
2020-03-20_23:59:57.60501 CONTEXT:  line 74 of configuration file "/var/opt/gitlab/postgresql/data/pg_hba.conf"
```

이 문제를 해결하려면 `/etc/gitlab/gitlab.rb`의 IP 주소를 `postgresql['md5_auth_cidr_addresses']` 아래에서 CIDR 형식 (예: `10.0.0.1/32`)을(를) 준수하도록 업데이트하세요.

## 메시지: `LOG:  invalid IP mask "md5": Name or service not known` {#message-log--invalid-ip-mask-md5-name-or-service-not-known}

이는 `postgresql['md5_auth_cidr_addresses']`에 서브넷 마스크 없이 IP 주소를 추가했을 때 발생합니다.

```plaintext
2020-03-21_00:23:01.97353 LOG:  invalid IP mask "md5": Name or service not known
2020-03-21_00:23:01.97354 CONTEXT:  line 75 of configuration file "/var/opt/gitlab/postgresql/data/pg_hba.conf"
```

이 문제를 해결하려면 `/etc/gitlab/gitlab.rb`의 서브넷 마스크를 `postgresql['md5_auth_cidr_addresses']` 아래에 추가하여 CIDR 형식 (예: `10.0.0.1/32`)을(를) 준수하도록 하세요.

## 메시지: `Found data in the gitlabhq_production database` {#message-found-data-in-the-gitlabhq_production-database}

`gitlab-ctl replicate-geo-database`를 실행할 때 오류 `Found data in the gitlabhq_production database!`을(를) 받으면 `projects` 테이블에서 데이터가 감지되었습니다. 하나 이상의 프로젝트가 감지되면 작업이 중단되어 의도하지 않은 데이터 손실을 방지합니다. 이 메시지를 무시하려면 명령에 `--force` 옵션을 전달하세요.

## 메시지: `FATAL:  could not map anonymous shared memory: Cannot allocate memory` {#message-fatal--could-not-map-anonymous-shared-memory-cannot-allocate-memory}

이 메시지가 표시되면 세컨더리 사이트의 PostgreSQL이 사용 가능한 메모리보다 높은 메모리를 요청하려고 한다는 의미입니다. 이 문제를 추적하는 [이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/381585)가 있습니다.

Patroni 로그의 예제 오류 메시지 (`/var/log/gitlab/patroni/current`에 위치하며 Linux 패키지 설치용):

```plaintext
2023-11-21_23:55:18.63727 FATAL:  could not map anonymous shared memory: Cannot allocate memory
2023-11-21_23:55:18.63729 HINT:  This error usually means that PostgreSQL's request for a shared memory segment exceeded available memory, swap space, or huge pages. To reduce the request size (currently 17035526144 bytes), reduce PostgreSQL's shared memory usage, perhaps by reducing shared_buffers or max_connections.
```

임시방편은 세컨더리 사이트의 PostgreSQL 노드에 사용 가능한 메모리를 증가시켜 프라이머리 사이트의 PostgreSQL 노드의 메모리 요구 사항과 일치하도록 하는 것입니다.

## 메시지: `could not open certificate file "/root/.postgresql/postgresql.crt"` {#message-could-not-open-certificate-file-rootpostgresqlpostgresqlcrt}

이 오류가 표시되면:

```plaintext
sql: error: connection to server at "x.x.x.x", port 5432 failed:
could not open certificate file "/root/.postgresql/postgresql.crt": Permission denied...
```

이 오류는 `psql` 또는 `libpq`을(를) 사용하는 애플리케이션과 같은 PostgreSQL 클라이언트가 `/root/.postgresql/postgresql.crt`과(와) 같은 특정 기본 위치에서 클라이언트 SSL 인증서를 찾기 때문에 발생합니다. 그러나 이 오류 메시지는 오도할 수 있습니다. GitLab 복제 사용자에 대해 잘못된 암호를 사용하는 등 다른 이유로 인증이 실패할 때 종종 나타납니다. SSL 인증서 문제를 해결하기 전에 먼저 인증 자격 증명이 올바른지 확인하세요.

## 데이터베이스 복제 지연의 원인 조사 {#investigate-causes-of-database-replication-lag}

`sudo gitlab-rake gitlab:geo:status`의 출력이 `Database replication lag`이(가) 시간이 지남에 따라 상당히 높게 유지됨을 보여주면 데이터베이스 복제 프로세스의 다양한 부분에 대한 지연 상태를 결정하기 위해 데이터베이스 복제의 프라이머리 노드를 확인할 수 있습니다. 이러한 값을 `write_lag`, `flush_lag`, `replay_lag`라고 합니다. 자세한 내용은 [공식 PostgreSQL 설명서](https://www.postgresql.org/docs/16/monitoring-stats.html#MONITORING-PG-STAT-REPLICATION-VIEW)를 참조하세요.

프라이머리 Geo 노드의 데이터베이스에서 다음 명령을 실행하여 관련 출력을 제공하세요:

```shell
gitlab-psql -xc 'SELECT write_lag,flush_lag,replay_lag FROM pg_stat_replication;'

-[ RECORD 1 ]---------------
write_lag  | 00:00:00.072392
flush_lag  | 00:00:00.108168
replay_lag | 00:00:00.108283
```

이러한 값 중 하나 이상이 상당히 높으면 문제를 나타낼 수 있으며 추가로 조사해야 합니다. 원인을 파악할 때 다음을 고려하세요:

- `write_lag`은(는) WAL 바이트가 프라이머리에서 전송된 후 세컨더리로 수신되었지만 아직 플러시되거나 적용되지 않은 시간을 나타냅니다.
- 높은 `write_lag` 값은 프라이머리와 세컨더리 노드 간의 성능 저하된 네트워크 성능 또는 불충분한 네트워크 속도를 나타낼 수 있습니다.
- 높은 `flush_lag` 값은 세컨더리 노드의 스토리지 장치로 인한 성능 저하 또는 차선의 디스크 I/O 성능을 나타낼 수 있습니다.
- 높은 `replay_lag` 값은 PostgreSQL의 장시간 실행되는 트랜잭션 또는 CPU와 같은 필요한 리소스의 포화를 나타낼 수 있습니다.
- `write_lag`과(와) `flush_lag` 간의 시간 차이는 WAL 바이트가 기본 스토리지 시스템으로 전송되었지만 플러시되었다고 보고하지 않았음을 나타냅니다. 이 데이터는 아마도 영구 스토리지에 완전히 쓰이지 않았으며 일종의 휘발성 쓰기 캐시에 유지될 가능성이 높습니다.
- `flush_lag`과(와) `replay_lag` 간의 차이는 스토리지에 성공적으로 유지되었지만 데이터베이스 시스템에서 재생할 수 없는 WAL 바이트를 나타냅니다.

## 정체됨: `Message: pg_basebackup: initiating base backup, waiting for checkpoint to complete` {#stuck-at-message-pg_basebackup-initiating-base-backup-waiting-for-checkpoint-to-complete}

초기 복제가 `Message: pg_basebackup: initiating base backup, waiting for checkpoint to complete`에 정체되면 프라이머리 Geo 사이트가 적극적으로 사용되지 않고 있음을 의미합니다. 이는 대부분 프로덕션이 아닌 GitLab 서버 또는 새로운 GitLab 설치에서 발생합니다.

임시방편은 일부 데이터베이스 쓰기를 수행하는 것입니다. 예를 들어 프라이머리 사이트에 로그인하여 일부 이슈 및 댓글을 생성할 수 있습니다.

다른 임시방편은 프라이머리 사이트의 데이터베이스에서 SQL 쿼리 `CHECKPOINT;`을(를) 실행하는 것입니다:

```shell
sudo gitlab-psql -xc 'CHECKPOINT;'
```
