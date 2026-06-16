---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Linux 패키지 설치를 위한 PostgreSQL 복제 및 장애 조치 문제 해결
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

PostgreSQL 복제 및 장애 조치로 작업할 때 다음 문제가 발생할 수 있습니다.

## Consul 및 PostgreSQL 변경 사항이 적용되지 않음 {#consul-and-postgresql-changes-not-taking-effect}

가능한 영향으로 인해 `gitlab-ctl reconfigure`은(는) Consul 및 PostgreSQL만 다시 로드하며 서비스를 다시 시작하지 않습니다. 그러나 모든 변경 사항을 다시 로드하여 활성화할 수 있는 것은 아닙니다.

서비스를 다시 시작하려면 `gitlab-ctl restart SERVICE`을(를) 실행합니다.

PostgreSQL의 경우 기본적으로 리더 노드를 다시 시작하는 것이 일반적으로 안전합니다. 자동 장애 조치는 1분 타임아웃이 기본값입니다. 데이터베이스가 그 전에 반환되면 다른 작업은 필요하지 않습니다.

Consul 서버 노드에서 [Consul 서비스를 다시 시작](../consul.md#restart-consul)하는 것이 중요합니다.

## PgBouncer 오류 `ERROR: pgbouncer cannot connect to server` {#pgbouncer-error-error-pgbouncer-cannot-connect-to-server}

`gitlab-rake gitlab:db:configure`을(를) 실행할 때 이 오류가 발생할 수 있으며, PgBouncer 로그 파일에서 오류를 볼 수 있습니다.

```plaintext
PG::ConnectionBad: ERROR:  pgbouncer cannot connect to server
```

문제는 PgBouncer 노드의 IP 주소가 데이터베이스 노드의 `/etc/gitlab/gitlab.rb`에서 `trust_auth_cidr_addresses` 설정에 포함되지 않았을 수 있습니다.

리더 데이터베이스 노드에서 PostgreSQL 로그를 확인하여 이것이 문제인지 확인할 수 있습니다. 다음 오류가 표시되면 `trust_auth_cidr_addresses`이(가) 문제입니다.

```plaintext
2018-03-29_13:59:12.11776 FATAL:  no pg_hba.conf entry for host "123.123.123.123", user "pgbouncer", database "gitlabhq_production", SSL off
```

문제를 해결하려면 `/etc/gitlab/gitlab.rb`에 IP 주소를 추가합니다.

```ruby
postgresql['trust_auth_cidr_addresses'] = %w(123.123.123.123/32 <other_cidrs>)
```

[GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)하여 변경 사항을 적용합니다.

## PgBouncer 노드가 Patroni 전환 후 장애 조치되지 않음 {#pgbouncer-nodes-dont-fail-over-after-patroni-switchover}

GitLab 16.5.0 이전의 버전에 영향을 미치는 [알려진 문제](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8166) 로 인해 [Patroni 전환](replication_and_failover.md#manual-failover-procedure-for-patroni) 후 PgBouncer 노드의 자동 장애 조치가 발생하지 않습니다. 이 예에서 GitLab이 일시 중지된 데이터베이스를 감지하지 못하고 일시 중지되지 않은 데이터베이스에서 `RESUME`을(를) 시도했습니다:

```plaintext
INFO -- : Running: gitlab-ctl pgb-notify --pg-database gitlabhq_production --newhost database7.example.com --user pgbouncer --hostuser gitlab-consul
ERROR -- : STDERR: Error running command: GitlabCtl::Errors::ExecutionError
ERROR -- : STDERR: ERROR: ERROR:  database gitlabhq_production is not paused
```

[Patroni 전환](replication_and_failover.md#manual-failover-procedure-for-patroni)이 성공하려면 다음 명령으로 모든 PgBouncer 노드에서 PgBouncer 서비스를 수동으로 다시 시작해야 합니다:

```shell
gitlab-ctl restart pgbouncer
```

## 복제본 다시 초기화 {#reinitialize-a-replica}

복제본을 시작할 수 없거나 클러스터에 다시 참여할 수 없거나 지연되어 따라잡을 수 없으면 복제본을 다시 초기화해야 할 수 있습니다:

1. [복제 상태 확인](replication_and_failover.md#check-replication-status)하여 다시 초기화해야 할 서버를 확인합니다. 예를 들어:

   ```plaintext
   + Cluster: postgresql-ha (6970678148837286213) ------+---------+--------------+----+-----------+
   | Member                              | Host         | Role    | State        | TL | Lag in MB |
   +-------------------------------------+--------------+---------+--------------+----+-----------+
   | gitlab-database-1.example.com       | 172.18.0.111 | Replica | running      | 55 |         0 |
   | gitlab-database-2.example.com       | 172.18.0.112 | Replica | start failed |    |   unknown |
   | gitlab-database-3.example.com       | 172.18.0.113 | Leader  | running      | 55 |           |
   +-------------------------------------+--------------+---------+--------------+----+-----------+
   ```

1. 손상된 서버에 로그인하고 데이터베이스 및 복제를 다시 초기화합니다. Patroni가 해당 서버에서 PostgreSQL을 종료하고 데이터 디렉토리를 제거한 후 처음부터 다시 초기화합니다:

   ```shell
   sudo gitlab-ctl patroni reinitialize-replica --member gitlab-database-2.example.com
   ```

   이것은 모든 Patroni 노드에서 실행할 수 있지만 `sudo gitlab-ctl patroni reinitialize-replica`이(가) `--member` 없이 실행되면 실행되는 서버를 다시 시작한다는 점에 주의합니다. 의도하지 않은 데이터 손실의 위험을 줄이기 위해 손상된 서버에서 로컬로 실행해야 합니다.
1. 로그를 모니터링합니다:

   ```shell
   sudo gitlab-ctl tail patroni
   ```

## Consul에서 Patroni 상태 재설정 {#reset-the-patroni-state-in-consul}

> [!warning]
> Consul에서 Patroni 상태를 재설정하는 것은 잠재적으로 파괴적인 프로세스입니다. 먼저 정상 데이터베이스 백업이 있는지 확인합니다.

마지막 수단으로 Consul에서 Patroni 상태를 완전히 재설정할 수 있습니다.

이는 Patroni 클러스터가 알 수 없는 상태 또는 나쁜 상태이고 어떤 노드도 시작할 수 없는 경우 필요할 수 있습니다:

```plaintext
+ Cluster: postgresql-ha (6970678148837286213) ------+---------+---------+----+-----------+
| Member                              | Host         | Role    | State   | TL | Lag in MB |
+-------------------------------------+--------------+---------+---------+----+-----------+
| gitlab-database-1.example.com       | 172.18.0.111 | Replica | stopped |    |   unknown |
| gitlab-database-2.example.com       | 172.18.0.112 | Replica | stopped |    |   unknown |
| gitlab-database-3.example.com       | 172.18.0.113 | Replica | stopped |    |   unknown |
+-------------------------------------+--------------+---------+---------+----+-----------+
```

Consul에서 Patroni 상태를 삭제하기 전에 Patroni 노드에서 [`gitlab-ctl` 오류를 해결해야 합니다](#errors-running-gitlab-ctl).

이 프로세스는 첫 번째 Patroni 노드가 시작될 때 다시 초기화된 Patroni 클러스터를 만듭니다.

Consul에서 Patroni 상태를 재설정하려면:

1. 리더였던 Patroni 노드 또는 애플리케이션이 현재 리더라고 생각하는 Patroni 노드를 기록합니다. 현재 상태가 두 개 이상 또는 없음을 표시하는 경우:
   - PgBouncer 노드의 `/var/opt/gitlab/consul/databases.ini`을(를) 확인합니다. 여기에는 현재 리더의 호스트명이 포함되어 있습니다.
   - 모든 데이터베이스 노드에서 Patroni 로그 `/var/log/gitlab/patroni/current` (또는 더 오래된 회전 및 압축된 로그 `/var/log/gitlab/patroni/@40000*`)를 확인하여 클러스터에서 가장 최근에 리더로 확인된 서버를 참조합니다:

     ```plaintext
     INFO: no action. I am a secondary (database1.local) and following a leader (database2.local)
     ```

1. 모든 노드에서 Patroni를 중지합니다:

   ```shell
   sudo gitlab-ctl stop patroni
   ```

1. Consul에서 상태를 재설정합니다:

   ```shell
   /opt/gitlab/embedded/bin/consul kv delete -recurse /service/postgresql-ha/
   ```

1. 리더로 선출할 Patroni 클러스터를 초기화하는 하나의 Patroni 노드를 시작합니다. 이전 리더(첫 번째 단계에서 기록)를 시작하는 것이 좋습니다. 이렇게 하면 클러스터 상태가 깨져 복제되지 않았을 수 있는 기존 쓰기를 잃지 않습니다:

   ```shell
   sudo gitlab-ctl start patroni
   ```

1. Patroni 클러스터에 복제본으로 참여하는 다른 모든 Patroni 노드를 시작합니다:

   ```shell
   sudo gitlab-ctl start patroni
   ```

여전히 문제가 표시되면 다음 단계는 마지막 정상 백업을 복원하는 것입니다.

## Patroni 로그의 `pg_hba.conf` 항목이 `127.0.0.1`에 대해 표시되는 오류 {#errors-in-the-patroni-log-about-a-pg_hbaconf-entry-for-127001}

Patroni 로그의 다음 로그 항목은 복제가 작동하지 않고 구성 변경이 필요함을 나타냅니다:

```plaintext
FATAL:  no pg_hba.conf entry for replication connection from host "127.0.0.1", user "gitlab_replicator"
```

문제를 해결하려면 루프백 인터페이스가 CIDR 주소 목록에 포함되도록 합니다:

1. `/etc/gitlab/gitlab.rb`을 편집합니다:

   ```ruby
   postgresql['trust_auth_cidr_addresses'] = %w(<other_cidrs> 127.0.0.1/32)
   ```

1. [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)하여 변경 사항을 적용합니다.
1. [모든 복제본이 동기화](replication_and_failover.md#check-replication-status)되었는지 확인합니다.

## 보류 중인 재시작으로 표시되는 Patroni 멤버 {#patroni-members-showing-as-pending-restart}

`gitlab-ctl patroni members`의 출력이 보류 중인 재시작 상태인 보조 사이트의 Patroni 멤버를 표시할 수 있습니다:

```shell
secondary-site:postgresql-1> gitlab-ctl patroni members
+ Cluster: postgresql-ha ------------------------------------------------------------------+
| Member         | Host      | Role           | State   | TL | Lag in MB | Pending restart |
+----------------+-----------+----------------+---------+----+-----------+-----------------+
| patroni-1 | 10.20.0.1 | Replica        | running | 27 |         0 | *               |
| patroni-2 | 10.20.0.2 | Replica        | running | 27 |         5 | *               |
| patroni-3 | 10.20.0.3 | Standby Leader | running | 27 |           | *               |
+----------------+-----------+----------------+---------+----+-----------+----------
```

보류 중인 재시작 상태는 해당 노드가 일부 구성 변경을 적용하기 위해 재시작을 기다리고 있음을 의미합니다.

보류 중인 재시작 설정이 무엇인지 알기 위해 확인해야 하는 인스턴스에서 다음을 실행합니다:

```shell
sudo gitlab-psql -c "select name, setting,  short_desc, sourcefile, sourceline  from pg_settings where pending_restart"
```

보류 중인 구성 변경을 적용하려면 영향을 받는 노드를 다시 시작합니다:

1. 복제본 노드의 경우 `sudo gitlab-ctl restart patroni`을(를) 실행합니다.
1. 리더 노드의 경우 먼저 장애 조치를 수행하거나 `sudo gitlab-ctl reload patroni`을(를) 실행하여 다운타임을 피할 수 있습니다.

## 오류: 요청된 시작 지점이 쓰기 미리 로그(WAL) 플러시 위치보다 앞에 있음 {#error-requested-start-point-is-ahead-of-the-write-ahead-log-wal-flush-position}

Patroni 로그의 이 오류는 데이터베이스가 복제되지 않음을 나타냅니다:

```plaintext
FATAL:  could not receive data from WAL stream:
ERROR:  requested starting point 0/5000000 is ahead of the WAL flush position of this server 0/4000388
```

이 예 오류는 처음에 잘못 구성되었으며 복제된 적이 없는 복제본에서 발생합니다.

[복제본을 다시 초기화하여](#reinitialize-a-replica) 이를 해결합니다.

## Patroni가 `MemoryError`로 시작되지 못함 {#patroni-fails-to-start-with-memoryerror}

Patroni가 시작되지 못하고 오류 및 스택 추적을 로깅할 수 있습니다:

```plaintext
MemoryError
Traceback (most recent call last):
  File "/opt/gitlab/embedded/bin/patroni", line 8, in <module>
    sys.exit(main())
[..]
  File "/opt/gitlab/embedded/lib/python3.7/ctypes/__init__.py", line 273, in _reset_cache
    CFUNCTYPE(c_int)(lambda: None)
```

스택 추적이 `CFUNCTYPE(c_int)(lambda: None)`으로 끝나면 이 코드는 Linux 서버가 보안을 위해 강화된 경우 `MemoryError`을(를) 트리거합니다.

코드는 Python이 임시 실행 가능 파일을 작성하도록 합니다. 그리고 파일 시스템을 찾을 수 없는 경우. 예를 들어 `noexec`이(가) `/tmp` 파일 시스템에서 설정되면 `MemoryError`로 실패합니다 ([문제에서 자세히 알아보기](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6184)).

## `gitlab-ctl` 실행 시 오류 {#errors-running-gitlab-ctl}

Patroni 노드는 `gitlab-ctl` 명령이 실패하고 `gitlab-ctl reconfigure`이(가) 노드를 수정할 수 없는 상태가 될 수 있습니다.

이것이 PostgreSQL의 버전 업그레이드와 일치하면 [다른 절차를 따릅니다](#postgresql-major-version-upgrade-fails-on-a-patroni-replica).

한 가지 일반적인 증상은 `gitlab-ctl`이(가) 데이터베이스 서버가 시작되지 못하는 경우 설치에 필요한 정보를 결정할 수 없다는 것입니다:

```plaintext
Malformed configuration JSON file found at /opt/gitlab/embedded/nodes/<HOSTNAME>.json.
This usually happens when your last run of `gitlab-ctl reconfigure` didn't complete successfully.
```

```plaintext
Error while reinitializing replica on the current node: Attributes not found in
/opt/gitlab/embedded/nodes/<HOSTNAME>.json, has reconfigure been run yet?
```

마찬가지로 노드 파일(`/opt/gitlab/embedded/nodes/<HOSTNAME>.json`)에는 많은 정보가 포함되어야 하지만 다음과 같이만 생성될 수 있습니다:

```json
{
  "name": "<HOSTNAME>"
}
```

다음 수정 프로세스는 이 복제본을 다시 초기화하는 것을 포함합니다. 이 노드의 PostgreSQL 현재 상태는 폐기됩니다:

1. Patroni 및 (있는 경우) PostgreSQL 서비스를 종료합니다:

   ```shell
   sudo gitlab-ctl status
   sudo gitlab-ctl stop patroni
   sudo gitlab-ctl stop postgresql
   ```

1. `/var/opt/gitlab/postgresql/data`을(를) 제거합니다. PostgreSQL이 시작되지 못하도록 하는 상태인 경우:

   ```shell
   cd /var/opt/gitlab/postgresql
   sudo rm -rf data
   ```

   > [!warning]
   > 데이터 손실을 피하기 위해 이 단계를 주의해서 수행합니다. 이 단계는 `data/`의 이름을 바꾸어 달성할 수도 있습니다. 기본 데이터베이스의 새 복사본에 대해 충분한 여유 디스크가 있는지 확인하고 복제본이 수정되면 추가 디렉토리를 제거합니다.

1. PostgreSQL이 실행되지 않으면 노드 파일이 이제 성공적으로 생성됩니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Patroni를 시작합니다:

   ```shell
   sudo gitlab-ctl start patroni
   ```

1. 로그를 모니터링하고 클러스터 상태를 확인합니다:

   ```shell
   sudo gitlab-ctl tail patroni
   sudo gitlab-ctl patroni members
   ```

1. `reconfigure`을(를) 다시 실행합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. `gitlab-ctl patroni members`이(가) 필요함을 나타내는 경우 복제본을 다시 초기화합니다:

   ```shell
   sudo gitlab-ctl patroni reinitialize-replica
   ```

이 절차가 작동하지 않고 클러스터가 리더를 선출할 수 없으면 [다른 수정 방법](#reset-the-patroni-state-in-consul)이 있으며, 이는 마지막 수단으로만 사용해야 합니다.

## PostgreSQL 주요 버전 업그레이드가 Patroni 복제본에서 실패함 {#postgresql-major-version-upgrade-fails-on-a-patroni-replica}

Patroni 복제본은 `gitlab-ctl pg-upgrade` 중에 루프에 갇힐 수 있으며 업그레이드가 실패합니다.

증상의 예시 집합은 다음과 같습니다:

1. `postgresql` 서비스가 정의되어 있으며, 일반적으로 Patroni 노드에 존재하지 않아야 합니다. `gitlab-ctl pg-upgrade`이(가) 새 빈 데이터베이스를 만드는 데 추가되므로 존재합니다:

   ```plaintext
   run: patroni: (pid 1972) 1919s; run: log: (pid 1971) 1919s
   down: postgresql: 1s, normally up, want up; run: log: (pid 1973) 1919s
   ```

1. PostgreSQL은 `/var/log/gitlab/postgresql/current`에서 `PANIC` 로그 항목을 생성합니다. Patroni가 복제본을 다시 초기화하는 과정에서 `/var/opt/gitlab/postgresql/data`을(를) 제거합니다:

   ```plaintext
   DETAIL:  Could not open file "pg_xact/0000": No such file or directory.
   WARNING:  terminating connection because of crash of another server process
   LOG:  all server processes terminated; reinitializing
   PANIC:  could not open file "global/pg_control": No such file or directory
   ```

1. `/var/log/gitlab/patroni/current`에서 Patroni는 다음을 기록합니다. 로컬 PostgreSQL 버전은 클러스터 리더와 다릅니다:

   ```plaintext
   INFO: trying to bootstrap from leader 'HOSTNAME'
   pg_basebackup: incompatible server version 12.6
   pg_basebackup: removing data directory "/var/opt/gitlab/postgresql/data"
   ERROR: Error when fetching backup: pg_basebackup exited with code=1
   ```

이 해결 방법은 Patroni 클러스터가 다음 상태일 때 적용됩니다:

- [리더가 새 주요 버전으로 성공적으로 업그레이드](replication_and_failover.md#upgrading-postgresql-major-version-in-a-patroni-cluster)되었습니다.
- 복제본에서 PostgreSQL을 업그레이드하는 단계가 실패하고 있습니다.

이 해결 방법은 노드를 새 PostgreSQL 버전을 사용하도록 설정한 후 리더가 업그레이드될 때 생성된 새 클러스터에서 복제본으로 다시 초기화하여 Patroni 복제본에서 PostgreSQL 업그레이드를 완료합니다:

1. 모든 노드에서 클러스터 상태를 확인하여 리더가 무엇이고 복제본의 상태를 확인합니다.

   ```shell
   sudo gitlab-ctl patroni members
   ```

1. 복제본: 어떤 버전의 PostgreSQL이 활성 상태인지 확인합니다:

   ```shell
   sudo ls -al /opt/gitlab/embedded/bin | grep postgres
   ```

1. 복제본: 노드 파일이 올바르고 `gitlab-ctl`이(가) 실행될 수 있는지 확인합니다. 이는 복제본에 해당 오류 중 일부가 있는 경우 [`gitlab-ctl` 실행 오류](#errors-running-gitlab-ctl) 문제를 해결합니다:

   ```shell
   sudo gitlab-ctl stop patroni
   sudo gitlab-ctl reconfigure
   ```

1. 복제본: PostgreSQL 바이너리를 필수 버전으로 다시 연결하여 `incompatible server version` 오류를 해결합니다:

   1. `/etc/gitlab/gitlab.rb`을(를) 편집하고 필수 버전을 지정합니다:

      ```ruby
      postgresql['version'] = 13
      ```

   1. GitLab을 재구성합니다:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

   1. 바이너리가 다시 연결되었는지 확인합니다. PostgreSQL용으로 배포된 바이너리는 주요 릴리스 간에 다르며, 일반적으로 적은 수의 부정확한 기호 링크가 있습니다:

      ```shell
      sudo ls -al /opt/gitlab/embedded/bin | grep postgres
      ```

1. 복제본: PostgreSQL이 지정된 버전에 대해 완전히 다시 초기화되도록 합니다:

   ```shell
   cd /var/opt/gitlab/postgresql
   sudo rm -rf data
   sudo gitlab-ctl reconfigure
   ```

1. 복제본: 선택적으로 두 개의 추가 터미널 세션에서 데이터베이스를 모니터링합니다:

   - 디스크 사용량은 `pg_basebackup`이(가) 실행될 때 증가합니다. 다음을 사용하여 복제본 초기화의 진행 상황을 추적합니다:

     ```shell
     cd /var/opt/gitlab/postgresql
     watch du -sh data
     ```

   - 로그에서 프로세스를 모니터링합니다:

     ```shell
     sudo gitlab-ctl tail patroni
     ```

1. 복제본:  Patroni를 시작하여 복제본을 다시 초기화합니다:

   ```shell
   sudo gitlab-ctl start patroni
   ```

1. 복제본:  완료한 후 `/etc/gitlab/gitlab.rb`에서 하드코딩된 버전을 제거합니다:

   1. `/etc/gitlab/gitlab.rb`을(를) 편집하고 `postgresql['version']`을(를) 제거합니다.
   1. GitLab을 재구성합니다:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

   1. 올바른 바이너리가 연결되어 있는지 확인합니다:

      ```shell
      sudo ls -al /opt/gitlab/embedded/bin | grep postgres
      ```

1. 모든 노드에서 클러스터 상태를 확인합니다:

   ```shell
   sudo gitlab-ctl patroni members
   ```

필요한 경우 다른 복제본에서 이 절차를 반복합니다.

## PostgreSQL 복제본이 생성되는 동안 루프에 갇혀 있음 {#postgresql-replicas-stuck-in-loop-while-being-created}

PostgreSQL 복제본이 마이그레이션되는 것으로 표시되지만 루프에서 다시 시작되면 복제본 및 기본 서버의 `/opt/gitlab-data/postgresql/` 폴더 권한을 확인합니다.

로그에서도 이 오류 메시지를 볼 수 있습니다. `could not get COPY data stream: ERROR: could not open file "<file>" Permission denied`.

## 다른 구성 요소의 문제 {#issues-with-other-components}

여기에 설명되지 않은 구성 요소의 문제가 발생하면 특정 설명서 페이지의 문제 해결 섹션을 확인해야 합니다:

- [Consul](../consul.md#troubleshooting-consul)
- [PostgreSQL](https://docs.gitlab.com/omnibus/settings/database/#troubleshooting)
