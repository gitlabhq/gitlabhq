---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 외부 PostgreSQL 서비스를 사용하여 GitLab 구성
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

클라우드 공급자에서 GitLab을 호스팅하는 경우 선택적으로 PostgreSQL용 관리 서비스를 사용할 수 있습니다. 예를 들어 AWS는 PostgreSQL을 실행하는 관리형 관계형 데이터베이스 서비스(RDS)를 제공합니다.

또는 Linux 패키지와 별도로 자체 PostgreSQL 인스턴스 또는 클러스터를 관리하도록 선택할 수 있습니다.

클라우드 관리 서비스를 사용하거나 자체 PostgreSQL 인스턴스를 제공하는 경우 [데이터베이스 요구사항 문서](../../install/requirements.md#postgresql)에 따라 PostgreSQL을 설정하세요.

## GitLab Rails 데이터베이스 {#gitlab-rails-database}

외부 PostgreSQL 서버를 설정한 후:

1. 데이터베이스 서버에 로그인합니다.
1. `gitlab` 사용자를 암호와 함께 설정하고 `gitlabhq_production` 데이터베이스를 생성한 다음 사용자를 데이터베이스 소유자로 설정합니다. [자체 컴파일 설치 문서](../../install/self_compiled/_index.md#7-database)에서 이 설정의 예를 확인할 수 있습니다.
1. 클라우드 관리 서비스를 사용하는 경우 `gitlab` 사용자에게 추가 역할을 부여해야 할 수 있습니다:
   - Amazon RDS는 [`rds_superuser`](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.html#Appendix.PostgreSQL.CommonDBATasks.Roles) 역할이 필요합니다.
   - Azure Database for PostgreSQL은 [`azure_pg_admin`](https://learn.microsoft.com/en-us/azure/postgresql/single-server/how-to-create-users#how-to-create-additional-admin-users-in-azure-database-for-postgresql) 역할이 필요합니다. Azure Database for PostgreSQL - Flexible Server는 [설치하기 전에 확장 프로그램을 허용 목록에 추가해야 합니다](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-extensions#how-to-use-postgresql-extensions).
   - Google Cloud SQL은 [`cloudsqlsuperuser`](https://cloud.google.com/sql/docs/postgres/users#default-users) 역할이 필요합니다.

   이는 설치 및 업그레이드 중 확장 프로그램 설치를 위한 것입니다. 또는 [필요한 확장 프로그램을 수동으로 설치](extensions.md)하세요.
1. GitLab 애플리케이션 서버를 `/etc/gitlab/gitlab.rb` 파일의 외부 PostgreSQL 서비스에 적합한 연결 세부 정보로 구성합니다:

   ```ruby
   # Disable the bundled Omnibus provided PostgreSQL
   postgresql['enable'] = false

   # PostgreSQL connection details
   gitlab_rails['db_adapter'] = 'postgresql'
   gitlab_rails['db_encoding'] = 'unicode'
   gitlab_rails['db_host'] = '10.1.0.5' # IP/hostname of database server
   gitlab_rails['db_port'] = 5432
   gitlab_rails['db_password'] = 'DB password'
   ```

   GitLab 다중 노드 설정에 대한 자세한 내용은 [참조 아키텍처](../reference_architectures/_index.md)를 참조하세요.

1. 변경 사항이 적용되도록 다시 구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. TCP 포트를 활성화하려면 PostgreSQL을 다시 시작합니다:

   ```shell
   sudo gitlab-ctl restart
   ```

## 컨테이너 레지스트리 메타데이터 데이터베이스 {#container-registry-metadata-database}

[컨테이너 레지스트리 메타데이터 데이터베이스](../packages/container_registry_metadata_database.md)를 사용하려는 경우 레지스트리 데이터베이스 및 사용자도 생성해야 합니다.

외부 PostgreSQL 서버를 설정한 후:

1. 데이터베이스 서버에 로그인합니다.
1. 다음 SQL 명령을 사용하여 사용자 및 데이터베이스를 생성합니다:

   ```sql
   -- Create the registry user
   CREATE USER registry WITH PASSWORD '<your_registry_password>';

   -- Create the registry database
   CREATE DATABASE registry OWNER registry;
   ```

1. 클라우드 관리 서비스의 경우 필요에 따라 추가 역할을 부여합니다:

   {{< tabs >}}

   {{< tab title="Amazon RDS" >}}

   ```sql
   GRANT rds_superuser TO registry;
   ```

   {{< /tab >}}

   {{< tab title="Azure 데이터베이스" >}}

   ```sql
   GRANT azure_pg_admin TO registry;
   ```

   {{< /tab >}}

   {{< tab title="Google Cloud SQL" >}}

   ```sql
   GRANT cloudsqlsuperuser TO registry;
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. 이제 컨테이너 레지스트리 메타데이터 데이터베이스를 활성화하고 사용을 시작할 수 있습니다.

## 문제 해결 {#troubleshooting}

### `SSL SYSCALL error: EOF detected` 오류 해결 {#resolve-ssl-syscall-error-eof-detected-error}

외부 PostgreSQL 인스턴스를 사용할 때 다음과 같은 오류가 나타날 수 있습니다:

```shell
pg_dump: error: Error message from server: SSL SYSCALL error: EOF detected
```

이 오류를 해결하려면 [PostgreSQL 최소 요구사항](../../install/requirements.md#postgresql)을 충족하는지 확인하세요. RDS 인스턴스를 [지원되는 버전](../../install/requirements.md#postgresql)으로 업그레이드한 후 이 오류 없이 백업을 수행할 수 있습니다. 자세한 내용은 [64763](https://gitlab.com/gitlab-org/gitlab/-/issues/364763)을 참조하세요.
