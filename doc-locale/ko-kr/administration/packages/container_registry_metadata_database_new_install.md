---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 새로운 설치를 위한 컨테이너 레지스트리 메타데이터 데이터베이스
description: 새로운 설치를 위해 컨테이너 레지스트리 메타데이터 데이터베이스를 활성화합니다.
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

인스턴스용 컨테이너 레지스트리 메타데이터 데이터베이스를 활성화합니다.

## 메타데이터 데이터베이스 활성화 {#enable-the-metadata-database}

새로운 컨테이너 레지스트리용 메타데이터 데이터베이스를 활성화합니다.

{{< tabs >}}

{{< tab title="GitLab 18.3 이상" >}}

전제 조건:

- 컨테이너 레지스트리에 푸시된 이미지가 없는 새로운 컨테이너 레지스트리가 있어야 합니다.

데이터베이스를 활성화하려면:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하고 `enabled`을(를) `true`으로 설정합니다:

   ```ruby
   registry['database'] = {
     'enabled' => true,
   }
   ```

1. 파일을 저장하고 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.

{{< /tab >}}

{{< tab title="GitLab 17.5 ~ 18.2" >}}

전제 조건:

- 컨테이너 레지스트리에 푸시된 이미지가 없는 새로운 컨테이너 레지스트리가 있어야 합니다.
- [외부 데이터베이스](../postgresql/external.md#container-registry-metadata-database)를 생성합니다.

데이터베이스를 활성화하려면:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하여 데이터베이스 연결 정보를 추가하되, 메타데이터 데이터베이스는 먼저 비활성화된 상태로 시작합니다:

   ```ruby
   registry['database'] = {
     'enabled' => false,
     'host' => '<registry_database_host_placeholder_change_me>',
     'port' => 5432, # Default, but set to the port of your database instance if it differs.
     'user' => '<registry_database_username_placeholder_change_me>',
     'password' => '<registry_database_placeholder_change_me>',
     'dbname' => '<registry_database_name_placeholder_change_me>',
     'sslmode' => 'require', # See the PostgreSQL documentation for additional information https://www.postgresql.org/docs/16/libpq-ssl.html.
     'sslcert' => '</path/to/cert.pem>',
     'sslkey' => '</path/to/private.key>',
     'sslrootcert' => '</path/to/ca.pem>'
   }
   ```

1. 파일을 저장하고 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.
1. [데이터베이스 마이그레이션 적용](container_registry_metadata_database.md#apply-database-migrations)합니다.
1. `/etc/gitlab/gitlab.rb`을(를) 편집하고 `enabled`을(를) `true`으로 설정합니다:

   ```ruby
   registry['database'] = {
     'enabled' => true,
     'host' => '<registry_database_host_placeholder_change_me>',
     'port' => 5432, # Default, but set to the port of your database instance if it differs.
     'user' => '<registry_database_username_placeholder_change_me>',
     'password' => '<registry_database_placeholder_change_me>',
     'dbname' => '<registry_database_name_placeholder_change_me>',
     'sslmode' => 'require', # See the PostgreSQL documentation for additional information https://www.postgresql.org/docs/16/libpq-ssl.html.
     'sslcert' => '</path/to/cert.pem>',
     'sslkey' => '</path/to/private.key>',
     'sslrootcert' => '</path/to/ca.pem>'
   }
   ```

{{< /tab >}}

{{< /tabs >}}

이제 모든 작업에 메타데이터 데이터베이스를 사용할 수 있습니다!
