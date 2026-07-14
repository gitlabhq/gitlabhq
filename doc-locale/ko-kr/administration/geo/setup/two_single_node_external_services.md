---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 외부 PostgreSQL 서비스를 사용하여 두 개의 단일 노드 사이트에 Geo 설정
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

다음 가이드는 두 개의 Linux 패키지 인스턴스와 RDS, Azure Database 또는 Google Cloud SQL과 같은 외부 PostgreSQL 데이터베이스를 사용하여 두 개의 단일 노드 사이트 설치를 위해 GitLab Geo를 배포하는 방법에 대한 간결한 지침을 제공합니다.

전제 조건:

- 독립적으로 작동하는 GitLab 사이트가 최소 2개 이상 있어야 합니다. 사이트를 만들려면 [GitLab 참조 아키텍처 설명서](../../reference_architectures/_index.md)를 참조하세요.
  - 하나의 GitLab 사이트는 **Geo primary site** 역할을 합니다. 각 Geo 사이트마다 다른 참조 아키텍처 크기를 사용할 수 있습니다. 이미 작동하는 GitLab 인스턴스가 있는 경우 주 사이트로 사용할 수 있습니다.
  - 두 번째 GitLab 사이트는 **Geo secondary site** 역할을 합니다. Geo는 여러 보조 사이트를 지원합니다.
- Geo 주 사이트에는 최소한 [GitLab Premium](https://about.gitlab.com/pricing/) 라이선스가 있어야 합니다. 모든 사이트에 대해 라이선스 1개만 필요합니다.
- 모든 사이트가 [Geo 실행 요구 사항](../_index.md#requirements-for-running-geo)을 충족하는지 확인하세요.

## Linux 패키지(Omnibus)에 대해 Geo 설정 {#set-up-geo-for-linux-package-omnibus}

전제 조건:

- PostgreSQL 12 이상을 사용합니다. 여기에는 [`pg_basebackup` 도구](https://www.postgresql.org/docs/16/app-pgbasebackup.html)가 포함됩니다.

### 주 사이트 구성 {#configure-the-primary-site}

1. GitLab 주 사이트에 SSH로 연결하고 root로 로그인합니다:

   ```shell
   sudo -i
   ```

1. `/etc/gitlab/gitlab.rb`에 고유한 Geo 사이트 이름을 추가합니다:

   ```ruby
   ##
   ## The unique identifier for the Geo site. See
   ## https://docs.gitlab.com/administration/geo_sites/#common-settings
   ##
   gitlab_rails['geo_node_name'] = '<site_name_here>'
   ```

1. 변경사항을 적용하려면 주 사이트를 다시 구성합니다:

   ```shell
   gitlab-ctl reconfigure
   ```

1. 사이트를 주 Geo 사이트로 정의합니다:

   ```shell
   gitlab-ctl set-geo-primary-node
   ```

   이 명령은 `/etc/gitlab/gitlab.rb`에 정의된 `external_url`을 사용합니다.

구성 예제는 [외부 PostgreSQL을 사용하는 완전한 기본 사이트](#complete-primary-site-with-external-postgresql)를 참조하세요.

### 복제할 외부 데이터베이스 구성 {#configure-the-external-database-to-be-replicated}

외부 데이터베이스를 설정하려면 다음 중 하나를 수행할 수 있습니다:

- [스트리밍 복제](https://www.postgresql.org/docs/16/warm-standby.html#STREAMING-REPLICATION-SLOTS)를 직접 설정하세요(예: Amazon RDS 또는 Linux 패키지에서 관리하지 않는 베어 메탈).
- Linux 패키지 설치의 구성을 다음과 같이 수동으로 수행합니다.

#### 클라우드 제공자의 도구를 활용하여 기본 데이터베이스 복제 {#leverage-your-cloud-providers-tools-to-replicate-the-primary-database}

AWS EC2에서 설정된 기본 사이트가 RDS를 사용한다고 가정합니다. 이제 다른 리전에서 읽기 전용 복제본을 생성할 수 있으며 복제 프로세스는 AWS에서 관리합니다. 세컨더리 Rails 노드가 데이터베이스에 액세스할 수 있도록 필요에 따라 네트워크 ACL(액세스 제어 목록), 서브넷 및 보안 그룹을 설정했는지 확인합니다.

다음 지침은 일반적인 클라우드 제공자를 위해 읽기 전용 복제본을 생성하는 방법을 자세히 설명합니다:

- Amazon RDS - [읽기 복제본 생성](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ReadRepl.html#USER_ReadRepl.Create)
- Azure Database for PostgreSQL - [Azure Database for PostgreSQL에서 읽기 복제본 생성 및 관리](https://learn.microsoft.com/en-us/azure/postgresql/single-server/how-to-read-replicas-portal)
- Google Cloud SQL - [읽기 복제본 생성](https://cloud.google.com/sql/docs/postgres/replication/create-replica)

읽기 전용 복제본이 설정되면 [세컨더리 사이트 구성](#configure-the-secondary-site-to-use-the-external-read-replica)으로 건너뛸 수 있습니다.

### 외부 읽기 복제본을 사용하도록 세컨더리 사이트 구성 {#configure-the-secondary-site-to-use-the-external-read-replica}

Linux 패키지 설치의 경우 [`geo_secondary_role`](https://docs.gitlab.com/omnibus/roles/#gitlab-geo-roles)에는 세 가지 주요 기능이 있습니다:

1. 복제본 데이터베이스를 구성합니다.
1. 추적 데이터베이스를 구성합니다.
1. [Geo Log Cursor](../_index.md#geo-log-cursor)를 활성화합니다.

외부 읽기 복제본 데이터베이스에 대한 연결을 구성하려면:

1. **세컨더리** 사이트의 **Rails, Sidekiq and Geo Log Cursor** 노드 각각으로 SSH 연결하고 root로 로그인합니다:

   ```shell
   sudo -i
   ```

1. `/etc/gitlab/gitlab.rb`을 편집하고 다음을 추가합니다

   ```ruby
   ##
   ## Geo Secondary role
   ## - configure dependent flags automatically to enable Geo
   ##
   roles ['geo_secondary_role']

   # note this is shared between both databases,
   # make sure you define the same password in both
   gitlab_rails['db_password'] = '<your_db_password_here>'

   gitlab_rails['db_username'] = 'gitlab'
   gitlab_rails['db_host'] = '<database_read_replica_host>'

   # Disable the bundled Omnibus PostgreSQL because we are
   # using an external PostgreSQL
   postgresql['enable'] = false
   ```

1. [외부 PostgreSQL을 사용하는 완전한 세컨더리 사이트](#complete-secondary-site-with-external-postgresql)에서 구성 예제를 복사합니다. 변경사항을 적용하려면 파일을 저장하고 GitLab을 다시 구성합니다:

   ```shell
   gitlab-ctl reconfigure
   ```

복제본 데이터베이스에 대한 연결 문제가 있으면 [TCP 연결 확인](../../raketasks/maintenance.md)을 사용하여 서버에서 다음 명령을 실행하세요:

```shell
gitlab-rake gitlab:tcp_check[<replica FQDN>,5432]
```

이 단계가 실패하면 잘못된 IP 주소를 사용하거나 방화벽이 사이트에 대한 액세스를 차단할 수 있습니다. 공용 주소와 개인 주소의 차이점에 주의하여 IP 주소를 확인합니다. 방화벽이 있는 경우 보조 사이트가 5432 포트에서 주 사이트에 연결하도록 허용되는지 확인합니다.

#### GitLab 비밀 값 수동 복제 {#manually-replicate-secret-gitlab-values}

GitLab은 `/etc/gitlab/gitlab-secrets.json`에 여러 비밀 값을 저장합니다. 이 JSON 파일은 각 사이트 노드에서 동일해야 합니다. [문제 3789](https://gitlab.com/gitlab-org/gitlab/-/issues/3789)에서 이 동작을 변경할 것을 제안하지만 모든 보조 사이트에서 비밀 파일을 수동으로 복제해야 합니다.

1. 주 사이트의 Rails 노드에 SSH로 연결하고 아래 명령을 실행합니다:

   ```shell
   sudo cat /etc/gitlab/gitlab-secrets.json
   ```

   이는 JSON 형식으로 복제해야 하는 비밀을 표시합니다.

1. 보조 Geo 사이트의 각 노드에 SSH로 연결하고 root로 로그인합니다:

   ```shell
   sudo -i
   ```

1. 기존 비밀을 백업합니다:

   ```shell
   mv /etc/gitlab/gitlab-secrets.json /etc/gitlab/gitlab-secrets.json.`date +%F`
   ```

1. 주 사이트 Rails 노드에서 `/etc/gitlab/gitlab-secrets.json`을 각 보조 사이트 노드로 복사합니다. 노드 간에 파일 내용을 복사-붙여넣기할 수도 있습니다:

   ```shell
   sudo editor /etc/gitlab/gitlab-secrets.json

   # paste the output of the `cat` command you ran on the primary
   # save and exit
   ```

1. 파일 권한이 올바른지 확인합니다:

   ```shell
   chown root:root /etc/gitlab/gitlab-secrets.json
   chmod 0600 /etc/gitlab/gitlab-secrets.json
   ```

1. 변경 사항을 적용하려면 모든 Rails, Sidekiq 및 Gitaly 세컨더리 사이트 노드를 재구성합니다:

   ```shell
   gitlab-ctl reconfigure
   gitlab-ctl restart
   ```

#### 주 사이트 SSH 호스트 키 수동 복제 {#manually-replicate-the-primary-site-ssh-host-keys}

1. 보조 사이트의 각 노드에 SSH로 연결하고 root로 로그인합니다:

   ```shell
   sudo -i
   ```

1. 기존 SSH 호스트 키를 백업합니다:

   ```shell
   find /etc/ssh -iname 'ssh_host_*' -exec cp {} {}.backup.`date +%F` \;
   ```

1. 주 사이트에서 OpenSSH 호스트 키를 복사합니다.

   - 주 사이트 노드 중 SSH 트래픽을 제공하는 하나(일반적으로 주 GitLab Rails 애플리케이션 노드)에 root로 액세스할 수 있는 경우:

     ```shell
     # Run this from the secondary site, change `<primary_site_fqdn>` for the IP or FQDN of the server
     scp root@<primary_node_fqdn>:/etc/ssh/ssh_host_*_key* /etc/ssh
     ```

   - `sudo` 권한이 있는 사용자를 통해서만 액세스할 수 있는 경우:

     ```shell
     # Run this from the node on your primary site:
     sudo tar --transform 's/.*\///g' -zcvf ~/geo-host-key.tar.gz /etc/ssh/ssh_host_*_key*

     # Run this on each node on your secondary site:
     scp <user_with_sudo>@<primary_site_fqdn>:geo-host-key.tar.gz .
     tar zxvf ~/geo-host-key.tar.gz -C /etc/ssh
     ```

1. 각 보조 사이트 노드에서 파일 권한이 올바른지 확인합니다:

   ```shell
   chown root:root /etc/ssh/ssh_host_*_key*
   chmod 0600 /etc/ssh/ssh_host_*_key
   ```

1. 키 지문이 일치하는지 확인하려면 각 사이트의 주 및 보조 노드에서 다음 명령을 실행합니다:

   ```shell
   for file in /etc/ssh/ssh_host_*_key; do ssh-keygen -lf $file; done
   ```

   다음과 유사한 출력을 받아야 합니다:

   ```shell
   1024 SHA256:FEZX2jQa2bcsd/fn/uxBzxhKdx4Imc4raXrHwsbtP0M root@serverhostname (DSA)
   256 SHA256:uw98R35Uf+fYEQ/UnJD9Br4NXUFPv7JAUln5uHlgSeY root@serverhostname (ECDSA)
   256 SHA256:sqOUWcraZQKd89y/QQv/iynPTOGQxcOTIXU/LsoPmnM root@serverhostname (ED25519)
   2048 SHA256:qwa+rgir2Oy86QI+PZi/QVR+MSmrdrpsuH7YyKknC+s root@serverhostname (RSA)
   ```

   두 노드의 출력은 동일해야 합니다.

1. 기존 개인 키에 대해 올바른 공개 키가 있는지 확인합니다:

   ```shell
   # This will print the fingerprint for private keys:
   for file in /etc/ssh/ssh_host_*_key; do ssh-keygen -lf $file; done

   # This will print the fingerprint for public keys:
   for file in /etc/ssh/ssh_host_*_key.pub; do ssh-keygen -lf $file; done
   ```

   공개 및 개인 키 명령의 출력이 동일한 지문을 생성해야 합니다.

1. 각 보조 사이트 노드에서 `sshd`을 다시 시작합니다:

   ```shell
   # Debian or Ubuntu installations
   sudo service ssh reload

   # CentOS installations
   sudo service sshd reload
   ```

1. SSH가 여전히 작동하는지 확인하려면 새 터미널에서 GitLab 보조 서버에 SSH로 연결합니다. 연결할 수 없으면 올바른 권한이 있는지 확인하세요.

#### 권한 있는 SSH 키의 빠른 조회 {#fast-lookup-of-authorized-ssh-keys}

초기 복제 프로세스가 완료되면 [인증된 SSH 키의 빠른 조회 구성](../../operations/fast_ssh_key_lookup.md) 단계를 따릅니다.

빠른 조회는 [Geo에 필수입니다](../../operations/fast_ssh_key_lookup.md#fast-lookup-is-required-for-geo).

> [!note]
> 인증은 주 사이트에서 처리됩니다. 보조 사이트에 대해 사용자 지정 인증을 설정하지 마세요. **운영자** 영역에 액세스해야 하는 모든 변경사항은 보조 사이트가 읽기 전용 복사본이므로 주 사이트에서 수행해야 합니다.

#### 보조 사이트 추가 {#add-the-secondary-site}

1. 보조 사이트의 각 Rails 및 Sidekiq 노드에 SSH로 연결하고 root로 로그인합니다:

   ```shell
   sudo -i
   ```

1. `/etc/gitlab/gitlab.rb`을 편집하고 사이트에 대한 고유한 이름을 추가합니다.

   ```ruby
   ##
   ## The unique identifier for the Geo site. See
   ## https://docs.gitlab.com/administration/geo_sites/#common-settings
   ##
   gitlab_rails['geo_node_name'] = '<secondary_site_name_here>'
   ```

   다음 단계를 위해 고유한 이름을 저장합니다.

1. 변경사항을 적용하려면 보조 사이트의 각 Rails 및 Sidekiq 노드를 다시 구성합니다.

   ```shell
   gitlab-ctl reconfigure
   ```

1. 주 노드 GitLab 인스턴스로 이동합니다:
   1. 오른쪽 위 모서리에서 **운영자**를 선택하세요.
   1. **Geo** > **사이트**를 선택합니다.
   1. **사이트 추가**를 선택합니다.

      ![새 세컨더리 Geo 사이트를 추가하기 위한 양식](img/adding_a_secondary_v15_8.png)

   1. **이름**에 `/etc/gitlab/gitlab.rb`의 `gitlab_rails['geo_node_name']` 값을 입력합니다. 값이 정확히 일치해야 합니다.
   1. **외부 URL**에 `/etc/gitlab/gitlab.rb`의 `external_url` 값을 입력합니다. 한 값이 `/`로 끝나고 다른 값이 끝나지 않으면 괜찮습니다. 그렇지 않으면 값이 정확히 일치해야 합니다.
   1. 선택사항. **내부 URL (옵션)**에 주 사이트의 내부 URL을 입력합니다.
   1. 선택사항. 보조 사이트에서 복제해야 할 그룹 또는 스토리지 분할을 선택합니다. 모두를 복제하려면 필드를 비워 둡니다. [선택적 동기화](../replication/selective_synchronization.md)를 참조하세요.
   1. **변경 사항 저장**을 선택합니다.
1. 보조 사이트의 각 Rails 및 Sidekiq 노드에 SSH로 연결하고 서비스를 다시 시작합니다:

   ```shell
   sudo gitlab-ctl restart
   ```

1. Geo 설정에 공통적인 문제가 있는지 확인하려면 다음을 실행합니다:

   ```shell
   sudo gitlab-rake gitlab:geo:check
   ```

   검사 중 일부가 실패하면 [문제 해결 설명서](../replication/troubleshooting/_index.md)를 참조하세요.

1. 세컨더리 사이트에 연결할 수 있는지 확인하려면 기본 사이트의 Rails 또는 Sidekiq 서버로 SSH 연결하고 다음을 실행합니다:

   ```shell
   sudo gitlab-rake gitlab:geo:check
   ```

   검사 중 일부가 실패하면 [문제 해결 설명서](../replication/troubleshooting/_index.md)를 확인하세요.

보조 사이트가 Geo 관리 페이지에 추가되고 다시 시작된 후 사이트는 자동으로 백필이라고 하는 프로세스에서 주 사이트로부터 누락된 데이터의 복제를 시작합니다.

한편, 주 사이트는 각 보조 사이트에 변경사항을 알리기 시작하므로 보조 사이트는 알림에 즉시 대응할 수 있습니다.

보조 사이트가 실행 중이고 액세스 가능한지 확인하세요. 주 사이트에 사용한 동일한 자격 증명으로 보조 사이트에 로그인할 수 있습니다.

#### HTTP/HTTPS 및 SSH를 통한 Git 액세스 활성화 {#enable-git-access-over-httphttps-and-ssh}

Geo는 HTTP/HTTPS를 통해 리포지토리를 동기화하며(새 설치의 경우 기본적으로 활성화됨) 따라서 이 클론 메서드를 활성화해야 합니다. 기존 사이트를 Geo로 변환하는 경우 복제 방법이 활성화되어 있는지 확인해야 합니다.

주 사이트에서:

1. 오른쪽 위 모서리에서 **운영자**를 선택하세요.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **공개 범위 및 액세스 설정**을 확장합니다.
1. SSH를 통해 Git을 사용하는 경우:
   1. **활성화된 Git 액세스 프로토콜**이 **SSH 및 HTTP(S) 모두**로 설정되어 있는지 확인합니다.
   1. 기본 사이트와 세컨더리 사이트 모두에서 [데이터베이스의 인증된 SSH 키의 빠른 조회](../../operations/fast_ssh_key_lookup.md)를 활성화합니다.
1. SSH를 통해 Git을 사용하지 않는 경우 **활성화된 Git 액세스 프로토콜**을 **HTTP(S)만**으로 설정합니다.

#### 보조 사이트의 적절한 기능 확인 {#verify-proper-functioning-of-the-secondary-site}

주 사이트에 사용한 동일한 자격 증명으로 보조 사이트에 로그인할 수 있습니다.

로그인한 후:

1. 오른쪽 위 모서리에서 **운영자**를 선택하세요.
1. 왼쪽 사이드바에서 **Geo** > **사이트**를 선택하세요.
1. 사이트가 보조 Geo 사이트로 올바르게 식별되고 Geo가 활성화되어 있는지 확인합니다.

초기 복제에는 시간이 걸릴 수 있습니다. 주 사이트에서 **Geo 사이트** 대시보드를 통해 각 Geo 사이트의 동기화 프로세스를 모니터링할 수 있습니다.

![세컨더리 사이트의 동기화 상태를 보여주는 Geo 관리자 대시보드.](img/geo_dashboard_v14_0.png)

## 추적 데이터베이스 구성 {#configure-the-tracking-database}

> [!note]
> 이 단계는 추적 데이터베이스를 다른 서버에서 외부적으로 설정하려는 경우 선택사항입니다.

**세컨더리** 사이트는 복제 상태를 추적하고 잠재적인 복제 문제에서 자동으로 복구하기 위해 추적 데이터베이스로 별도의 PostgreSQL 설치를 사용합니다. Linux 패키지는 `roles ['geo_secondary_role']`가 설정될 때 자동으로 추적 데이터베이스를 구성합니다. 이 데이터베이스를 Linux 패키지 설치 외부에서 실행하려는 경우 다음 지침을 사용합니다.

### 클라우드 관리 데이터베이스 서비스 {#cloud-managed-database-services}

추적 데이터베이스에 클라우드 관리 서비스를 사용하는 경우 추적 데이터베이스 사용자(기본적으로 `gitlab_geo`)에게 추가 역할을 부여해야 할 수 있습니다:

- Amazon RDS에는 [`rds_superuser`](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.html#Appendix.PostgreSQL.CommonDBATasks.Roles) 역할이 필요합니다.
- Azure Database for PostgreSQL에는 [`azure_pg_admin`](https://learn.microsoft.com/en-us/azure/postgresql/single-server/how-to-create-users#how-to-create-additional-admin-users-in-azure-database-for-postgresql) 역할이 필요합니다.
- Google Cloud SQL에는 [`cloudsqlsuperuser`](https://cloud.google.com/sql/docs/postgres/users#default-users) 역할이 필요합니다.

설치 및 업그레이드 중 확장 설치를 위해 추가 역할이 필요합니다. 대신 [필수 확장 프로그램을 수동으로 설치](../../postgresql/extensions.md)하세요.

> [!note]
> Amazon RDS를 추적 데이터베이스로 사용하려면 세컨더리 데이터베이스에 액세스할 수 있는지 확인하세요. 불행히도 동일한 보안 그룹을 할당하는 것만으로는 충분하지 않습니다. 왜냐하면 아웃바운드 규칙이 RDS PostgreSQL 데이터베이스에 적용되지 않기 때문입니다. 따라서 읽기 복제본의 보안 그룹에 추적 데이터베이스에서 포트 5432의 TCP 트래픽을 허용하는 인바운드 규칙을 명시적으로 추가해야 합니다.

### 추적 데이터베이스 생성 {#create-the-tracking-database}

PostgreSQL 인스턴스에서 추적 데이터베이스를 생성하고 구성합니다:

1. [데이터베이스 요구 사항 문서](../../../install/requirements.md#postgresql)에 따라 PostgreSQL을 설정합니다.
1. `gitlab_geo` 사용자를 설정하고 선택한 비밀번호를 사용하여 `gitlabhq_geo_production` 데이터베이스를 생성하고 사용자를 데이터베이스 소유자로 만듭니다. [자체 컴파일된 설치 설명서](../../../install/self_compiled/_index.md#7-database)에서 이 설정의 예를 볼 수 있습니다.
1. **not** 클라우드 관리 PostgreSQL 데이터베이스를 사용하는 경우 세컨더리 사이트가 `pg_hba.conf`(추적 데이터베이스와 연관됨)를 수동으로 변경하여 추적 데이터베이스와 통신할 수 있도록 합니다. 변경 사항을 적용하려면 이후에 PostgreSQL을 다시 시작합니다:

   ```plaintext
   ##
   ## Geo Tracking Database Role
   ## - pg_hba.conf
   ##
   host    all         all               <trusted tracking IP>/32      md5
   host    all         all               <trusted secondary IP>/32     md5
   ```

### GitLab 구성 {#configure-gitlab}

이 데이터베이스를 사용하도록 GitLab을 구성합니다. 이 단계는 Linux 패키지 및 Docker 배포용입니다.

1. GitLab **세컨더리** 서버로 SSH 연결하고 root로 로그인합니다:

   ```shell
   sudo -i
   ```

1. `/etc/gitlab/gitlab.rb`을 편집하여 PostgreSQL 인스턴스가 있는 머신의 연결 매개 변수와 자격 증명으로 작성합니다:

   ```ruby
   geo_secondary['db_username'] = 'gitlab_geo'
   geo_secondary['db_password'] = '<your_tracking_db_password_here>'

   geo_secondary['db_host'] = '<tracking_database_host>'
   geo_secondary['db_port'] = <tracking_database_port>      # change to the correct port
   geo_postgresql['enable'] = false     # don't use internal managed instance
   ```

1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   gitlab-ctl reconfigure
   ```

#### 데이터베이스 스키마 수동으로 설정(선택사항) {#manually-set-up-the-database-schema-optional}

[이전에 나열된 단계](#configure-gitlab)의 재구성 명령이 이러한 단계를 자동으로 처리합니다. 이러한 단계는 문제가 발생한 경우를 대비하여 제공됩니다.

1. 이 작업은 데이터베이스 스키마를 생성합니다. 데이터베이스 사용자가 슈퍼유저여야 합니다.

   ```shell
   sudo gitlab-rake db:create:geo
   ```

1. Rails 데이터베이스 마이그레이션(스키마 및 데이터 업데이트)도 재구성에 의해 수행됩니다. `geo_secondary['auto_migrate'] = false`이 설정되었거나 스키마가 수동으로 생성된 경우 이 단계가 필요합니다:

   ```shell
   sudo gitlab-rake db:migrate:geo
   ```

## 예제 구성 {#example-configurations}

### 외부 PostgreSQL을 사용하는 완전한 기본 사이트 {#complete-primary-site-with-external-postgresql}

<!-- If you update this configuration example, also update the example in two_single_node_sites.md -->

이 완전한 `gitlab.rb` 구성 예제는 외부 PostgreSQL을 사용하는 Geo 기본 사이트에 대한 것입니다:

```ruby
# Primary site with external PostgreSQL configuration example

## Geo Primary role
roles(['geo_primary_role'])

## The unique identifier for the Geo site
gitlab_rails['geo_node_name'] = 'headquarters'

## External URL
external_url 'https://gitlab.example.com'

## External PostgreSQL configuration
postgresql['enable'] = false
gitlab_rails['db_adapter'] = 'postgresql'
gitlab_rails['db_encoding'] = 'unicode'
gitlab_rails['db_host'] = 'primary-postgres.example.com'
gitlab_rails['db_port'] = 5432
gitlab_rails['db_database'] = 'gitlabhq_production'
gitlab_rails['db_username'] = 'gitlab'
gitlab_rails['db_password'] = 'your_database_password_here'

## SSL/TLS configuration
nginx['listen_port'] = 80
nginx['listen_https'] = false
letsencrypt['enable'] = false

## Object Storage configuration (recommended for external services)
gitlab_rails['object_store']['enabled'] = true
gitlab_rails['object_store']['connection'] = {
  'provider' => 'AWS',
  'region' => 'us-east-1',
  'aws_access_key_id' => 'your_access_key',
  'aws_secret_access_key' => 'your_secret_key'
}

## Monitoring configuration
node_exporter['listen_address'] = '0.0.0.0:9100'
gitlab_workhorse['prometheus_listen_addr'] = '0.0.0.0:9229'
```

### 외부 PostgreSQL을 사용하는 완전한 세컨더리 사이트 {#complete-secondary-site-with-external-postgresql}

<!-- If you update this configuration example, also update the example in two_single_node_sites.md -->

이 완전한 `gitlab.rb` 구성 예제는 외부 PostgreSQL을 사용하는 Geo 세컨더리 사이트에 대한 것입니다:

```ruby
# Secondary site with external PostgreSQL configuration example

## Geo Secondary role
roles(['geo_secondary_role'])

## The unique identifier for the Geo site
gitlab_rails['geo_node_name'] = 'location-2'

## External URL
external_url 'https://gitlab.example.com'

## External PostgreSQL configuration (read-only replica)
postgresql['enable'] = false
gitlab_rails['db_adapter'] = 'postgresql'
gitlab_rails['db_encoding'] = 'unicode'
gitlab_rails['db_host'] = 'secondary-postgres.example.com'
gitlab_rails['db_port'] = 5432
gitlab_rails['db_database'] = 'gitlabhq_production'
gitlab_rails['db_username'] = 'gitlab'
gitlab_rails['db_password'] = 'your_database_password_here'

## Geo tracking database configuration
geo_secondary['db_username'] = 'gitlab_geo'
geo_secondary['db_password'] = 'your_tracking_db_password_here'
geo_secondary['db_host'] = 'secondary-tracking-db.example.com'
geo_secondary['db_port'] = 5432
geo_postgresql['enable'] = false

## SSL/TLS configuration
nginx['listen_port'] = 80
nginx['listen_https'] = false
letsencrypt['enable'] = false

## Object Storage configuration (must match primary)
gitlab_rails['object_store']['enabled'] = true
gitlab_rails['object_store']['connection'] = {
  'provider' => 'AWS',
  'region' => 'us-east-1',
  'aws_access_key_id' => 'your_access_key',
  'aws_secret_access_key' => 'your_secret_key'
}

## Monitoring configuration
node_exporter['listen_address'] = '0.0.0.0:9100'
gitlab_workhorse['prometheus_listen_addr'] = '0.0.0.0:9229'
```

## 문제 해결 {#troubleshooting}

[Geo 문제 해결](../replication/troubleshooting/_index.md)을 참조하세요.
