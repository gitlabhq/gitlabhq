---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 일반적인 Geo 오류 문제 해결
description: "일반적인 Geo 문제를 진단하고 해결합니다. 상태 확인, 데이터베이스 복제 문제, 사이트 연결 및 오류 해결 절차를 다룹니다."
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

## 기본 문제 해결 {#basic-troubleshooting}

고급 문제 해결을 시도하기 전에:

- [Geo 사이트의 상태](#check-the-health-of-the-geo-sites)를 확인합니다.
- [PostgreSQL 복제가 작동 중인지 확인](#check-if-postgresql-replication-is-working)합니다.

### Geo 사이트 간 요청 추적 {#tracing-requests-across-geo-sites}

Geo 문제를 해결할 때, 세컨더리 사이트에서 프라이머리 사이트로의 요청을 추적하거나 그 반대로 추적해야 할 수 있습니다. GitLab은 상관 ID를 사용하여 서비스 전체의 관련 로그 항목을 연결합니다.

기본적으로 각 사이트는 요청을 수신할 때 자체 상관 ID를 생성합니다. 동일한 상관 ID를 사용하여 두 사이트 간 단일 요청을 추적하려면 각 수신 사이트의 Workhorse를 다른 Geo 사이트의 수신 상관 ID를 받도록 구성해야 합니다.

모든 Geo 사이트에서:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   gitlab_workhorse['propagate_correlation_id'] = true
   gitlab_workhorse['trusted_cidrs_for_propagation'] = %w(<secondary-site-ip>/32)
   ```

1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Helm 값을 업데이트합니다:

   ```yaml
   gitlab:
     webservice:
       workhorse:
         extraArgs: "-propagateCorrelationID"
         trustedCIDRsForPropagation: ["<secondary-site-ip>/32"]
   ```

1. 변경 사항을 적용합니다.

{{< /tab >}}

{{< /tabs >}}

이 설정을 활성화한 후 세컨더리 사이트에서 프라이머리 사이트로 전송된 요청은 로그에서 동일한 상관 ID를 공유하므로 두 사이트 간 요청을 추적할 수 있습니다.

### Geo 사이트의 상태 확인 {#check-the-health-of-the-geo-sites}

**프라이머리** 사이트에서:

1. 오른쪽 위 모서리에서 **운영자**를 선택하세요.
1. 왼쪽 사이드바에서 **Geo** > **사이트**를 선택하세요.

각 **세컨더리** 사이트에서 다음 상태 확인을 수행하여 문제를 식별하는 데 도움을 줍니다:

- 사이트가 실행 중입니까?
- 세컨더리 사이트의 데이터베이스가 스트리밍 복제를 위해 구성되었습니까?
- 세컨더리 사이트의 추적 데이터베이스가 구성되었습니까?
- 세컨더리 사이트의 추적 데이터베이스가 연결되었습니까?
- 세컨더리 사이트의 추적 데이터베이스가 최신 상태입니까?
- 세컨더리 사이트의 상태가 1시간 이내입니까?

사이트의 상태가 1시간 이상 지난 경우 사이트는 "양호하지 않음"으로 표시됩니다. 이 경우 영향을 받는 세컨더리 사이트의 [레일 콘솔](../../../operations/rails_console.md)에서 다음을 실행해 봅니다:

```ruby
Geo::MetricsUpdateWorker.new.perform
```

오류가 발생하면 오류 때문에 작업이 완료되지 않을 수도 있습니다. 1시간 이상 소요되면 상태가 간헐적으로 업데이트되더라도 상태가 "양호하지 않음"으로 표시되거나 유지될 수 있습니다. 이는 사용량의 증가, 시간 경과에 따른 데이터 증가, 또는 누락된 데이터베이스 인덱스와 같은 성능 버그 때문일 수 있습니다.

`top` 또는 `htop`와 같은 유틸리티로 시스템 CPU 로드를 모니터링할 수 있습니다. PostgreSQL이 상당한 양의 CPU를 사용 중이면 문제가 있거나 시스템이 과소 프로비저닝된 것을 나타낼 수 있습니다. 시스템 메모리도 모니터링해야 합니다.

메모리를 증가시키는 경우 `/etc/gitlab/gitlab.rb` 구성에서 PostgreSQL 메모리 관련 설정도 확인해야 합니다.

상태를 성공적으로 업데이트하면 Sidekiq에 문제가 있을 수 있습니다. 실행 중입니까? 로그에 오류가 표시됩니까? 이 작업은 매분마다 대기열에 추가되어야 하며 [작업 중복 제거 멱등성](../../../sidekiq/sidekiq_troubleshooting.md#clearing-a-sidekiq-job-deduplication-idempotency-key) 키가 제대로 지워지지 않으면 실행되지 않을 수 있습니다. Redis에서 배타적 리스이를 사용하여 이러한 작업 중 하나만 동시에 실행될 수 있도록 합니다. 프라이머리 사이트는 PostgreSQL 데이터베이스에서 직접 상태를 업데이트합니다. 세컨더리 사이트는 상태 데이터와 함께 프라이머리 사이트에 HTTP Post 요청을 보냅니다.

특정 상태 확인이 실패하면 사이트도 "양호하지 않음"으로 표시됩니다. 영향을 받는 세컨더리 사이트의 [레일 콘솔](../../../operations/rails_console.md)에서 다음을 실행하여 실패를 확인할 수 있습니다:

```ruby
Gitlab::Geo::HealthCheck.new.perform_checks
```

`""`(빈 문자열) 또는 `"Healthy"`를 반환하면 확인이 성공했습니다. 다른 것을 반환하면 메시지에 실패한 내용을 설명하거나 예외 메시지를 표시해야 합니다.

사용자 인터페이스에서 보고된 일반적인 오류 메시지를 해결하는 방법에 대한 정보는 [일반적인 오류 수정](#fixing-common-errors)을 참조하세요.

사용자 인터페이스가 작동하지 않거나 로그인할 수 없으면 Geo 상태 확인을 수동으로 실행하여 이 정보 및 추가 세부 정보를 얻을 수 있습니다.

#### 상태 확인 Rake 작업 {#health-check-rake-task}

{{< history >}}

- 사용자 지정 NTP 서버의 사용은 GitLab 15.7에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105514).

{{< /history >}}

이 Rake 작업은 Geo 사이트의 **레일** 노드에서 **프라이머리** 또는 **세컨더리** 사이트에서 실행할 수 있습니다:

```shell
sudo gitlab-rake gitlab:geo:check
```

출력 예:

```plaintext
Checking Geo ...

GitLab Geo is available ... yes
GitLab Geo is enabled ... yes
This machine's Geo node name matches a database record ... yes, found a secondary node named "Shanghai"
GitLab Geo tracking database is correctly configured ... yes
Database replication enabled? ... yes
Database replication working? ... yes
GitLab Geo HTTP(S) connectivity ...
* Can connect to the primary node ... yes
HTTP/HTTPS repository cloning is enabled ... yes
Machine clock is synchronized ... yes
Git user has default SSH configuration? ... yes
OpenSSH configured to use AuthorizedKeysCommand ... yes
GitLab configured to disable writing to authorized_keys file ... yes
GitLab configured to store new projects in hashed storage? ... yes
All projects are in hashed storage? ... yes
Container Registry replication enabled ... yes
Container Registry Geo events ... last event at 2024-01-15 10:30:00 UTC

Checking Geo ... Finished
```

환경 변수를 사용하여 사용자 지정 NTP 서버를 지정할 수도 있습니다. 예를 들어:

```shell
sudo gitlab-rake gitlab:geo:check NTP_HOST="ntp.ubuntu.com" NTP_TIMEOUT="30"
```

다음 환경 변수가 지원됩니다.

| 변수      | 설명 | 기본값 |
| ------------- | ----------- | ------------- |
| `NTP_HOST`    | NTP 호스트입니다. | `pool.ntp.org` |
| `NTP_PORT`    | 호스트가 수신하는 NTP 포트입니다. | `123` |
| `NTP_TIMEOUT` | 초 단위의 NTP 타임아웃입니다. | `net-ntp` Ruby 라이브러리에 정의된 값([60초](https://github.com/zencoder/net-ntp/blob/3d0990214f439a5127782e0f50faeaf2c8ca7023/lib/net/ntp/ntp.rb#L6))입니다. |

Rake 작업이 `OpenSSH configured to use AuthorizedKeysCommand` 확인을 건너뛰면 다음 출력이 표시됩니다:

```plaintext
OpenSSH configured to use AuthorizedKeysCommand ... skipped
  Reason:
  Cannot access OpenSSH configuration file
  Try fixing it:
  This is expected if you are using SELinux. You may want to check configuration manually
  For more information see:
  doc/administration/operations/fast_ssh_key_lookup.md
```

이 문제는 다음과 같은 경우 발생할 수 있습니다:

- [SELinux](../../../operations/fast_ssh_key_lookup.md#selinux-support)를 사용합니다.
- SELinux를 사용하지 않으며 `git` 사용자가 파일 권한 제한으로 인해 OpenSSH 구성 파일에 액세스할 수 없습니다.

후자의 경우 다음 출력은 `root` 사용자만 이 파일을 읽을 수 있음을 보여줍니다:

```plaintext
sudo stat -c '%G:%U %A %a %n' /etc/ssh/sshd_config

root:root -rw------- 600 /etc/ssh/sshd_config
```

`git` 사용자가 파일 소유자나 권한을 변경하지 않고 OpenSSH 구성 파일을 읽을 수 있도록 하려면 `acl`을(를) 사용합니다:

```plaintext
sudo setfacl -m u:git:r /etc/ssh/sshd_config
```

#### 동기화 상태 Rake 작업 {#sync-status-rake-task}

현재 동기화 정보는 Geo **세컨더리** 사이트의 Rails(Puma, Sidekiq 또는 Geo Log Cursor)를 실행하는 모든 노드에서 이 Rake 작업을 실행하여 수동으로 찾을 수 있습니다.

GitLab은 **not** 객체 스토리지에 저장된 객체를 확인합니다. 객체 스토리지를 사용 중이면 "verified" 확인이 모두 0개의 성공을 표시합니다. 이는 예상된 것이며 우려 사항이 아닙니다.

```shell
sudo gitlab-rake gitlab:geo:status
```

출력에 포함됩니다:

- 실패가 발생한 경우 "failed" 항목의 개수
- "total"에 대한 "succeeded" 항목의 백분율

예:

```plaintext
                        Geo Site Information
--------------------------------------------
                                      Name: example-us-east-2
                                       URL: https://gitlab.example.com
                                  Geo Role: Secondary
                             Health Status: Healthy
                This Node's GitLab Version: 17.7.0-ee

                     Replication Information
--------------------------------------------
                             Sync Settings: Full
                  Database replication lag: 0 seconds
           Last event ID seen from primary: 12345 (about 2 minutes ago)
                   Last event ID processed: 12345 (about 2 minutes ago)
                    Last status report was: 1 minute ago

                          Replication Status
--------------------------------------------
                    Lfs Objects replicated: succeeded 111 / total 111 (100%)
            Merge Request Diffs replicated: succeeded 28 / total 28 (100%)
                  Package Files replicated: succeeded 90 / total 90 (100%)
       Terraform State Versions replicated: succeeded 65 / total 65 (100%)
           Snippet Repositories replicated: succeeded 63 / total 63 (100%)
        Group Wiki Repositories replicated: succeeded 14 / total 14 (100%)
             Pipeline Artifacts replicated: succeeded 112 / total 112 (100%)
              Pages Deployments replicated: succeeded 55 / total 55 (100%)
                        Uploads replicated: succeeded 2 / total 2 (100%)
                  Job Artifacts replicated: succeeded 32 / total 32 (100%)
                Ci Secure Files replicated: succeeded 44 / total 44 (100%)
         Dependency Proxy Blobs replicated: succeeded 15 / total 15 (100%)
     Dependency Proxy Manifests replicated: succeeded 2 / total 2 (100%)
      Project Wiki Repositories replicated: succeeded 2 / total 2 (100%)
 Design Management Repositories replicated: succeeded 1 / total 1 (100%)
           Project Repositories replicated: succeeded 2 / total 2 (100%)

                         Verification Status
--------------------------------------------
                      Lfs Objects verified: succeeded 111 / total 111 (100%)
              Merge Request Diffs verified: succeeded 28 / total 28 (100%)
                    Package Files verified: succeeded 90 / total 90 (100%)
         Terraform State Versions verified: succeeded 65 / total 65 (100%)
             Snippet Repositories verified: succeeded 63 / total 63 (100%)
          Group Wiki Repositories verified: succeeded 14 / total 14 (100%)
               Pipeline Artifacts verified: succeeded 112 / total 112 (100%)
                Pages Deployments verified: succeeded 55 / total 55 (100%)
                          Uploads verified: succeeded 2 / total 2 (100%)
                    Job Artifacts verified: succeeded 32 / total 32 (100%)
                  Ci Secure Files verified: succeeded 44 / total 44 (100%)
           Dependency Proxy Blobs verified: succeeded 15 / total 15 (100%)
       Dependency Proxy Manifests verified: succeeded 2 / total 2 (100%)
        Project Wiki Repositories verified: succeeded 2 / total 2 (100%)
   Design Management Repositories verified: succeeded 1 / total 1 (100%)
             Project Repositories verified: succeeded 2 / total 2 (100%)

```

모든 객체가 복제되고 검증되며, 이는 [Geo 용어집](../../glossary.md)에 정의되어 있습니다. [지원되는 Geo 데이터 유형](../datatypes.md#data-types)에서 각 데이터 유형을 복제하고 확인하는 방법에 대해 자세히 알아봅니다.

실패한 항목에 대한 자세한 내용을 확인하려면 [`gitlab-rails/geo.log` 파일](../../../logs/log_parsing.md#find-most-common-geo-sync-errors)을(를) 확인합니다.

복제 또는 검증 실패가 있으면 [해결](synchronization_verification.md)할 수 있습니다.

##### Geo 확인 Rake 작업을 실행할 때 발견된 오류 수정 {#fixing-errors-found-when-running-the-geo-check-rake-task}

이 Rake 작업을 실행할 때 노드가 올바르게 구성되지 않으면 오류 메시지가 표시될 수 있습니다:

```shell
sudo gitlab-rake gitlab:geo:check
```

- Rails가 데이터베이스에 연결할 때 암호를 제공하지 않았습니다.

  ```plaintext
  Checking Geo ...

  GitLab Geo is available ... Exception: fe_sendauth: no password supplied
  GitLab Geo is enabled ... Exception: fe_sendauth: no password supplied
  ...
  Checking Geo ... Finished
  ```

  `gitlab_rails['db_password']`이(가) `postgresql['sql_user_password']` 해시를 생성할 때 사용된 일반 텍스트 암호로 설정되어 있는지 확인합니다.

- Rails가 데이터베이스에 연결할 수 없습니다.

  ```plaintext
  Checking Geo ...

  GitLab Geo is available ... Exception: FATAL:  no pg_hba.conf entry for host "1.1.1.1",  user "gitlab", database "gitlabhq_production", SSL on
  FATAL:  no pg_hba.conf entry for host "1.1.1.1", user "gitlab", database "gitlabhq_production", SSL off
  GitLab Geo is enabled ... Exception: FATAL:  no pg_hba.conf entry for host "1.1.1.1", user "gitlab", database "gitlabhq_production", SSL on
  FATAL:  no pg_hba.conf entry for host "1.1.1.1", user "gitlab", database "gitlabhq_production", SSL off
  ...
  Checking Geo ... Finished
  ```

  Rails 노드의 IP 주소가 `postgresql['md5_auth_cidr_addresses']`에 포함되어 있는지 확인합니다. 또한 IP 주소에 서브넷 마스크를 포함했는지 확인합니다: `postgresql['md5_auth_cidr_addresses'] = ['1.1.1.1/32']`.

- Rails가 잘못된 암호를 제공했습니다.

  ```plaintext
  Checking Geo ...
  GitLab Geo is available ... Exception: FATAL:  password authentication failed for user "gitlab"
  FATAL:  password authentication failed for user "gitlab"
  GitLab Geo is enabled ... Exception: FATAL:  password authentication failed for user "gitlab"
  FATAL:  password authentication failed for user "gitlab"
  ...
  Checking Geo ... Finished
  ```

  `gitlab_rails['db_password']`에 대해 올바른 암호가 설정되어 있는지 확인합니다. 이 암호는 `postgresql['sql_user_password']`에서 해시를 생성할 때 사용되었으며 `gitlab-ctl pg-password-md5 gitlab`을(를) 실행하고 암호를 입력하여 확인합니다.

- 확인이 `not a secondary node`을(를) 반환합니다.

  ```plaintext
  Checking Geo ...

  GitLab Geo is available ... yes
  GitLab Geo is enabled ... yes
  GitLab Geo tracking database is correctly configured ... not a secondary node
  Database replication enabled? ... not a secondary node
  ...
  Checking Geo ... Finished
  ```

  **운영자** 영역에서 **Geo** > **사이트** 아래의 **프라이머리** 사이트의 웹 인터페이스에 세컨더리 사이트를 추가했는지 확인합니다. 또한 **운영자** 영역에서 **프라이머리** 사이트의 세컨더리 사이트를 추가할 때 `gitlab_rails['geo_node_name']`을(를) 입력했는지 확인합니다.

- 확인이 `Exception: PG::UndefinedTable: ERROR:  relation "geo_nodes" does not exist`을(를) 반환합니다.

  ```plaintext
  Checking Geo ...

  GitLab Geo is available ... no
    Try fixing it:
    Add a new license that includes the GitLab Geo feature
    For more information see:
    https://about.gitlab.com/features/gitlab-geo/
  GitLab Geo is enabled ... Exception: PG::UndefinedTable: ERROR:  relation "geo_nodes" does not exist
  LINE 8:                WHERE a.attrelid = '"geo_nodes"'::regclass
                                             ^
  :               SELECT a.attname, format_type(a.atttypid, a.atttypmod),
                       pg_get_expr(d.adbin, d.adrelid), a.attnotnull, a.atttypid, a.atttypmod,
                       c.collname, col_description(a.attrelid, a.attnum) AS comment
                  FROM pg_attribute a
                  LEFT JOIN pg_attrdef d ON a.attrelid = d.adrelid AND a.attnum = d.adnum
                  LEFT JOIN pg_type t ON a.atttypid = t.oid
                  LEFT JOIN pg_collation c ON a.attcollation = c.oid AND a.attcollation <> t.typcollation
                 WHERE a.attrelid = '"geo_nodes"'::regclass
                   AND a.attnum > 0 AND NOT a.attisdropped
                 ORDER BY a.attnum
  ...
  Checking Geo ... Finished
  ```

  PostgreSQL 주요 버전 업데이트(9 > 10)를 수행할 때 이는 예상됩니다. [복제 프로세스 시작](../../setup/database.md#step-3-initiate-the-replication-process)을(를) 따릅니다.

- Rails는 Geo 추적 데이터베이스에 연결하는 데 필요한 구성이 없는 것으로 보입니다.

  ```plaintext
  Checking Geo ...

  GitLab Geo is available ... yes
  GitLab Geo is enabled ... yes
  GitLab Geo tracking database is correctly configured ... no
  Try fixing it:
  Rails does not appear to have the configuration necessary to connect to the Geo tracking database. If the tracking database is running on a node other than this one, then you may need to add configuration.
  ...
  Checking Geo ... Finished
  ```

  - 모든 서비스에 대해 세컨더리 사이트를 단일 노드에서 실행 중인 경우 [Geo 데이터베이스 복제 - 세컨더리 서버 구성](../../setup/database.md#step-2-configure-the-secondary-server)을(를) 따릅니다.
  - 세컨더리 사이트의 추적 데이터베이스를 자체 노드에서 실행 중인 경우 [여러 서버의 Geo - Geo 세컨더리 사이트에서 Geo 추적 데이터베이스 구성](../multiple_servers.md#step-2-configure-the-geo-tracking-database-on-the-geo-secondary-site)을(를) 따릅니다.
  - 세컨더리 사이트의 추적 데이터베이스를 Patroni 클러스터에서 실행 중인 경우 [Geo 데이터베이스 복제 - 추적 PostgreSQL 데이터베이스를 위한 Patroni 클러스터 구성](../../setup/database.md#configuring-patroni-cluster-for-the-tracking-postgresql-database)을(를) 따릅니다.
  - 세컨더리 사이트의 추적 데이터베이스를 외부 데이터베이스에서 실행 중인 경우 [외부 PostgreSQL 인스턴스를 사용하는 Geo](../../setup/external_database.md#configure-the-tracking-database)를 따릅니다.
  - GitLab Rails 앱(Puma, Sidekiq 또는 Geo Log Cursor)을 실행하는 서비스를 실행하지 않는 노드에서 Geo 확인 작업을 실행한 경우 이 오류는 무시할 수 있습니다. 노드는 Rails가 구성되어 있을 필요가 없습니다.

##### 메시지:  컨테이너 레지스트리 Geo 이벤트 ... 없음 {#message-container-registry-geo-events--none-found}

`Container Registry Geo events ... none found`이(가) 표시되고 컨테이너 레지스트리 복제 이벤트가 있을 것으로 예상하면 **프라이머리** 사이트의 레지스트리 알림 구성이 [컨테이너 레지스트리 복제 구성 가이드](../container_registry.md#configure-primary-site)에 따라 구성되어 있는지 확인합니다.

##### 메시지:  머신 시계 동기화 ... 예외 {#message-machine-clock-is-synchronized--exception}

Rake 작업은 서버 시계가 NTP와 동기화되어 있는지 확인을 시도합니다. 동기화된 시계는 Geo가 올바르게 작동하는 데 필요합니다. 예를 들어, 보안상 프라이머리 사이트와 세컨더리 사이트의 서버 시간이 약 1분 이상 차이가 나면 Geo 사이트 간 요청이 실패합니다. 이 확인 작업이 시간 불일치 이외의 이유로 완료되지 못하면 Geo가 작동하지 않는다는 의미는 아닙니다.

확인을 수행하는 Ruby gem은 `pool.ntp.org`을(를) 참조 시간 소스로 하드코딩합니다.

- 예외 메시지 `Machine clock is synchronized ... Exception: Timeout::Error`

  이 문제는 서버가 호스트 `pool.ntp.org`에 액세스할 수 없을 때 발생합니다.

- 예외 메시지 `Machine clock is synchronized ... Exception: No route to host - recvfrom(2)`

  이 문제는 호스트 이름 `pool.ntp.org`이(가) 시간 서비스를 제공하지 않는 서버로 확인될 때 발생합니다.

이 경우 GitLab 15.7 이상에서는 [환경 변수를 사용하여 사용자 지정 NTP 서버를 지정](#health-check-rake-task)합니다.

GitLab 15.6 이전에는 다음 해결 방법 중 하나를 사용합니다:

- `/etc/hosts`에 `pool.ntp.org` 항목을 추가하여 요청을 유효한 로컬 시간 서버로 보냅니다. 이는 긴 타임아웃 및 타임아웃 오류를 수정합니다.
- 확인을 유효한 IP 주소로 직접 보냅니다. 이는 타임아웃 문제를 해결하지만 `No route to host` 오류로 확인이 실패합니다(이전에 언급한 대로).

[클라우드 네이티브 GitLab 배포](https://docs.gitlab.com/charts/advanced/geo/#set-the-geo-primary-site)는 Kubernetes의 컨테이너가 호스트 클록에 액세스할 수 없기 때문에 오류를 생성합니다:

```plaintext
Machine clock is synchronized ... Exception: getaddrinfo: Servname not supported for ai_socktype
```

##### 메시지: `cannot execute INSERT in a read-only transaction` {#message-cannot-execute-insert-in-a-read-only-transaction}

세컨더리 사이트에서 이 오류가 발생하면 `gitlab-rails` 또는 `gitlab-rake` 명령과 같은 GitLab Rails의 모든 사용에 영향을 미칠 수 있으며 Puma, Sidekiq 및 Geo Log Cursor 서비스도 영향을 받습니다.

```plaintext
ActiveRecord::StatementInvalid: PG::ReadOnlySqlTransaction: ERROR:  cannot execute INSERT in a read-only transaction
/opt/gitlab/embedded/service/gitlab-rails/app/models/application_record.rb:86:in `block in safe_find_or_create_by'
/opt/gitlab/embedded/service/gitlab-rails/app/models/concerns/cross_database_modification.rb:92:in `block in transaction'
/opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/database.rb:332:in `block in transaction'
/opt/gitlab/embedded/service/gitlab-rails/lib/gitlab/database.rb:331:in `transaction'
/opt/gitlab/embedded/service/gitlab-rails/app/models/concerns/cross_database_modification.rb:83:in `transaction'
/opt/gitlab/embedded/service/gitlab-rails/app/models/application_record.rb:86:in `safe_find_or_create_by'
/opt/gitlab/embedded/service/gitlab-rails/app/models/shard.rb:21:in `by_name'
/opt/gitlab/embedded/service/gitlab-rails/app/models/shard.rb:17:in `block in populate!'
/opt/gitlab/embedded/service/gitlab-rails/app/models/shard.rb:17:in `map'
/opt/gitlab/embedded/service/gitlab-rails/app/models/shard.rb:17:in `populate!'
/opt/gitlab/embedded/service/gitlab-rails/config/initializers/fill_shards.rb:9:in `<top (required)>'
/opt/gitlab/embedded/service/gitlab-rails/config/environment.rb:7:in `<top (required)>'
/opt/gitlab/embedded/bin/bundle:23:in `load'
/opt/gitlab/embedded/bin/bundle:23:in `<main>'
```

PostgreSQL 읽기 복제본 데이터베이스에서 이러한 오류가 발생합니다:

```plaintext
2023-01-17_17:44:54.64268 ERROR:  cannot execute INSERT in a read-only transaction
2023-01-17_17:44:54.64271 STATEMENT:  /*application:web,db_config_name:main*/ INSERT INTO "shards" ("name") VALUES ('storage1') RETURNING "id"
```

이 상황은 다음과 같은 경우 발생할 수 있습니다:

- 초기 구성 중 세컨더리 사이트가 아직 세컨더리 사이트라는 것을 인식하지 못할 때입니다. 오류를 해결하려면 [단계 3을(를) 따릅니다. 세컨더리 사이트 추가](../configuration.md#step-3-add-the-secondary-site).
- Geo 세컨더리 사이트의 업그레이드 중입니다. `gitlab_rails['auto_migrate']`이(가) `true`로 설정되어 있어서 GitLab이 필요하지 않은 복제본 데이터베이스에서 데이터베이스 마이그레이션을 시도할 수 있습니다. 오류를 해결하려면:

  1. 세컨더리 사이트의 GitLab Rails 노드에 루트로 SSH합니다.
  1. `/etc/gitlab/gitlab.rb`을(를) 편집하고 이 설정을 주석 처리하거나 false로 설정합니다:

     ```ruby
     gitlab_rails['auto_migrate'] = false
     ```

  1. GitLab을 다시 구성하세요:

     ```shell
     sudo gitlab-ctl reconfigure
     ```

### PostgreSQL 복제가 작동 중인지 확인 {#check-if-postgresql-replication-is-working}

PostgreSQL 복제가 작동 중인지 확인하려면 다음을 확인합니다:

- [사이트가 올바른 데이터베이스 노드를 가리키고 있습니다](#are-sites-pointing-to-the-correct-database-node).
- [Geo가 현재 사이트를 올바르게 감지할 수 있습니다](#can-geo-detect-the-current-site-correctly).

여전히 문제가 있으면 [고급 복제 문제 해결](synchronization_verification.md)을(를) 참조하세요.

#### 사이트가 올바른 데이터베이스 노드를 가리키고 있습니까? {#are-sites-pointing-to-the-correct-database-node}

**프라이머리** Geo [사이트](../../glossary.md)가 쓰기 권한이 있는 데이터베이스 노드를 가리키는지 확인해야 합니다.

**세컨더리** 사이트는 읽기 전용 데이터베이스 노드만 가리켜야 합니다.

#### Geo가 현재 사이트를 올바르게 감지할 수 있습니까? {#can-geo-detect-the-current-site-correctly}

Geo는 현재 Puma 또는 Sidekiq 노드의 Geo [사이트](../../glossary.md) 이름을 `/etc/gitlab/gitlab.rb`에서 다음 논리로 찾습니다:

1. "Geo 노드 이름"을(를) 가져옵니다([설정을 "Geo 사이트 이름"으로 이름을 바꾸는 문제](https://gitlab.com/gitlab-org/gitlab/-/issues/335944)가 있음):
   - Linux package: `gitlab_rails['geo_node_name']` 설정을 가져옵니다.
   - GitLab Helm 차트: `global.geo.nodeName` 설정을 가져옵니다([GitLab Geo가 있는 차트](https://docs.gitlab.com/charts/advanced/geo/) 참조).
1. 정의되지 않은 경우 `external_url` 설정을 가져옵니다.

이 이름은 **Geo 사이트** 대시보드에서 동일한 **이름**을(를) 가진 Geo 사이트를 찾는 데 사용됩니다.

현재 머신에 데이터베이스의 사이트와 일치하는 사이트 이름이 있는지 확인하려면 확인 작업을 실행합니다:

```shell
sudo gitlab-rake gitlab:geo:check
```

현재 머신의 사이트 이름과 일치하는 데이터베이스 레코드가 **프라이머리** 또는 **세컨더리** 사이트인지 표시합니다.

```plaintext
This machine's Geo node name matches a database record ... yes, found a secondary node named "Shanghai"
```

```plaintext
This machine's Geo node name matches a database record ... no
  Try fixing it:
  You could add or update a Geo node database record, setting the name to "https://example.com/".
  Or you could set this machine's Geo node name to match the name of an existing database record: "London", "Shanghai"
  For more information see:
  doc/administration/geo/replication/troubleshooting/_index.md#can-geo-detect-the-current-node-correctly
```

이름 필드의 설명에서 권장 사이트 이름에 대한 자세한 내용은 [Geo **운영자** 영역 일반 설정](../../../geo_sites.md#common-settings)을(를) 참조하세요.

### OS 로케일 데이터 호환성 확인 {#check-os-locale-data-compatibility}

가능하면 모든 Geo 노드는 [Geo 실행 요구 사항](../../_index.md#requirements-for-running-geo)에 정의된 것처럼 동일한 방법과 운영 체제로 배포되어야 합니다.

Geo 사이트 전체에 다양한 운영 체제 또는 다양한 운영 체제 버전이 배포된 경우 Geo를 설정하기 전에 로케일 데이터 호환성 확인을 수행해야 합니다(**must**). GitLab 배포 방법의 혼합을 사용할 때 `glibc`도 확인해야 합니다. 로케일은 Linux package 설치, GitLab Docker 컨테이너, Helm 차트 배포 또는 외부 데이터베이스 서비스 간에 다를 수 있습니다. [PostgreSQL의 운영 체제 업그레이드 설명서](../../../postgresql/upgrading_os.md)를 참조하고 `glibc` 버전 호환성을 확인하는 방법을 포함합니다.

Geo는 PostgreSQL 및 스트리밍 복제를 사용하여 Geo 사이트 전체에서 데이터를 복제합니다. PostgreSQL은 텍스트 정렬을 위해 운영 체제의 C 라이브러리에서 제공하는 로케일 데이터를 사용합니다. Geo 사이트 전체에서 C 라이브러리의 로케일 데이터가 호환되지 않으면 [세컨더리 사이트의 잘못된 동작](https://gitlab.com/gitlab-org/gitlab/-/issues/360723)으로 이어지는 부정확한 쿼리 결과가 발생합니다.

예를 들어 Ubuntu 18.04 이전 버전과 RHEL/CentOS 7 이전 버전은 이후 버전과 호환되지 않습니다. [PostgreSQL wiki를 참조하여 자세한 내용](https://wiki.postgresql.org/wiki/Locale_data_changes)을(를) 확인하세요.

## 일반적인 오류 수정 {#fixing-common-errors}

이 섹션은 웹 인터페이스의 **운영자** 영역에서 보고된 일반적인 오류 메시지와 해결 방법을 설명합니다.

### 기존 추적 데이터베이스를 재사용할 수 없음 {#an-existing-tracking-database-cannot-be-reused}

Geo는 기존 추적 데이터베이스를 재사용할 수 없습니다.

새로운 세컨더리를 사용하거나 [Geo 세컨더리 사이트 복제 재설정](synchronization_verification.md#resetting-geo-secondary-site-replication)에 따라 전체 세컨더리를 재설정하는 것이 가장 안전합니다.

세컨더리를 재설정하지 않고 재사용하는 것은 위험합니다. 세컨더리 사이트가 일부 Geo 이벤트를 놓쳤을 수 있기 때문입니다. 예를 들어 놓친 삭제 이벤트로 인해 세컨더리 사이트가 영구적으로 삭제되어야 하는 데이터를 가지게 됩니다. 유사하게, 데이터 위치를 물리적으로 이동하는 이벤트를 잃으면 데이터가 한 위치에 영구적으로 고아 상태가 되고 다시 확인될 때까지 다른 위치에서 누락됩니다. 이것이 GitLab이 해시된 스토리지로 전환한 이유이며, 데이터 이동이 불필요합니다. 손실된 이벤트로 인한 다른 알려지지 않은 문제가 있을 수 있습니다.

이러한 종류의 위험이 적용되지 않는 경우(예: 테스트 환경) 또는 주 Postgres 데이터베이스가 Geo 사이트가 추가된 이후의 모든 Geo 이벤트를 여전히 포함한다는 것을 알고 있으면 이 상태 확인을 무시할 수 있습니다:

1. 마지막으로 처리된 이벤트 시간을 가져옵니다. **세컨더리** 사이트의 레일 콘솔에서:

   ```ruby
   Geo::EventLogState.last.created_at.utc
   ```

1. 출력을 복사합니다(예: `2024-02-21 23:50:50.676918 UTC`).
1. 세컨더리 사이트의 생성 시간을 업데이트하여 더 오래 보이게 합니다. **프라이머리** 사이트의 레일 콘솔에서:

   ```ruby
   GeoNode.secondary_nodes.last.update_column(:created_at, DateTime.parse('2024-02-21 23:50:50.676918 UTC') - 1.second)
   ```

   이 명령은 영향을 받는 세컨더리 사이트가 마지막으로 생성된 것임을 가정합니다.

1. **운영자** > **Geo** > **사이트**에서 세컨더리 사이트의 상태를 업데이트합니다. **세컨더리** 사이트의 레일 콘솔에서:

   ```ruby
   Geo::MetricsUpdateWorker.new.perform
   ```

1. 세컨더리 사이트가 정상으로 표시되어야 합니다. 그렇지 않으면 세컨더리 사이트에서 `gitlab-rake gitlab:geo:check`을(를) 실행하거나 세컨더리 사이트를 다시 추가한 이후 Rails를 다시 시작해 봅니다.
1. 누락되었거나 오래된 데이터를 재동기화하려면 **운영자** > **Geo** > **사이트**로 이동합니다.
1. 세컨더리 사이트에서 **복제 세부 정보**를 선택합니다.
1. 모든 데이터 유형에 대해 **전체 재인증**을(를) 선택합니다.

### Geo 사이트에 쓰기 가능한 데이터베이스가 있음 {#geo-site-has-a-database-that-is-writable}

이 오류 메시지는 **세컨더리** 사이트의 데이터베이스 복제본과 관련된 문제를 나타내며, Geo는 이에 대한 액세스 권한을 가져야 합니다. 쓰기 가능한 세컨더리 사이트 데이터베이스는 데이터베이스가 프라이머리 사이트와의 복제를 위해 구성되지 않았음을 나타냅니다. 일반적으로 다음 중 하나를 의미합니다:

- 지원되지 않는 복제 방법이 사용되었습니다(예: 논리적 복제).
- [Geo 데이터베이스 복제](../../setup/database.md) 설정 지침을 따르지 않았습니다.
- 데이터베이스 연결 세부 정보가 올바르지 않습니다. 즉, `/etc/gitlab/gitlab.rb` 파일에 잘못된 사용자를 지정했습니다.

Geo **세컨더리** 사이트에는 두 개의 별도 PostgreSQL 인스턴스가 필요합니다:

- **프라이머리** 사이트의 읽기 전용 복제본입니다.
- 복제 메타데이터를 저장하는 일반적인 쓰기 가능 인스턴스입니다. 즉, Geo 추적 데이터베이스입니다.

이 오류 메시지는 **세컨더리** 사이트의 복제 데이터베이스가 잘못 구성되었으며 복제가 중지되었음을 나타냅니다.

데이터베이스를 복원하고 복제를 재개하려면 다음 중 하나를 수행할 수 있습니다:

- [Geo 세컨더리 사이트 복제 재설정](synchronization_verification.md#resetting-geo-secondary-site-replication)합니다.
- [Linux package를 사용하여 새로운 Geo 세컨더리 설정](../../setup/_index.md#using-linux-package-installations)합니다.

처음부터 새로운 세컨더리를 설정하는 경우 [Geo 클러스터에서 이전 사이트 제거](../remove_geo_site.md)도 수행해야 합니다.

### Geo 사이트가 프라이머리 사이트에서 데이터베이스를 복제하는 것으로 나타나지 않음 {#geo-site-does-not-appear-to-be-replicating-the-database-from-the-primary-site}

데이터베이스가 올바르게 복제되지 않도록 하는 가장 일반적인 문제는 다음과 같습니다:

- **세컨더리** 사이트가 **프라이머리** 사이트에 도달할 수 없습니다. 자격 증명 및 [방화벽 규칙](../../_index.md#firewall-rules)을(를) 확인합니다.
- SSL 인증서 문제입니다. `/etc/gitlab/gitlab-secrets.json`을(를) **프라이머리** 사이트에서 복사했는지 확인합니다.
- 데이터베이스 스토리지 디스크가 가득 찼습니다.
- 데이터베이스 복제 슬롯이 잘못 구성되었습니다.
- 데이터베이스가 복제 슬롯을 사용하지 않거나 다른 대체 방법을 사용하지 않으며 WAL 파일이 제거되었기 때문에 따라잡을 수 없습니다.

[Geo 데이터베이스 복제](../../setup/database.md) 지침을 따라 지원되는 구성을 확인하세요.

### Geo 데이터베이스 버전(...)이 최신 마이그레이션(...)과(와) 일치하지 않음 {#geo-database-version--does-not-match-latest-migration-}

Linux package 설치를 사용 중이면 업그레이드 중에 오류가 발생했을 수 있습니다. 다음을 수행할 수 있습니다:

- `sudo gitlab-ctl reconfigure`을(를) 실행합니다.
- 다음을 실행하여 데이터베이스 마이그레이션을 수동으로 트리거합니다: `sudo gitlab-rake db:migrate:geo` (**세컨더리** 사이트에서 루트로)

### GitLab은 100% 이상의 리포지토리가 동기화되었음을 나타냄 {#gitlab-indicates-that-more-than-100-of-repositories-were-synced}

이는 프로젝트 레지스트리의 고아 레코드로 인해 발생할 수 있습니다. 레지스트리 worker를 사용하여 주기적으로 정리되고 있으므로 자체 수정될 시간을 주세요.

### 프라이머리 사이트에서 실패한 체크섬 {#failed-checksums-on-primary-site}

Geo Primary Verification 정보 화면에서 식별된 실패한 체크섬은 누락된 파일 또는 체크섬 불일치로 인해 발생할 수 있습니다. `"Repository cannot be checksummed because it does not exist"` 또는 `"File is not checksummable - file does not exist at: <path>"`와 같은 오류 메시지를 `gitlab-rails/geo.log` 파일에서 찾을 수 있습니다. 오류 메시지에는 누락된 파일을 식별하는 데 도움이 되는 파일 경로가 포함됩니다.

실패한 항목에 대한 추가 정보를 보려면 [무결성 확인 Rake 작업](../../../raketasks/check.md#uploaded-files-integrity)을(를) 실행합니다:

```ruby
sudo gitlab-rake gitlab:artifacts:check
sudo gitlab-rake gitlab:ci_secure_files:check
sudo gitlab-rake gitlab:lfs:check
sudo gitlab-rake gitlab:uploads:check
```

개별 오류에 대한 자세한 정보는 `VERBOSE=1` 변수를 사용합니다.

### 세컨더리 사이트는 UI에서 **양호하지 않음**을(를) 표시 {#secondary-site-shows-unhealthy-in-ui}

프라이머리 사이트에서 `external_url`의 값을 업데이트했거나 프로토콜을 `http`에서 `https`로 변경한 경우 세컨더리 사이트가 **양호하지 않음**으로 표시될 수 있습니다(`/etc/gitlab/gitlab.rb`). `geo.log`에서 다음 오류를 찾을 수도 있습니다:

```plaintext
"class": "Geo::NodeStatusRequestService",
...
"message": "Failed to Net::HTTP::Post to primary url: http://primary-site.gitlab.tld/api/v4/geo/status",
  "error": "Failed to open TCP connection to <PRIMARY_IP_ADDRESS>:80 (Connection refused - connect(2) for \"<PRIMARY_ID_ADDRESS>\" port 80)"
```

이 경우 모든 사이트에서 변경된 URL을 업데이트했는지 확인합니다:

1. 오른쪽 위 모서리에서 **운영자**를 선택하세요.
1. 왼쪽 사이드바에서 **Geo** > **사이트**를 선택하세요.
1. URL을 변경하고 변경 사항을 저장합니다.

### 메시지: `ERROR: canceling statement due to conflict with recovery` 백업 중 {#message-error-canceling-statement-due-to-conflict-with-recovery-during-backup}

Geo **세컨더리**에서 백업을 실행하는 것은 [지원되지 않습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/211668).

**세컨더리**에서 백업을 실행할 때 다음 오류 메시지가 나타날 수 있습니다:

```plaintext
Dumping PostgreSQL database gitlabhq_production ...
pg_dump: error: Dumping the contents of table "notes" failed: PQgetResult() failed.
pg_dump: error: Error message from server: ERROR:  canceling statement due to conflict with recovery
DETAIL:  User query might have needed to see row versions that must be removed.
pg_dump: error: The command was: COPY public.notes (id, note, [...], last_edited_at) TO stdout;
```

GitLab 업그레이드 중에 Geo **secondaries**에서 데이터베이스 백업이 자동으로 생성되는 것을 방지하려면 다음과 같은 빈 파일을 생성합니다:

```shell
sudo touch /etc/gitlab/skip-auto-backup
```

### 프라이머리에서 개체 검증 중 높은 CPU 사용량 {#high-cpu-usage-on-primary-during-object-verification}

GitLab 16.11에서 GitLab 17.2까지 누락된 PostgreSQL 인덱스로 인해 높은 CPU 사용량과 느린 아티팩트 검증 진행 상황이 발생합니다. 또한 Geo 세컨더리 사이트가 비정상으로 보고될 수 있습니다. [이슈 471727](https://gitlab.com/gitlab-org/gitlab/-/issues/471727)에서 자세한 동작을 설명합니다.

이 문제가 있을 수 있는지 확인하려면 [영향을 받는지 확인](https://gitlab.com/gitlab-org/gitlab/-/issues/471727#to-confirm-if-you-are-affected)하는 단계를 따릅니다.

영향을 받는 경우 [해결 방법](https://gitlab.com/gitlab-org/gitlab/-/issues/471727#workaround)의 단계에 따라 인덱스를 수동으로 생성합니다. 인덱스를 생성하면 PostgreSQL이 완료될 때까지 리소스를 약간 더 많이 소비합니다. 그 후 검증이 계속되는 동안 CPU 사용량이 높게 유지될 수 있지만 쿼리는 상당히 더 빠르게 완료되고 세컨더리 사이트 상태는 올바르게 업데이트됩니다.

### 검증 실패: `Verification timed out after (...)` {#verification-failed-with-verification-timed-out-after-}

GitLab 16.11부터 Geo는 동일한 `artifact_id`에 대해 중복 `JobArtifactRegistry` 항목을 생성할 수 있으며, 이는 프라이머리 및 세컨더리 사이트 간 동기화 실패로 이어질 수 있습니다. 이 문제는 `UploadRegistry` 및 `PackageFileRegistry` 항목에도 영향을 미칠 수 있습니다.

이 문제가 있을 수 있는지 확인하고 중복 항목을 제거하려면:

1. 세컨더리 사이트에서 [레일 콘솔](../../../operations/rails_console.md)을(를) 엽니다.
1. 중복이 있는 모델 레코드 ID의 수를 가져옵니다:

   ```ruby
   artifact_ids = Geo::JobArtifactRegistry.group(:artifact_id).having('COUNT(*) > 1').pluck(:artifact_id); artifact_ids.size
   upload_ids = Geo::UploadRegistry.group(:file_id).having('COUNT(*) > 1').pluck(:file_id); upload_ids.size
   package_file_ids = Geo::PackageFileRegistry.group(:package_file_id).having('COUNT(*) > 1').pluck(:package_file_id); package_file_ids.size
   ```

1. ID를 출력합니다:

   ```ruby
   puts 'BEGIN Artifact IDs', artifact_ids, 'END Artifact IDs'
   puts 'BEGIN Upload IDs', upload_ids, 'END Upload IDs'
   puts 'BEGIN Package File IDs', package_file_ids, 'END Package File IDs'
   ```

   출력이 비어 있으면 영향을 받지 않습니다. 그렇지 않으면 나중에 연결이 끊길 경우를 대비하여 터미널 출력을 텍스트 파일에 저장합니다.

1. 모든 중복 항목을 삭제합니다:

   ```ruby
   Geo::JobArtifactRegistry.where(artifact_id: artifact_ids).delete_all
   Geo::UploadRegistry.where(file_id: upload_ids).delete_all
   Geo::PackageFileRegistry.where(package_file_id: package_file_ids).delete_all
   ```

1. 배경 작업이 레지스트리 행을 다시 생성하고 재동기화할 때까지 기다립니다.

[이슈 479852](https://gitlab.com/gitlab-org/gitlab/-/issues/479852)를 따르면 수정에 대한 피드백을 얻을 수 있습니다.

### 오류 `end of file reached` (세컨더리에서 Geo Rake 확인 작업 실행 시) {#error-end-of-file-reached-when-running-geo-rake-check-task-on-secondary}

세컨더리 사이트에서 [상태 확인 Rake 작업](common.md#health-check-rake-task)을(를) 실행할 때 다음 오류가 나타날 수 있습니다:

```plaintext
Can connect to the primary node ... no
Reason:
end of file reached
```

프라이머리 사이트의 URL이 잘못되도록 지정된 경우 발생할 수 있습니다. 문제를 해결하려면 [레일 콘솔](../../../operations/rails_console.md)에서 다음 명령을 실행합니다:

```ruby
primary = Gitlab::Geo.primary_node
primary.internal_uri
Gitlab::HTTP.get(primary.internal_uri, allow_local_requests: true, limit: 10)
```

`internal_uri`의 값이 이전 출력에서 올바른지 확인합니다. 프라이머리 사이트의 URL이 올바르지 않으면 `/etc/gitlab/gitlab.rb`, **운영자** > **Geo** > **사이트**에서 다시 확인합니다.

### Geo 메트릭 수집으로 인한 과도한 데이터베이스 IO {#excessive-database-io-from-geo-metrics-collection}

Geo 메트릭 수집이 자주 발생하여 높은 데이터베이스 로드가 발생하는 경우 `geo_metrics_update_worker` 작업의 빈도를 줄일 수 있습니다. 이 조정은 메트릭 수집이 데이터베이스 성능에 크게 영향을 미치는 대규모 GitLab 인스턴스에서 데이터베이스 부하를 완화하는 데 도움이 될 수 있습니다.

간격을 늘리면 Geo 메트릭이 덜 자주 업데이트됩니다. 이로 인해 메트릭이 더 길게 오래되므로 실시간으로 Geo 복제를 모니터링하는 능력에 영향을 미칠 수 있습니다. 메트릭이 10분 이상 오래되면 사이트가 관리자 영역에서 "양호하지 않음"으로 임의로 표시됩니다.

다음 예제는 작업을 30분마다 실행하도록 설정합니다. 필요에 따라 cron 일정을 조정합니다.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`에 다음 설정을 추가하거나 수정합니다:

   ```ruby
   gitlab_rails['geo_metrics_update_worker_cron'] = "*/30 * * * *"
   ```

1. GitLab을 다시 구성하세요:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. `/home/git/gitlab/config/gitlab.yml`을(를) 편집합니다:

   ```yaml
   production: &base
     ee_cron_jobs:
       geo_metrics_update_worker:
         cron: "*/30 * * * *"
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

#### 사전 계산된 검증 요약 사용 {#use-pre-calculated-verification-summaries}

{{< history >}}

- GitLab 19.0에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/590853) , [플래그 사용](../../../../administration/feature_flags/_index.md) (`geo_job_artifact_verification_summaries` 명명됨) 기본적으로 비활성화됨.

{{< /history >}}

> [!flag]
> 이 기능의 가용성은 기능 플래그로 제어됩니다. 자세한 내용은 기록을 참조하세요. 이 기능은 테스트용으로 사용 가능하지만 프로덕션 사용을 위해 준비되지 않았습니다.

메트릭 수집 빈도를 줄이는 대신 CI 작업 아티팩트에 대해 사전 계산된 검증 요약을 활성화할 수 있습니다. 이는 전체 테이블 스캔을 증분 업데이트로 바꾸므로 변경된 데이터만 다시 계산됩니다.

활성화되면 배경 worker가 전용 테이블에서 요약 개수를 유지합니다. 데이터베이스 트리거는 검증 상태가 변경될 때 영향을 받는 버킷을 dirty로 표시하고 worker는 해당 버킷만 다시 계산합니다. 이는 대규모 인스턴스에서 메트릭 수집으로 인한 데이터베이스 로드를 몇 배 줄입니다.

활성화하려면:

```shell
sudo gitlab-rails runner 'Feature.enable(:geo_job_artifact_verification_summaries)'
```

비활성화하려면:

```shell
sudo gitlab-rails runner 'Feature.disable(:geo_job_artifact_verification_summaries)'
```
