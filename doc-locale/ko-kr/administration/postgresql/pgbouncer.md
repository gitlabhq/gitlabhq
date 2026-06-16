---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 번들로 제공되는 PgBouncer 서비스 사용
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

> [!note]
> PgBouncer는 `gitlab-ee` 패키지에 번들로 포함되어 있지만 무료로 사용할 수 있습니다. 지원을 받으려면 [Premium 구독](https://about.gitlab.com/pricing/)이 필요합니다.

[PgBouncer](https://www.pgbouncer.org/)는 장애 조치(failover) 시나리오에서 데이터베이스 연결을 서버 간에 원활하게 마이그레이션하는 데 사용됩니다. 또한 장애 허용 불가(non-fault-tolerant) 설정에서 연결을 풀링하여 응답 시간을 단축하고 리소스 사용을 줄이는 데 사용할 수 있습니다.

GitLab Premium은 `/etc/gitlab/gitlab.rb`를 통해 관리할 수 있는 번들로 제공되는 PgBouncer 버전을 포함합니다.

## 장애 허용(fault-tolerant) GitLab 설치의 일부로서의 PgBouncer {#pgbouncer-as-part-of-a-fault-tolerant-gitlab-installation}

이 콘텐츠는 [새 위치](replication_and_failover.md#configure-pgbouncer-nodes)로 이동되었습니다.

## 장애 허용 불가(non-fault-tolerant) GitLab 설치의 일부로서의 PgBouncer {#pgbouncer-as-part-of-a-non-fault-tolerant-gitlab-installation}

1. `PGBOUNCER_USER_PASSWORD_HASH`를 `gitlab-ctl pg-password-md5 pgbouncer` 명령으로 생성합니다
1. `SQL_USER_PASSWORD_HASH`를 `gitlab-ctl pg-password-md5 gitlab` 명령으로 생성합니다. 나중에 평문 SQL_USER_PASSWORD를 입력합니다.
1. 데이터베이스 노드에서 `/etc/gitlab/gitlab.rb`에 다음이 설정되어 있는지 확인합니다

   ```ruby
   postgresql['pgbouncer_user_password'] = 'PGBOUNCER_USER_PASSWORD_HASH'
   postgresql['sql_user_password'] = 'SQL_USER_PASSWORD_HASH'
   postgresql['listen_address'] = 'XX.XX.XX.Y' # Where XX.XX.XX.Y is the ip address on the node postgresql should listen on
   postgresql['md5_auth_cidr_addresses'] = %w(AA.AA.AA.B/32) # Where AA.AA.AA.B is the IP address of the pgbouncer node
   ```

1. `gitlab-ctl reconfigure`를 실행합니다

   > [!note]
   > 데이터베이스가 이미 실행 중인 경우 `gitlab-ctl restart postgresql`를 실행하여 재구성 후 다시 시작해야 합니다.

1. PgBouncer를 실행 중인 노드에서 `/etc/gitlab/gitlab.rb`에 다음이 설정되어 있는지 확인합니다

   ```ruby
   pgbouncer['enable'] = true
   pgbouncer['databases'] = {
     gitlabhq_production: {
       host: 'DATABASE_HOST',
       user: 'pgbouncer',
       password: 'PGBOUNCER_USER_PASSWORD_HASH'
     }
   }
   ```

   데이터베이스별로 추가 구성 매개변수를 전달할 수 있습니다. 예를 들어:

   ```ruby
   pgbouncer['databases'] = {
     gitlabhq_production: {
        ...
        pool_mode: 'transaction'
     }
   }
   ```

   이러한 매개변수는 주의해서 사용합니다. 매개변수의 전체 목록은 [PgBouncer 설명서](https://www.pgbouncer.org/config.html#section-databases)를 참조합니다.

1. `gitlab-ctl reconfigure`를 실행합니다
1. Puma를 실행 중인 노드에서 `/etc/gitlab/gitlab.rb`에 다음이 설정되어 있는지 확인합니다

   ```ruby
   gitlab_rails['db_host'] = 'PGBOUNCER_HOST'
   gitlab_rails['db_port'] = '6432'
   gitlab_rails['db_password'] = 'SQL_USER_PASSWORD'
   ```

1. `gitlab-ctl reconfigure`를 실행합니다
1. 이 시점에서 인스턴스는 PgBouncer를 통해 데이터베이스에 연결되어야 합니다. 문제가 있으면 [문제 해결](#troubleshooting) 섹션을 참조합니다

## 백업 {#backups}

PgBouncer 연결을 통해 GitLab을 백업하거나 복원하지 마세요. GitLab 중단을 야기합니다.

[이에 대해 자세히 알아보고 백업을 재구성하는 방법을 참조합니다](../backup_restore/backup_gitlab.md#back-up-and-restore-for-installations-using-pgbouncer).

## 모니터링 활성화 {#enable-monitoring}

모니터링을 활성화하면 모든 PgBouncer 서버에서 활성화되어야 합니다.

1. `/etc/gitlab/gitlab.rb`를 생성하거나 편집하고 다음 구성을 추가합니다:

   ```ruby
   # Enable service discovery for Prometheus
   consul['enable'] = true
   consul['monitoring_service_discovery'] =  true

   # Replace placeholders
   # Y.Y.Y.Y consul1.gitlab.example.com Z.Z.Z.Z
   # with the addresses of the Consul server nodes
   consul['configuration'] = {
      retry_join: %w(Y.Y.Y.Y consul1.gitlab.example.com Z.Z.Z.Z),
   }

   # Set the network addresses that the exporters will listen on
   node_exporter['listen_address'] = '0.0.0.0:9100'
   pgbouncer_exporter['listen_address'] = '0.0.0.0:9188'
   ```

1. `sudo gitlab-ctl reconfigure`를 실행하여 구성을 컴파일합니다.

## 관리 콘솔 {#administrative-console}

Linux 패키지 설치에서는 PgBouncer 관리 콘솔에 자동으로 연결할 수 있는 명령이 제공됩니다. 콘솔과 상호작용하는 방법에 대한 자세한 지침은 [PgBouncer 설명서](https://www.pgbouncer.org/usage.html#admin-console)를 참조합니다.

세션을 시작하려면 다음을 실행하고 `pgbouncer` 사용자의 비밀번호를 입력합니다:

```shell
sudo gitlab-ctl pgb-console
```

인스턴스에 대한 기본 정보를 가져오려면:

```shell
pgbouncer=# show databases; show clients; show servers;
        name         |   host    | port |      database       | force_user | pool_size | reserve_pool | pool_mode | max_connections | current_connections
---------------------+-----------+------+---------------------+------------+-----------+--------------+-----------+-----------------+---------------------
 gitlabhq_production | 127.0.0.1 | 5432 | gitlabhq_production |            |       100 |            5 |           |               0 |                   1
 pgbouncer           |           | 6432 | pgbouncer           | pgbouncer  |         2 |            0 | statement |               0 |                   0
(2 rows)

 type |   user    |      database       | state  |   addr    | port  | local_addr | local_port |    connect_time     |    request_time     |    ptr    | link
| remote_pid | tls
------+-----------+---------------------+--------+-----------+-------+------------+------------+---------------------+---------------------+-----------+------
+------------+-----
 C    | gitlab    | gitlabhq_production | active | 127.0.0.1 | 44590 | 127.0.0.1  |       6432 | 2018-04-24 22:13:10 | 2018-04-24 22:17:10 | 0x12444c0 |
|          0 |
 C    | gitlab    | gitlabhq_production | active | 127.0.0.1 | 44592 | 127.0.0.1  |       6432 | 2018-04-24 22:13:10 | 2018-04-24 22:17:10 | 0x12447c0 |
|          0 |
 C    | gitlab    | gitlabhq_production | active | 127.0.0.1 | 44594 | 127.0.0.1  |       6432 | 2018-04-24 22:13:10 | 2018-04-24 22:17:10 | 0x1244940 |
|          0 |
 C    | gitlab    | gitlabhq_production | active | 127.0.0.1 | 44706 | 127.0.0.1  |       6432 | 2018-04-24 22:14:22 | 2018-04-24 22:16:31 | 0x1244ac0 |
|          0 |
 C    | gitlab    | gitlabhq_production | active | 127.0.0.1 | 44708 | 127.0.0.1  |       6432 | 2018-04-24 22:14:22 | 2018-04-24 22:15:15 | 0x1244c40 |
|          0 |
 C    | gitlab    | gitlabhq_production | active | 127.0.0.1 | 44794 | 127.0.0.1  |       6432 | 2018-04-24 22:15:15 | 2018-04-24 22:15:15 | 0x1244dc0 |
|          0 |
 C    | gitlab    | gitlabhq_production | active | 127.0.0.1 | 44798 | 127.0.0.1  |       6432 | 2018-04-24 22:15:15 | 2018-04-24 22:16:31 | 0x1244f40 |
|          0 |
 C    | pgbouncer | pgbouncer           | active | 127.0.0.1 | 44660 | 127.0.0.1  |       6432 | 2018-04-24 22:13:51 | 2018-04-24 22:17:12 | 0x1244640 |
|          0 |
(8 rows)

 type |  user  |      database       | state |   addr    | port | local_addr | local_port |    connect_time     |    request_time     |    ptr    | link | rem
ote_pid | tls
------+--------+---------------------+-------+-----------+------+------------+------------+---------------------+---------------------+-----------+------+----
--------+-----
 S    | gitlab | gitlabhq_production | idle  | 127.0.0.1 | 5432 | 127.0.0.1  |      35646 | 2018-04-24 22:15:15 | 2018-04-24 22:17:10 | 0x124dca0 |      |
  19980 |
(1 row)
```

## PgBouncer 우회 절차 {#procedure-for-bypassing-pgbouncer}

### Linux 패키지 설치 {#linux-package-installations}

일부 데이터베이스 변경은 PgBouncer를 통하지 않고 직접 수행해야 합니다.

주요 영향을 받는 작업은 [데이터베이스 복원](../backup_restore/backup_gitlab.md#back-up-and-restore-for-installations-using-pgbouncer) 및 [데이터베이스 마이그레이션을 포함한 GitLab 업그레이드](../../update/zero_downtime.md)입니다.

1. 기본 노드를 찾으려면 데이터베이스 노드에서 다음을 실행합니다:

   ```shell
   sudo gitlab-ctl patroni members
   ```

1. 작업을 수행 중인 애플리케이션 노드에서 `/etc/gitlab/gitlab.rb`를 편집하고 `gitlab_rails['db_host']` 및 `gitlab_rails['db_port']`을(를) 데이터베이스 기본의 호스트 및 포트로 업데이트합니다.

1. 재구성을 실행합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

작업이나 절차를 수행한 후 PgBouncer 사용으로 다시 전환합니다:

1. `/etc/gitlab/gitlab.rb`을(를) PgBouncer를 가리키도록 다시 변경합니다.
1. 재구성을 실행합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### Helm 차트 설치 {#helm-chart-installations}

고가용성 배포도 Linux 패키지 기반과 같은 이유로 PgBouncer를 우회해야 합니다. Helm 차트 설치의 경우:

- 데이터베이스 백업 및 복원 작업은 도구 상자 컨테이너에서 수행됩니다.
- 마이그레이션 작업은 마이그레이션 컨테이너에서 수행됩니다.

각 하위 차트에서 PostgreSQL 포트를 재정의하여 이러한 작업을 실행하고 PostgreSQL에 직접 연결할 수 있습니다:

- [도구 상자](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/charts/gitlab/charts/toolbox/values.yaml#L40)
- [마이그레이션](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/charts/gitlab/charts/migrations/values.yaml#L46)

## 세부 조정 {#fine-tuning}

PgBouncer의 기본 설정은 대부분의 설치에 적합합니다. 특정 경우에는 성능별 및 리소스별 변수를 변경하여 처리량을 증가시키거나 데이터베이스에서 메모리 고갈을 야기할 수 있는 리소스 사용을 제한할 수 있습니다.

[공식 PgBouncer 설명서](https://www.pgbouncer.org/config.html)에서 매개변수 및 각각의 설명서를 찾을 수 있습니다. 아래에는 가장 관련성 높은 것들과 Linux 패키지 설치에서의 기본값이 나열되어 있습니다:

- `pgbouncer['max_client_conn']` (기본값: `2048`, 서버 파일 설명자 제한에 따라 다름) 이는 PgBouncer의 "프론트엔드" 풀입니다: Rails에서 PgBouncer로의 연결.
- `pgbouncer['default_pool_size']` (기본값: `100`) 이는 PgBouncer의 "백엔드" 풀입니다: PgBouncer에서 데이터베이스로의 연결.

`default_pool_size`의 이상적인 수는 데이터베이스에 액세스해야 하는 모든 프로비저닝된 서비스를 처리할 수 있을 만큼 충분해야 합니다. 필요한 풀 크기를 계산하는 방법에 대한 자세한 지침은 [PostgreSQL 튜닝](tune.md)을(를) 참조합니다.

내부 로드 밸런서가 있는 PgBouncer가 두 개 이상인 경우 `default_pool_size`을(를) 인스턴스 수로 나누어 그들 사이에 균등하게 분산된 로드를 보장할 수 있습니다.

`pgbouncer['max_client_conn']`는 PgBouncer가 허용할 수 있는 연결의 상한입니다. 변경할 필요가 없을 가능성이 높습니다. 해당 제한에 도달하면 내부 로드 밸런서가 있는 추가 PgBouncers 추가를 고려할 수 있습니다.

Geo 추적 데이터베이스를 가리키는 PgBouncer의 제한을 설정할 때 `puma`를 수식에서 무시할 수 있습니다. 해당 데이터베이스에만 가끔 액세스하기 때문입니다.

## 문제 해결 {#troubleshooting}

PgBouncer를 통해 연결하는 데 문제가 있는 경우 먼저 확인해야 할 위치는 항상 로그입니다:

```shell
sudo gitlab-ctl tail pgbouncer
```

또한 `show databases`의 출력을 [관리 콘솔](#administrative-console)에서 확인할 수 있습니다. 출력에서 `gitlabhq_production` 데이터베이스에 대한 `host` 필드에 값이 표시될 것으로 예상됩니다. 또한 `current_connections`는 1보다 커야 합니다.

### 메시지: `LOG:  invalid CIDR mask in address` {#message-log--invalid-cidr-mask-in-address}

[Geo 설명서](../geo/replication/troubleshooting/postgresql_replication.md#message-log--invalid-cidr-mask-in-address)에서 제안된 수정을 참조합니다.

### 메시지: `LOG:  invalid IP mask "md5": Name or service not known` {#message-log--invalid-ip-mask-md5-name-or-service-not-known}

[Geo 설명서](../geo/replication/troubleshooting/postgresql_replication.md#message-log--invalid-ip-mask-md5-name-or-service-not-known)에서 제안된 수정을 참조합니다.
