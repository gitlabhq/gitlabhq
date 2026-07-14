---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 외부 PostgreSQL 인스턴스를 사용한 Geo
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

이 문서는 Linux 패키지로 관리되지 않는 PostgreSQL 인스턴스를 사용하는 경우에 해당합니다. 여기에는 [클라우드 관리 인스턴스](../../reference_architectures/_index.md#best-practices-for-the-database-services) 또는 수동으로 설치하고 구성한 PostgreSQL 인스턴스가 포함됩니다.

Geo 사이트를 다시 빌드해야 하는 경우 [버전 불일치를 피하기](../_index.md#requirements-for-running-geo) 위해 [Linux 패키지와 함께 제공되는](../../package_information/postgresql_versions.md) PostgreSQL 버전 중 하나를 사용 중인지 확인합니다.

> [!note]
> GitLab Geo를 사용 중이라면 Linux 패키지를 사용하여 설치된 인스턴스 또는 [검증된 클라우드 관리 인스턴스](../../reference_architectures/_index.md#recommended-cloud-providers-and-services)를 실행할 것을 강력히 권장합니다. 왜냐하면 저희는 해당 인스턴스를 기반으로 적극적으로 개발하고 테스트하기 때문입니다. 다른 외부 데이터베이스와의 호환성을 보장할 수 없습니다.

## **프라이머리** 사이트 {#primary-site}

1. **Rails node on your primary**로 SSH 연결하고 루트로 로그인합니다:

   ```shell
   sudo -i
   ```

1. `/etc/gitlab/gitlab.rb`를 편집하고 다음을 추가합니다:

   ```ruby
   ##
   ## Geo Primary role
   ## - configure dependent flags automatically to enable Geo
   ##
   roles ['geo_primary_role']

   ##
   ## The unique identifier for the Geo site. See
   ## https://docs.gitlab.com/administration/geo_sites/#common-settings
   ##
   gitlab_rails['geo_node_name'] = '<site_name_here>'
   ```

1. 변경 사항이 적용되도록 **Rails node**를 재구성합니다:

   ```shell
   gitlab-ctl reconfigure
   ```

1. **Rails node**에서 아래 명령을 실행하여 사이트를 **프라이머리** 사이트로 정의합니다:

   ```shell
   gitlab-ctl set-geo-primary-node
   ```

   이 명령은 `/etc/gitlab/gitlab.rb`에서 정의한 `external_url`을(를) 사용합니다.

### 복제할 외부 데이터베이스 구성 {#configure-the-external-database-to-be-replicated}

외부 데이터베이스를 설정하려면 다음 중 하나를 수행할 수 있습니다:

- [스트리밍 복제](https://www.postgresql.org/docs/16/warm-standby.html#STREAMING-REPLICATION-SLOTS)를 직접 설정합니다(예: Amazon RDS 또는 Linux 패키지로 관리되지 않는 베어 메탈).
- Linux 패키지 설치의 구성을 수동으로 수행합니다.

#### 클라우드 제공자의 도구를 활용하여 프라이머리 데이터베이스 복제 {#leverage-your-cloud-providers-tools-to-replicate-the-primary-database}

AWS EC2에서 RDS를 사용하는 프라이머리 사이트가 설정되어 있다고 가정합니다. 이제 다른 리전에서 읽기 전용 복제본을 만들 수 있으며 복제 프로세스는 AWS에서 관리합니다. 네트워크 ACL(액세스 제어 목록), 서브넷 및 보안 그룹을 필요에 따라 설정했는지 확인하여 세컨더리 Rails 노드가 데이터베이스에 액세스할 수 있도록 합니다.

다음 지침은 일반적인 클라우드 제공자를 위한 읽기 전용 복제본을 만드는 방법을 자세히 설명합니다:

- Amazon RDS - [읽기 복제본 생성](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ReadRepl.html#USER_ReadRepl.Create)
- Azure Database for PostgreSQL - [Azure Database for PostgreSQL에서 읽기 복제본 생성 및 관리](https://learn.microsoft.com/en-us/azure/postgresql/single-server/how-to-read-replicas-portal)
- Google Cloud SQL - [읽기 복제본 생성](https://cloud.google.com/sql/docs/postgres/replication/create-replica)

읽기 전용 복제본이 설정되면 [세컨더리 사이트 구성](#configure-secondary-site-to-use-the-external-read-replica)으로 건너뜁니다.

> [!warning]
> [AWS Database Migration Service](https://aws.amazon.com/dms/) 또는 [Google Cloud Database Migration Service](https://cloud.google.com/database-migration)와 같은 논리적 복제 방법을 사용하여 온-프레미스 프라이머리 데이터베이스에서 RDS 세컨더리로 복제하는 것은 지원되지 않습니다.

#### 복제를 위해 프라이머리 데이터베이스를 수동으로 구성 {#manually-configure-the-primary-database-for-replication}

[`geo_primary_role`](https://docs.gitlab.com/omnibus/roles/#gitlab-geo-roles)는 `pg_hba.conf` 및 `postgresql.conf`에 변경 사항을 적용하여 **프라이머리** 노드의 데이터베이스를 복제하도록 구성합니다. 외부 데이터베이스 구성에 다음 구성 변경 사항을 수동으로 적용하고 변경 사항이 적용되도록 나중에 PostgreSQL을 다시 시작해야 합니다:

```plaintext
##
## Geo Primary Role
## - pg_hba.conf
##
host    all         all               <trusted primary IP>/32       md5
host    replication gitlab_replicator <trusted primary IP>/32       md5
host    all         all               <trusted secondary IP>/32     md5
host    replication gitlab_replicator <trusted secondary IP>/32     md5
```

```plaintext
##
## Geo Primary Role
## - postgresql.conf
##
wal_level = hot_standby
max_wal_senders = 10
wal_keep_segments = 50
max_replication_slots = 1 # number of secondary instances
hot_standby = on
```

## **세컨더리** 사이트 {#secondary-sites}

### 복제 데이터베이스를 수동으로 구성 {#manually-configure-the-replica-database}

외부 복제 데이터베이스의 `pg_hba.conf` 및 `postgresql.conf`에 다음 구성 변경 사항을 수동으로 적용하고 변경 사항이 적용되도록 나중에 PostgreSQL을 다시 시작해야 합니다:

```plaintext
##
## Geo Secondary Role
## - pg_hba.conf
##
host    all         all               <trusted secondary IP>/32     md5
host    replication gitlab_replicator <trusted secondary IP>/32     md5
host    all         all               <trusted primary IP>/24       md5
```

```plaintext
##
## Geo Secondary Role
## - postgresql.conf
##
wal_level = hot_standby
max_wal_senders = 10
wal_keep_segments = 10
hot_standby = on
```

### **세컨더리** 사이트를 외부 읽기 복제본을 사용하도록 구성 {#configure-secondary-site-to-use-the-external-read-replica}

Linux 패키지 설치의 경우 [`geo_secondary_role`](https://docs.gitlab.com/omnibus/roles/#gitlab-geo-roles)는 세 가지 주요 기능을 합니다:

1. 복제 데이터베이스를 구성합니다.
1. 추적 데이터베이스를 구성합니다.
1. [Geo Log Cursor](../_index.md#geo-log-cursor)를 활성화합니다(이 섹션에서는 다루지 않음).

외부 읽기 복제본 데이터베이스에 대한 연결을 구성하고 Log Cursor를 활성화하려면:

1. **세컨더리** 사이트의 각 **Rails, Sidekiq and Geo Log Cursor** 노드로 SSH 연결하고 루트로 로그인합니다:

   ```shell
   sudo -i
   ```

1. `/etc/gitlab/gitlab.rb`을(를) 편집하고 다음을 추가합니다.

   ```ruby
   ##
   ## Geo Secondary role
   ## - configure dependent flags automatically to enable Geo
   ##
   roles ['geo_secondary_role']

   # note this is shared between both databases,
   # make sure you define the same password in both
   gitlab_rails['db_password'] = '<your_primary_db_password_here>'

   gitlab_rails['db_username'] = 'gitlab'
   gitlab_rails['db_host'] = '<database_read_replica_host>'

   # Disable the bundled Omnibus PostgreSQL because we are
   # using an external PostgreSQL
   postgresql['enable'] = false
   ```

1. 파일을 저장하고 [GitLab 재구성](../../restart_gitlab.md#reconfigure-a-linux-package-installation)

### 추적 데이터베이스 구성 {#configure-the-tracking-database}

**세컨더리** 사이트는 별도의 PostgreSQL 설치를 추적 데이터베이스로 사용하여 복제 상태를 추적하고 잠재적 복제 문제에서 자동으로 복구합니다. `roles ['geo_secondary_role']`가 설정되면 Linux 패키지가 자동으로 추적 데이터베이스를 구성합니다. 이 데이터베이스를 Linux 패키지 설치 외부에서 실행하려면 다음 지침을 사용합니다.

#### 내부 및 외부 추적 데이터베이스 이해 {#understanding-internal-and-external-tracking-databases}

추적 데이터베이스를 다음 중 하나로 구성할 수 있습니다:

- 내부(`geo_postgresql['enable'] = true`):  추적 데이터베이스는 Rails 애플리케이션과 같은 서버에서 관리되는 PostgreSQL 인스턴스로 실행됩니다. 이것이 기본값입니다.
- 외부(`geo_postgresql['enable'] = false`):  추적 데이터베이스는 별도의 서버 또는 클라우드 관리 서비스로 실행됩니다.

다중 노드 세컨더리 사이트 설정에서 한 Rails 노드에서 추적 데이터베이스를 활성화하면 사이트의 다른 모든 Rails 노드에 "외부"가 됩니다. 다른 모든 Rails 노드는 `geo_postgresql['enable'] = false`을(를) 설정하고 해당 추적 데이터베이스에 연결하기 위한 연결 세부 정보를 지정해야 합니다.

#### 클라우드 관리 데이터베이스 서비스 {#cloud-managed-database-services}

추적 데이터베이스에 클라우드 관리 서비스를 사용하는 경우 추적 데이터베이스 사용자(기본적으로 `gitlab_geo`)에 추가 역할을 부여해야 할 수 있습니다:

- Amazon RDS는 [`rds_superuser`](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.html#Appendix.PostgreSQL.CommonDBATasks.Roles) 역할이 필요합니다.
- Azure Database for PostgreSQL은 [`azure_pg_admin`](https://learn.microsoft.com/en-us/azure/postgresql/single-server/how-to-create-users#how-to-create-additional-admin-users-in-azure-database-for-postgresql) 역할이 필요합니다.
- Google Cloud SQL은 [`cloudsqlsuperuser`](https://cloud.google.com/sql/docs/postgres/users#default-users) 역할이 필요합니다.

이것은 설치 및 업그레이드 중 확장 설치를 위한 것입니다. 또는 [필수 확장 프로그램을 수동으로 설치](../../postgresql/extensions.md)합니다.

> [!note]
> Amazon RDS를 추적 데이터베이스로 사용하려면 세컨더리 데이터베이스에 액세스할 수 있는지 확인합니다. 불행하게도 같은 보안 그룹을 할당하는 것만으로는 충분하지 않습니다. 아웃바운드 규칙이 RDS PostgreSQL 데이터베이스에 적용되지 않기 때문입니다. 따라서 읽기 복제본의 보안 그룹에 포트 5432의 추적 데이터베이스에서 모든 TCP 트래픽을 허용하는 인바운드 규칙을 명시적으로 추가해야 합니다.

#### 추적 데이터베이스 생성 {#create-the-tracking-database}

PostgreSQL 인스턴스에서 추적 데이터베이스를 생성하고 구성합니다:

1. [데이터베이스 요구 사항 문서](../../../install/requirements.md#postgresql)에 따라 PostgreSQL을 설정합니다.
1. 선택한 암호를 사용하여 `gitlab_geo` 사용자를 설정하고 `gitlabhq_geo_production` 데이터베이스를 생성하고 사용자를 데이터베이스 소유자로 만듭니다. [자체 컴파일 설치 문서](../../../install/self_compiled/_index.md#7-database)에서 이 설정의 예를 볼 수 있습니다.
1. 클라우드 관리 PostgreSQL 데이터베이스를 **not** 세컨더리 사이트가 추적 데이터베이스와 통신할 수 있도록 추적 데이터베이스와 연결된 `pg_hba.conf`을(를) 수동으로 변경하여 확인합니다. 변경 사항이 적용되도록 나중에 PostgreSQL을 다시 시작하는 것을 잊지 마세요:

   ```plaintext
   ##
   ## Geo Tracking Database Role
   ## - pg_hba.conf
   ##
   host    all         all               <trusted tracking IP>/32      md5
   host    all         all               <trusted secondary IP>/32     md5
   # In multi-node setups, add entries for all Rails nodes that will connect
   ```

#### GitLab 구성 {#configure-gitlab}

이 데이터베이스를 사용하도록 GitLab을 구성합니다. 이 단계는 Linux 패키지 및 Docker 배포용입니다.

1. GitLab **세컨더리** 서버로 SSH 연결하고 루트로 로그인합니다:

   ```shell
   sudo -i
   ```

1. PostgreSQL 인스턴스가 있는 머신에 대한 연결 매개변수 및 자격 증명으로 `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   geo_secondary['db_username'] = 'gitlab_geo'
   geo_secondary['db_password'] = '<your_tracking_db_password_here>'

   geo_secondary['db_host'] = '<tracking_database_host>'
   geo_secondary['db_port'] = <tracking_database_port>      # change to the correct port
   geo_postgresql['enable'] = false     # don't use internal managed instance
   ```

   다중 노드 설정에서 외부 추적 데이터베이스에 연결해야 하는 각 Rails 노드에 이 구성을 적용합니다.

1. 파일을 저장하고 [GitLab 재구성](../../restart_gitlab.md#reconfigure-a-linux-package-installation)

#### 데이터베이스 스키마 설정 {#set-up-the-database-schema}

[이전에 나열된 단계](#configure-gitlab)의 재구성 명령은 Linux 패키지 및 Docker 배포에 대해 이러한 단계를 자동으로 처리해야 합니다.

1. 이 작업은 데이터베이스 스키마를 생성합니다. 데이터베이스 사용자가 슈퍼유저여야 합니다.

   ```shell
   sudo gitlab-rake db:create:geo
   ```

1. Rails 데이터베이스 마이그레이션(스키마 및 데이터 업데이트) 적용도 재구성에 의해 수행됩니다. `geo_secondary['auto_migrate'] = false`이(가) 설정되었거나 스키마가 수동으로 생성된 경우 이 단계가 필요합니다:

   ```shell
   sudo gitlab-rake db:migrate:geo
   ```
