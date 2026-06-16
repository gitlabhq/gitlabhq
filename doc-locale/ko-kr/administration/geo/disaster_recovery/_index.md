---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 재해 복구(Geo)
description: Geo 인스턴스를 사용하여 재해에서 복구합니다.
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

Geo는 데이터베이스, Git 리포지토리 및 기타 자산을 복제합니다. [알려진 문제](../_index.md#known-issues)가 있습니다.

> [!warning]
>
> - 다중 세컨더리 구성은 모든 프로모션되지 않은 세컨더리의 완전한 재동기화 및 재구성이 필요하며 다운타임을 야기합니다.
> - 세컨더리 사이트가 프로모션되면 프라이머리 사이트는 완전히 분리됩니다. 프라이머리 사이트를 복원하려면 새 세컨더리 사이트로 추가해야 합니다.

## 선택적 동기화가 활성화된 세컨더리 사이트 {#secondary-sites-with-selective-synchronization-enabled}

선택적 동기화가 활성화된 **세컨더리** 사이트를 프로모션하면 해당 세컨더리 사이트에 복제되지 않은 모든 데이터에 대해 **permanent data loss**이 발생합니다. 자세한 내용은 [선택적 동기화가 활성화된 세컨더리 사이트 프로모션](../replication/selective_synchronization.md#promoting-a-secondary-site-with-selective-synchronization-enabled)을 참조하세요.

## `gitlab-cluster.json` 파일 {#the-gitlab-clusterjson-file}

세컨더리 사이트를 `gitlab-ctl geo promote`로 프라이머리 사이트로 프로모션할 때 이 명령은 실행되는 각 노드에서 자동으로 `/etc/gitlab/gitlab-cluster.json` 파일을 생성합니다. 대부분의 경우 이 파일을 수동으로 편집할 필요가 없습니다.

`gitlab-cluster.json` 파일은 프로모션 명령이 `/etc/gitlab/gitlab.rb`를 직접 수정하지 않고도 구성 변경을 자동화할 수 있도록 합니다. `gitlab.rb`를 프로그래밍 방식으로 편집하는 것은 오류가 발생하기 쉬우므로 `gitlab-cluster.json`는 머신 관리식 오버라이드 계층 역할을 합니다.

두 파일이 모두 존재할 때 `gitlab-cluster.json`의 값이 `gitlab-ctl reconfigure`를 실행할 때 `gitlab.rb`의 해당 값보다 우선합니다. 이 명령을 실행하면 다음과 같은 경고가 표시됩니다:

```plaintext
The 'geo_primary_role' is defined in /etc/gitlab/gitlab-cluster.json as 'true' and overrides the setting in the /etc/gitlab/gitlab.rb
The 'geo_secondary_role' is defined in /etc/gitlab/gitlab-cluster.json as 'false' and overrides the setting in the /etc/gitlab/gitlab.rb
```

이 경고는 프로모션 후 예상된 것입니다.

### 파일 구조 {#file-structure}

일반적인 `gitlab-cluster.json` 파일은 다음과 같습니다:

```json
{
  "primary": true,
  "secondary": false,
  "geo_secondary": {
    "enable": false
  }
}
```

| 키 | 설명 |
|---|---|
| `primary` | `true`일 때 `geo_primary_role`를 활성화하며 이는 노드를 Geo 프라이머리로 구성합니다. |
| `secondary` | `true`일 때 `geo_secondary_role`를 활성화하며 이는 노드를 Geo 세컨더리로 구성합니다. |
| `geo_secondary` | 추적 데이터베이스와 같은 Geo 세컨더리 구성과 관련된 설정을 포함합니다. `"enable": false`는 세컨더리 특정 서비스를 비활성화합니다. |

`primary` 및 `secondary` 키는 각각 `geo_primary_role` 및 `geo_secondary_role`에 매핑됩니다. 이 역할은 단일 노드 설정의 편의를 위한 것이며 `gitlab.rb`에서 개별 서비스 역할이 명시적으로 구성된 다중 노드 구성에서는 사용하면 안 됩니다.

### 파일 제거 {#remove-the-file}

성공적인 프로모션 후 `gitlab-cluster.json`를 제자리에 유지할 수 있습니다. 그러나 다음 상황에서는 파일을 제거해야 합니다:

- [강등된 프라이머리를 복구](bring_primary_back.md#configure-the-former-primary-site-to-be-a-secondary-site)하여 새 세컨더리 사이트로 추가하는 경우 모든 Sidekiq, PostgreSQL, Gitaly 및 Rails 노드에서 `gitlab-cluster.json`를 삭제해야 합니다.
- `gitlab.rb`를 업데이트하여 Geo 역할을 설정(예: `roles(['geo_primary_role'])`) 한 후 `gitlab.rb`를 유일한 구성 소스로 만들려고 합니다.
- 부분 장애 조치에서 복구한 후입니다.

  파일이 복구 중에 수동으로 생성되는 시기에 대한 세부 정보는 [부분 장애 조치에서 복구](failover_troubleshooting.md#recovering-from-a-partial-failover)를 참조하세요.

파일을 제거하려면:

- 다음 명령을 실행합니다:

  ```shell
  sudo rm /etc/gitlab/gitlab-cluster.json
  sudo gitlab-ctl reconfigure
  ```

  다중 노드 설정에서는 사이트의 모든 노드에서 이 명령을 반복합니다.

`gitlab-cluster.json`이 재구성 프로세스와 상호 작용하는 방식에 대한 기술적 세부 정보는 [Omnibus 재구성 문서](https://docs.gitlab.com/omnibus/development/reconfigure_in_detail/#gitlab-clusterjson-file)를 참조하세요.

## 단일 세컨더리 구성에서 세컨더리 Geo 사이트 프로모션 {#promoting-a-secondary-geo-site-in-single-secondary-configurations}

Geo 복제본을 자동으로 프로모션하고 장애 조치를 수행할 수는 없지만 머신에 대한 `root` 액세스 권한이 있으면 수동으로 프로모션할 수 있습니다.

이 프로세스는 **세컨더리** Geo 사이트를 **프라이머리** 사이트로 프로모션합니다. 가능한 빨리 지리적 중복성을 복구하려면 이 지시사항을 따른 직후 새 **세컨더리** 사이트를 추가해야 합니다.

### 가능하면 복제 완료 허용 {#allow-replication-to-finish-if-possible}

**세컨더리** 사이트가 여전히 **프라이머리** 사이트에서 데이터를 복제하고 있는 경우 불필요한 데이터 손실을 피하기 위해 [계획된 장애 조치 문서](planned_failover.md)를 최대한 따르세요.

### 1단계. **프라이머리** 사이트를 영구적으로 비활성화 {#step-1-permanently-disable-the-primary-site}

> [!warning]
> **프라이머리** 사이트가 오프라인 상태가 되면 **프라이머리** 사이트에 저장된 데이터가 **세컨더리** 사이트로 복제되지 않았을 수 있습니다. 진행하면 이 데이터는 손실된 것으로 취급되어야 합니다.

**프라이머리** 사이트에서 장애가 발생한 경우 두 개의 다른 GitLab 인스턴스에서 쓰기가 발생할 수 있는 분할 상황을 피하기 위해 최선을 다해야 하며, 이는 복구 노력을 복잡하게 합니다. 따라서 장애 조치를 준비하려면 **프라이머리** 사이트를 비활성화해야 합니다.

- SSH 액세스 권한이 있으면:

  1. **프라이머리** 사이트로 SSH 연결하여 GitLab을 중지하고 비활성화합니다:

     ```shell
     sudo gitlab-ctl stop
     ```

  1. 서버가 예기치 않게 재부팅될 경우 GitLab이 다시 시작되지 않도록 방지합니다:

     ```shell
     sudo systemctl disable gitlab-runsvdir
     ```

- **프라이머리** 사이트에 대한 SSH 액세스 권한이 없으면 머신을 오프라인 상태로 전환하고 사용 가능한 모든 수단으로 재부팅되지 않도록 방지합니다. 다음이 필요할 수 있습니다:

  - 로드 밸런서를 다시 구성합니다.
  - DNS 레코드를 변경합니다(예: 프라이머리 DNS 레코드를 **세컨더리** 사이트로 지정하여 **프라이머리** 사이트의 사용을 중지).
  - 가상 서버를 중지합니다.
  - 방화벽을 통해 트래픽을 차단합니다.
  - **프라이머리** 사이트에서 객체 저장소 권한을 취소합니다.
  - 머신의 물리적 연결을 끊습니다.

  [프라이머리 도메인 DNS 레코드를 업데이트](#optional-updating-the-primary-domain-dns-record)할 계획인 경우 DNS 변경의 빠른 전파를 보장하기 위해 낮은 TTL을 유지할 수 있습니다.

  > [!note]
  > 프라이머리 사이트의 `/etc/gitlab/gitlab.rb` 파일은 이 프로세스 중에 세컨더리 사이트로 자동으로 복사되지 않습니다. 프라이머리의 `/etc/gitlab/gitlab.rb` 파일을 백업해야 하므로 나중에 세컨더리 사이트에서 필요한 값을 복원할 수 있습니다.

### 2단계. **세컨더리** 사이트 프로모션 {#step-2-promoting-a-secondary-site}

세컨더리를 프로모션할 때 다음을 참고합니다:

- 세컨더리 사이트가 [일시 중지된 경우](../replication/pause_resume_replication.md) 프로모션은 마지막으로 알려진 상태로 시점 복구를 수행합니다. 세컨더리가 일시 중지되는 동안 프라이머리에서 생성된 데이터는 손실됩니다.
- 세컨더리 사이트가 [일시 중지된 경우](../replication/pause_resume_replication.md) 이 프로세스 중에 `ActiveRecord::StatementInvalid: PG::ReadOnlySqlTransaction: ERROR:  cannot execute DELETE in a read-only transaction` 오류 메시지가 표시되면 다음 기술 자료 문서를 참조하세요:  [예기치 않은 프라이머리 종료 후 읽기 전용 트랜잭션 오류 또는 시간 초과로 인한 Geo 프로모션 실패](https://support.gitlab.com/hc/en-us/articles/21019042667804-Geo-promotion-fails-with-read-only-transaction-error-or-timeout-after-unexpected-primary-shutdown).
- 이때 새로운 **세컨더리**를 추가하지 않아야 합니다. 새로운 **세컨더리**를 추가하려면 **세컨더리**를 **프라이머리**로 프로모션하는 전체 프로세스를 완료한 후 수행하세요.
- 이 프로세스 중에 `ActiveRecord::RecordInvalid: Validation failed: Name has already been taken` 오류 메시지가 표시되면 자세한 내용은 이 [문제 해결 조언](failover_troubleshooting.md#fixing-errors-during-a-failover-or-when-promoting-a-secondary-to-a-primary-site)을 참조하세요.
- 별도 URL을 사용하는 경우 [새로 프로모션된 사이트로 프라이머리 도메인 DNS를 지정](#optional-updating-the-primary-domain-dns-record)해야 합니다. 그렇지 않으면 러너를 새로 프로모션된 사이트에 다시 등록해야 하며 모든 Git 리모트, 북마크 및 외부 통합을 업데이트해야 합니다.
- [위치 인식 DNS](../secondary_proxy/_index.md#configure-location-aware-dns)를 사용하는 경우 이전 프라이머리가 DNS 항목에서 제거된 후 러너가 자동으로 새 프라이머리에 연결되어야 합니다.
- 프라이머리 사이트가 다운되면 세컨더리에서 `gitlab-ctl promotion-preflight-checks`를 실행하여 Geo 동기화 상태를 확인하고 최종 검증 검사를 수행합니다.
- 이전 프라이머리에 연결된 러너가 다시 돌아올 것으로 예상하지 않으면 이를 제거해야 합니다:
  - UI를 통해:
    1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
    1. **CI/CD** > **러너**를 선택하고 이를 제거합니다.
  - [러너 API](../../../api/runners.md)를 사용합니다.

#### 단일 노드에서 실행 중인 **세컨더리** 사이트 프로모션 {#promoting-a-secondary-site-running-on-a-single-node}

1. **세컨더리** 사이트로 SSH 연결하고 다음을 실행합니다:

   - 세컨더리 사이트를 프라이머리로 승격하려면:

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - **without any further confirmation** 사이트를 프라이머리로 승격하되 추가 확인 없이:

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. 새로 승격된 **프라이머리** 사이트에 이전에 **세컨더리** 사이트에 사용된 URL을 사용하여 연결할 수 있는지 확인합니다.
1. 성공한 경우 **세컨더리** 사이트가 이제 **프라이머리** 사이트로 승격되었습니다.

`gitlab-ctl geo promote`를 실행하면 [`gitlab-cluster.json`](#the-gitlab-clusterjson-file) 파일이 노드에서 생성됩니다. 이 파일은 재구성할 때 `gitlab.rb`의 Geo 역할 설정을 재정의합니다.

### 3단계. 이전 세컨더리의 추적 데이터베이스 제거 {#step-3-removing-the-former-secondarys-tracking-database}

`geo_secondary[]` 구성 옵션이 `/etc/gitlab/gitlab.rb` 파일에 활성화되어 있으면 이를 주석 처리하거나 제거한 후 [GitLab 재구성](../../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행하여 변경 사항을 적용합니다.

이 시점에서 프로모션된 사이트는 새 프라이머리 GitLab 사이트입니다. 선택적으로 Geo를 새 세컨더리 사이트로 다시 설정하려면 [이전 사이트를 세컨더리로 복구](bring_primary_back.md#configure-the-former-primary-site-to-be-a-secondary-site)할 수 있습니다.

### 다중 노드를 가진 **세컨더리** 사이트 및 **single-secondary** 사이트 프로모션 {#promoting-a-secondary-site-with-multiple-nodes-and-a-single-secondary-site}

1. **세컨더리** 사이트의 모든 Sidekiq, PostgreSQL 및 Gitaly 노드에 SSH로 접속하여 다음 명령 중 하나를 실행합니다:

   - 세컨더리 사이트의 노드를 프라이머리로 프로모션하려면:

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - **without any further confirmation** 사이트를 프라이머리로 승격하되 추가 확인 없이:

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. **세컨더리** 사이트의 각 Rails 노드에 SSH로 접속하여 다음 명령 중 하나를 실행합니다:

   - 세컨더리 사이트를 프라이머리로 승격하려면:

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - **without any further confirmation** 사이트를 프라이머리로 승격하되 추가 확인 없이:

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. 새로 승격된 **프라이머리** 사이트에 이전에 **세컨더리** 사이트에 사용된 URL을 사용하여 연결할 수 있는지 확인합니다.
1. 성공한 경우 **세컨더리** 사이트가 이제 **프라이머리** 사이트로 승격되었습니다.

`gitlab-ctl geo promote`를 실행하면 [`gitlab-cluster.json`](#the-gitlab-clusterjson-file) 파일이 노드에서 생성됩니다. 이 파일은 재구성할 때 `gitlab.rb`의 Geo 역할 설정을 재정의합니다.

#### Patroni 대기 클러스터가 있는 **세컨더리** 사이트 프로모션 {#promoting-a-secondary-site-with-a-patroni-standby-cluster}

1. **세컨더리** 사이트의 모든 Sidekiq, PostgreSQL 및 Gitaly 노드에 SSH로 접속하여 다음 명령 중 하나를 실행합니다:

   - 세컨더리 사이트를 프라이머리로 승격하려면:

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - **without any further confirmation** 사이트를 프라이머리로 승격하되 추가 확인 없이:

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. **세컨더리** 사이트의 각 Rails 노드에 SSH로 접속하여 다음 명령 중 하나를 실행합니다:

   - 세컨더리 사이트를 프라이머리로 승격하려면:

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - **without any further confirmation** 사이트를 프라이머리로 승격하되 추가 확인 없이:

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. 새로 승격된 **프라이머리** 사이트에 이전에 **세컨더리** 사이트에 사용된 URL을 사용하여 연결할 수 있는지 확인합니다.
1. 성공한 경우 **세컨더리** 사이트가 이제 **프라이머리** 사이트로 승격되었습니다.

#### 외부 PostgreSQL 데이터베이스가 있는 **세컨더리** 사이트 프로모션 {#promoting-a-secondary-site-with-an-external-postgresql-database}

`gitlab-ctl geo promote` 명령은 외부 PostgreSQL 데이터베이스와 함께 사용할 수 있습니다. 이 경우 먼저 **세컨더리** 사이트와 관련된 복제본 데이터베이스를 수동으로 프로모션해야 합니다:

1. **세컨더리** 사이트와 관련된 복제본 데이터베이스를 프로모션합니다. 이는 데이터베이스를 읽기-쓰기로 설정합니다. 지침은 데이터베이스가 호스팅되는 위치에 따라 다릅니다:
   - [Amazon RDS](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ReadRepl.html#USER_ReadRepl.Promote)
   - [Azure PostgreSQL](https://learn.microsoft.com/en-us/azure/postgresql/single-server/how-to-read-replicas-portal#stop-replication)
   - [Google Cloud SQL](https://cloud.google.com/sql/docs/mysql/replication/manage-replicas#promote-replica)
   - 다른 외부 PostgreSQL 데이터베이스의 경우 다음 스크립트를 세컨더리 사이트(예: `/tmp/geo_promote.sh`)에 저장하고 연결 매개 변수를 환경과 일치하도록 수정합니다. 그런 다음 이를 실행하여 복제본을 프로모션합니다:

     ```shell
     #!/bin/bash

     PG_SUPERUSER=postgres

     # The path to your pg_ctl binary. You may need to adjust this path to match
     # your PostgreSQL installation
     PG_CTL_BINARY=/usr/lib/postgresql/16/bin/pg_ctl

     # The path to your PostgreSQL data directory. You may need to adjust this
     # path to match your PostgreSQL installation. You can also run
     # `SHOW data_directory;` from PostgreSQL to find your data directory
     PG_DATA_DIRECTORY=/etc/postgresql/16/main

     # Promote the PostgreSQL database and allow read/write operations
     sudo -u $PG_SUPERUSER $PG_CTL_BINARY -D $PG_DATA_DIRECTORY promote
     ```

1. **세컨더리** 사이트의 모든 Sidekiq, PostgreSQL 및 Gitaly 노드에 SSH로 접속하여 다음 명령 중 하나를 실행합니다:

   - 세컨더리 사이트를 프라이머리로 승격하려면:

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - **without any further confirmation** 사이트를 프라이머리로 승격하되 추가 확인 없이:

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. **세컨더리** 사이트의 각 Rails 노드에 SSH로 접속하여 다음 명령 중 하나를 실행합니다:

   - 세컨더리 사이트를 프라이머리로 승격하려면:

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - **without any further confirmation** 사이트를 프라이머리로 승격하되 추가 확인 없이:

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. 새로 승격된 **프라이머리** 사이트에 이전에 **세컨더리** 사이트에 사용된 URL을 사용하여 연결할 수 있는지 확인합니다.
1. 성공한 경우 **세컨더리** 사이트가 이제 **프라이머리** 사이트로 승격되었습니다.

### (선택적) 프라이머리 도메인 DNS 레코드 업데이트 {#optional-updating-the-primary-domain-dns-record}

프라이머리 도메인에 대한 DNS 레코드를 **세컨더리** 사이트로 지정하도록 업데이트합니다. 이렇게 하면 Git 리모트 및 API URL 변경과 같이 프라이머리 도메인에 대한 모든 참조를 업데이트할 필요가 없습니다.

1. **세컨더리** 사이트로 SSH 연결하고 루트로 로그인합니다:

   ```shell
   sudo -i
   ```

1. 프라이머리 도메인의 DNS 레코드를 업데이트합니다. 프라이머리 도메인의 DNS 레코드를 **세컨더리** 사이트로 지정하도록 업데이트한 후 **세컨더리** 사이트에서 `/etc/gitlab/gitlab.rb`를 편집하여 새 URL을 반영합니다:

   ```ruby
   # Change the existing external_url configuration
   external_url 'https://<new_external_url>'
   ```

   > [!note]
   > `external_url`를 변경해도 세컨더리 DNS 레코드가 여전히 유효한 한 이전 세컨더리 URL을 통한 액세스는 방지되지 않습니다.

1. **세컨더리** SSL 인증서를 업데이트합니다:

   - [Let's Encrypt 통합](https://docs.gitlab.com/omnibus/settings/ssl/#enable-the-lets-encrypt-integration)을 사용하는 경우 인증서가 자동으로 업데이트됩니다.
   - [수동으로 설정](https://docs.gitlab.com/omnibus/settings/ssl/#configure-https-manually)한 경우 **세컨더리** 인증서, 인증서를 **프라이머리**에서 **세컨더리**로 복사합니다. **프라이머리**에 액세스할 수 없으면 새 인증서를 발급하고 주체 대체 이름에 **프라이머리** 및 **세컨더리** URL이 모두 포함되도록 합니다. 다음을 사용하여 확인할 수 있습니다:

     ```shell
     /opt/gitlab/embedded/bin/openssl x509 -noout -dates -subject -issuer \
         -nameopt multiline -ext subjectAltName -in /etc/gitlab/ssl/new-gitlab.new-example.com.crt
     ```

1. **세컨더리** 사이트를 재구성하여 변경 사항을 적용합니다:

   ```shell
   gitlab-ctl reconfigure
   ```

1. 새로 프로모션된 **프라이머리** 사이트 URL을 업데이트하려면 아래 명령을 실행합니다:

   ```shell
   gitlab-rake gitlab:geo:update_primary_node_url
   ```

   이 명령은 `/etc/gitlab/gitlab.rb`에 정의된 변경된 `external_url` 구성을 사용합니다.

1. 새로 프로모션된 **프라이머리**를 URL을 사용하여 연결할 수 있는지 확인합니다. 프라이머리 도메인에 대한 DNS 레코드를 업데이트한 경우 이전 DNS 레코드 TTL에 따라 이러한 변경사항이 아직 전파되지 않았을 수 있습니다.

### (선택적) **세컨더리** Geo 사이트를 프로모션된 **프라이머리** 사이트에 추가 {#optional-add-secondary-geo-site-to-a-promoted-primary-site}

새 **세컨더리** 사이트를 온라인 상태로 전환하려면 [Geo 설정 지시사항](../setup/_index.md)을 따르세요.

## 다중 세컨더리 구성에서 세컨더리 Geo 복제본 프로모션 {#promoting-secondary-geo-replica-in-multi-secondary-configurations}

둘 이상의 **세컨더리** 사이트가 있고 그 중 하나를 프로모션해야 하는 경우 [단일 세컨더리 구성에서 **세컨더리** Geo 사이트 프로모션](#promoting-a-secondary-geo-site-in-single-secondary-configurations)을 따르고 그 후에도 두 가지 추가 단계가 필요합니다.

### 1단계. 새 **프라이머리** 사이트를 준비하여 하나 이상의 **세컨더리** 사이트를 제공 {#step-1-prepare-the-new-primary-site-to-serve-one-or-more-secondary-sites}

1. 새 **프라이머리** 사이트로 SSH 연결하고 루트로 로그인합니다:

   ```shell
   sudo -i
   ```

1. `/etc/gitlab/gitlab.rb`을 편집합니다:

   ```ruby
   ## Enable a Geo Primary role (if you haven't yet)
   roles ['geo_primary_role']

   ##
   # Allow PostgreSQL client authentication from the primary and secondary IPs. These IPs may be
   # public or VPC addresses in CIDR format, for example ['198.51.100.1/32', '198.51.100.2/32']
   ##
   postgresql['md5_auth_cidr_addresses'] = ['<primary_site_ip>/32', '<secondary_site_ip>/32']

   # Every secondary site needs to have its own slot so specify the number of secondary sites you're going to have
   # postgresql['max_replication_slots'] = 1 # Set this to be the number of Geo secondary nodes if you have more than one

   ##
   ## Disable automatic database migrations temporarily
   ## (until PostgreSQL is restarted and listening on the private address).
   ##
   gitlab_rails['auto_migrate'] = false
   ```

   (이 설정에 대한 자세한 내용은 [프라이머리 서버 구성](../setup/database.md#step-1-configure-the-primary-site)을 읽을 수 있습니다.)

1. 파일을 저장하고 데이터베이스 수신 대기 변경 및 복제 슬롯 변경이 적용되도록 GitLab을 재구성합니다:

   ```shell
   gitlab-ctl reconfigure
   ```

   PostgreSQL을 다시 시작하여 변경 사항을 적용합니다:

   ```shell
   gitlab-ctl restart postgresql
   ```

1. PostgreSQL이 다시 시작되고 개인 주소에서 수신 대기 중이므로 마이그레이션을 다시 활성화합니다.

   `/etc/gitlab/gitlab.rb`을 편집하고 구성을 `true`로 **변경**합니다:

   ```ruby
   gitlab_rails['auto_migrate'] = true
   ```

   파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   gitlab-ctl reconfigure
   ```

### 2단계. 복제 프로세스 시작 {#step-2-initiate-the-replication-process}

이제 각 **세컨더리** 사이트에서 새 **프라이머리** 사이트의 변경 사항을 수신 대기하도록 해야 합니다. 이를 위해 다시 [복제 프로세스를 시작](../setup/database.md#step-3-initiate-the-replication-process)해야 하지만 이번에는 다른 **프라이머리** 사이트의 경우입니다. 모든 이전 복제 설정이 덮어쓰기됩니다.

기존 세컨더리 사이트는 모두 채워진 데이터베이스를 가지므로 다음과 같은 메시지가 표시될 수 있습니다:

```shell
Found data inside the gitlabhq_production database! If you are sure you are in the secondary server, override with --force
```

적절한 세컨더리 사이트에 있음을 확인한 후 `--force`로 복제를 시작합니다.

> [!warning]
> `--force` 사용은 **all existing data in the database on that secondary server to be deleted**합니다.

## GitLab Helm 차트의 세컨더리 Geo 클러스터 프로모션 {#promoting-a-secondary-geo-cluster-in-the-gitlab-helm-chart}

클라우드 네이티브 Geo 배포를 업데이트할 때 세컨더리 Kubernetes 클러스터 외부의 모든 노드를 업데이트하는 프로세스는 클라우드 네이티브가 아닌 접근 방식과 다르지 않습니다. 따라서 항상 [단일 세컨더리 구성에서 세컨더리 Geo 사이트 프로모션](#promoting-a-secondary-geo-site-in-single-secondary-configurations)을 참조할 수 있습니다.

다음 섹션에서는 `gitlab` 네임스페이스를 사용하고 있다고 가정합니다. 클러스터를 설정할 때 다른 네임스페이스를 사용한 경우 `--namespace gitlab`를 네임스페이스로 바꿔야 합니다.

### 1단계. **프라이머리** 클러스터를 영구적으로 비활성화 {#step-1-permanently-disable-the-primary-cluster}

> [!warning]
> **프라이머리** 사이트가 오프라인 상태가 되면 **프라이머리** 사이트에 저장된 데이터가 **세컨더리** 사이트로 복제되지 않았을 수 있습니다. 진행하면 이 데이터는 손실된 것으로 취급되어야 합니다.

**프라이머리** 사이트에서 장애가 발생한 경우 두 개의 다른 GitLab 인스턴스에서 쓰기가 발생할 수 있는 분할 상황을 피하기 위해 최선을 다해야 하며, 이는 복구 노력을 복잡하게 합니다. 따라서 장애 조치를 준비하려면 **프라이머리** 사이트를 비활성화해야 합니다:

- **프라이머리** Kubernetes 클러스터에 액세스할 수 있으면 이에 연결하고 GitLab `webservice` 및 `Sidekiq` 포드를 비활성화합니다:

  ```shell
  kubectl --namespace gitlab scale deploy gitlab-geo-webservice-default --replicas=0
  kubectl --namespace gitlab scale deploy gitlab-geo-sidekiq-all-in-1-v1 --replicas=0
  ```

- **프라이머리** Kubernetes 클러스터에 액세스할 수 없으면 클러스터를 오프라인 상태로 전환하고 사용 가능한 모든 수단으로 다시 온라인 상태가 되지 않도록 방지합니다. 다음이 필요할 수 있습니다:

  - 로드 밸런서를 다시 구성합니다.
  - DNS 레코드를 변경합니다(예: 프라이머리 DNS 레코드를 **세컨더리** 사이트로 지정하여 **프라이머리** 사이트의 사용을 중지).
  - 가상 서버를 중지합니다.
  - 방화벽을 통해 트래픽을 차단합니다.
  - **프라이머리** 사이트에서 객체 저장소 권한을 취소합니다.
  - 머신의 물리적 연결을 끊습니다.

### 2단계. 클러스터 외부의 모든 **세컨더리** 사이트 노드 프로모션 {#step-2-promote-all-secondary-site-nodes-external-to-the-cluster}

> [!warning]
> 세컨더리 사이트가 [일시 중지된 경우](../_index.md#pausing-and-resuming-replication) 이는 마지막으로 알려진 상태로의 시점 복구를 수행합니다. 세컨더리가 일시 중지되는 동안 프라이머리에서 생성된 데이터는 손실됩니다.

1. **세컨더리** Kubernetes 클러스터 외부의 각 노드(예: PostgreSQL 또는 Gitaly)에 대해 Linux 패키지를 사용하여 노드로 SSH 연결하고 다음 명령 중 하나를 실행합니다:

   - **세컨더리** 사이트 노드를 Kubernetes 클러스터 외부에서 프라이머리로 프로모션하려면:

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - **세컨더리** 사이트 노드를 Kubernetes 클러스터 외부에서 프라이머리로 **without any further confirmation** 프로모션하려면:

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. `toolbox` 포드를 찾습니다:

   ```shell
   kubectl --namespace gitlab get pods -lapp=toolbox
   ```

1. 세컨더리를 프로모션합니다:

   ```shell
   kubectl --namespace gitlab exec -ti gitlab-geo-toolbox-XXX -- gitlab-rake gitlab:geo:set_secondary_as_primary
   ```

   작업의 동작을 수정하기 위해 환경 변수를 제공할 수 있습니다. 사용 가능한 변수는:

   | 이름 | 기본값 | 설명 |
   | ---- | ------------- | ------- |
   | `ENABLE_SILENT_MODE` | `false`  | `true`인 경우 프로모션 전에 [자동 모드](../../silent_mode/_index.md)를 활성화합니다(GitLab 16.4 이상). |

### 3단계. **세컨더리** 클러스터 프로모션 {#step-3-promote-the-secondary-cluster}

1. 기존 클러스터 구성을 업데이트합니다.

   Helm을 사용하여 기존 구성을 검색할 수 있습니다:

   ```shell
   helm --namespace gitlab get values gitlab-geo > gitlab.yaml
   ```

   기존 구성에는 Geo에 대한 섹션이 포함되어 있으며 다음과 같이 표시되어야 합니다:

   ```yaml
   geo:
      enabled: true
      role: secondary
      nodeName: secondary.example.com
      psql:
         host: geo-2.db.example.com
         port: 5431
         password:
            secret: geo
            key: geo-postgresql-password
   ```

   **세컨더리** 클러스터를 **프라이머리** 클러스터로 프로모션하려면 `role: secondary`을 `role: primary`로 업데이트합니다.

   클러스터가 프라이머리 사이트로 유지되는 경우 `geo` 아래의 전체 `psql` 섹션을 제거해야 합니다. 이는 추적 데이터베이스를 나타냅니다. 제자리에 남겨두면 애플리케이션이 부팅 시 노드를 세컨더리로 식별하여 새 세컨더리가 통합 URL로 추가될 때 인증을 중단시키는 경로 등록 문제를 일으킵니다.

   새 구성으로 클러스터를 업데이트합니다:

   ```shell
   helm upgrade --install --version <current Chart version> gitlab-geo gitlab/gitlab --namespace gitlab -f gitlab.yaml
   ```

1. 이전에 세컨더리에 사용된 URL을 사용하여 새로 프로모션된 프라이머리에 연결할 수 있는지 확인합니다.
1. 성공합니다! 세컨더리가 이제 프라이머리로 프로모션되었습니다.

### 4단계. (선택적) OpenBao HA 클러스터 프로모션 {#step-4-optional-promote-the-openbao-ha-cluster}

GitLab Secrets Manager가 활성화된 경우 Kubernetes 클러스터를 프로모션한 후 OpenBao 고가용성(HA) 클러스터를 프로모션하려면 다음 단계를 완료합니다.

#### OpenBao 포드 다시 시작 {#restart-openbao-pods}

PostgreSQL 복제본이 프라이머리로 프로모션된 후 OpenBao 포드를 다시 시작하여 이제 쓰기 가능한 데이터베이스에 다시 연결합니다:

```shell
kubectl --namespace gitlab rollout restart deployment -l app=openbao
```

#### (선택적) JWT 인증 구성 {#optional-configure-jwt-authentication}

프라이머리 도메인에 대한 DNS 레코드를 세컨더리 사이트로 지정하도록 업데이트한 경우 이 단계를 건너뜁니다.

JWT 인증을 재구성하려면 루트 토큰이 필요합니다. 복구 키를 사용하여 생성합니다. 자세한 내용은 [복구 키에서 루트 토큰 생성](../../secrets_manager/recovery_key.md#generate-a-root-token-from-the-recovery-key)을 참조하세요.

루트 토큰을 가진 후 JWT 인증 마운트를 다시 구성하여 세컨더리 도메인을 가리킵니다. 구성 세부 사항은 [Geo 구성](https://docs.gitlab.com/charts/charts/openbao/#geo-configuration)을 참조하세요.

#### 필요한 경우 밀봉 해제 비밀 복원 {#restore-the-unseal-secret-if-needed}

세컨더리 클러스터의 밀봉 해제 키는 프라이머리 키의 키와 동일해야 하며, 그렇지 않으면 OpenBao가 세컨더리에서 볼트를 밀봉 해제할 수 없습니다.

불일치가 있으면 `gitlab-openbao-unseal` 비밀을 [비밀 백업](https://docs.gitlab.com/charts/backup-restore/backup/#back-up-the-secrets)에서 세컨더리 클러스터로 복원한 후 OpenBao 포드를 다시 시작합니다:

```shell
kubectl --namespace gitlab rollout restart deployment -l app=openbao
```

#### OpenBao가 작동하는지 확인 {#verify-openbao-is-functional}

1. 모든 OpenBao 포드가 실행 중인지 확인합니다:

   ```shell
   kubectl --namespace gitlab get pods -l app=openbao
   ```

1. [Secrets Manager 변수](../../../ci/secrets/secrets_manager/_index.md)를 사용하는 CI 파이프라인을 실행하여 OpenBao 통합을 테스트합니다.

## 문제 해결 {#troubleshooting}

이 섹션이 [다른 위치](failover_troubleshooting.md#fixing-errors-during-a-failover-or-when-promoting-a-secondary-to-a-primary-site)로 이동되었습니다.
