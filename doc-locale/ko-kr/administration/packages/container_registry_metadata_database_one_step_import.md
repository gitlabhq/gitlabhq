---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 원스텝 임포트
description: 컨테이너 레지스트리 메타데이터 데이터베이스를 한 단계로 활성화합니다.
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

정기적으로 [오프라인 가비지 컬렉션](container_registry.md#container-registry-garbage-collection)을 실행하는 경우 원스텝 임포트 방법을 사용하세요. 이 방법은 3단계 임포트 방법과 비교하여 더 간단한 작업입니다.

## 원스텝 임포트 {#one-step-import}

> [!warning]
> 임포트 중에 레지스트리를 종료하거나 `read-only` 모드로 유지해야 합니다. 그렇지 않으면 임포트 중에 기록된 데이터에 접근할 수 없거나 불일치가 발생합니다.

{{< tabs >}}

{{< tab title="GitLab 18.7 이상" >}}

1. `registry['database']` 섹션에서 데이터베이스가 비활성화되어 있는지 확인합니다(`/etc/gitlab/gitlab.rb` 파일):

   ```ruby
   registry['database'] = {
     'enabled' => false, # Must be false!
   }
   ```

1. 레지스트리가 `read-only` 모드로 설정되어 있는지 확인합니다.

   `/etc/gitlab/gitlab.rb`을 편집하고 `maintenance` 섹션을 `registry['storage']` 구성에 추가합니다. 예를 들어 `gcs` 백엔드 레지스트리에서 `gs://my-company-container-registry` 버킷을 사용하는 경우 구성은 다음과 같을 수 있습니다:

   ```ruby
   ## Object Storage - Container Registry
   registry['storage'] = {
     'gcs' => {
       'bucket' => '<my-company-container-registry>',
       'chunksize' => 5242880
     },
     'maintenance' => {
       'readonly' => {
         'enabled' => true # Must be set to true.
       }
     }
   }
   ```

1. 파일을 저장하고 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.
1. [데이터베이스 마이그레이션 적용](container_registry_metadata_database.md#apply-database-migrations)합니다.
1. 다음 명령을 실행합니다:

   ```shell
   sudo gitlab-ctl registry-database import --log-to-stdout
   ```

1. 명령이 성공적으로 완료되었으면 레지스트리가 완전히 임포트됩니다. 데이터베이스를 활성화하고 구성에서 읽기 전용 모드를 끄고 레지스트리 서비스를 시작할 수 있습니다:

   ```ruby
   registry['database'] = {
     'enabled' => true, # Must be enabled now!
   }

   ## Object Storage - Container Registry
   registry['storage'] = {
     'gcs' => {
       'bucket' => '<my-company-container-registry>',
       'chunksize' => 5242880
     },
     'maintenance' => {
       'readonly' => {
         'enabled' => false
       }
     }
   }
   ```

1. 파일을 저장하고 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.

{{< /tab >}}

{{< tab title="GitLab 18.3~18.6" >}}

1. `registry['database']` 섹션에서 데이터베이스가 비활성화되어 있는지 확인합니다(`/etc/gitlab/gitlab.rb` 파일):

   ```ruby
   registry['database'] = {
     'enabled' => false, # Must be false!
   }
   ```

1. 레지스트리가 `read-only` 모드로 설정되어 있는지 확인합니다.

   `/etc/gitlab/gitlab.rb`을 편집하고 `maintenance` 섹션을 `registry['storage']` 구성에 추가합니다. 예를 들어 `gcs` 백엔드 레지스트리에서 `gs://my-company-container-registry` 버킷을 사용하는 경우 구성은 다음과 같을 수 있습니다:

   ```ruby
   ## Object Storage - Container Registry
   registry['storage'] = {
     'gcs' => {
       'bucket' => '<my-company-container-registry>',
       'chunksize' => 5242880
     },
     'maintenance' => {
       'readonly' => {
         'enabled' => true # Must be set to true.
       }
     }
   }
   ```

1. 파일을 저장하고 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.
1. [데이터베이스 마이그레이션 적용](container_registry_metadata_database.md#apply-database-migrations)합니다.
1. 다음 명령을 실행합니다:

   ```shell
   sudo -u registry gitlab-ctl registry-database import --log-to-stdout
   ```

1. 명령이 성공적으로 완료되었으면 레지스트리가 완전히 임포트됩니다. 데이터베이스를 활성화하고 구성에서 읽기 전용 모드를 끄고 레지스트리 서비스를 시작할 수 있습니다:

   ```ruby
   registry['database'] = {
     'enabled' => true, # Must be enabled now!
   }

   ## Object Storage - Container Registry
   registry['storage'] = {
     'gcs' => {
       'bucket' => '<my-company-container-registry>',
       'chunksize' => 5242880
     },
     'maintenance' => {
       'readonly' => {
         'enabled' => false
       }
     }
   }
   ```

1. 파일을 저장하고 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.

{{< /tab >}}

{{< tab title="GitLab 17.5 ~ 18.2" >}}

전제 조건:

- [외부 데이터베이스](../postgresql/external.md#container-registry-metadata-database)를 생성합니다.

1. `database` 섹션을 `/etc/gitlab/gitlab.rb` 파일에 추가합니다. 단, 메타데이터 데이터베이스는 처음에 비활성화된 상태로 시작합니다:

   ```ruby
   registry['database'] = {
     'enabled' => false, # Must be false!
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

1. 레지스트리가 `read-only` 모드로 설정되어 있는지 확인합니다.

   `/etc/gitlab/gitlab.rb`을 편집하고 `maintenance` 섹션을 `registry['storage']` 구성에 추가합니다. 예를 들어 `gcs` 백엔드 레지스트리에서 `gs://my-company-container-registry` 버킷을 사용하는 경우 구성은 다음과 같을 수 있습니다:

   ```ruby
   ## Object Storage - Container Registry
   registry['storage'] = {
     'gcs' => {
       'bucket' => '<my-company-container-registry>',
       'chunksize' => 5242880
     },
     'maintenance' => {
       'readonly' => {
         'enabled' => true # Must be set to true.
       }
     }
   }
   ```

1. 파일을 저장하고 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.
1. [데이터베이스 마이그레이션 적용](container_registry_metadata_database.md#apply-database-migrations)(아직 수행하지 않은 경우)합니다.
1. 다음 명령을 실행합니다:

   ```shell
   sudo gitlab-ctl registry-database import
   ```

1. 명령이 성공적으로 완료되었으면 레지스트리가 이제 완전히 임포트됩니다. 이제 데이터베이스를 활성화하고 구성에서 읽기 전용 모드를 끄고 레지스트리 서비스를 시작할 수 있습니다:

   ```ruby
   registry['database'] = {
     'enabled' => true, # Must be enabled now!
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

   ## Object Storage - Container Registry
   registry['storage'] = {
     'gcs' => {
       'bucket' => '<my-company-container-registry>',
       'chunksize' => 5242880
     },
     'maintenance' => {
       'readonly' => {
         'enabled' => false
       }
     }
   }
   ```

1. 파일을 저장하고 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.

{{< /tab >}}

{{< /tabs >}}

이제 모든 작업에 메타데이터 데이터베이스를 사용할 수 있습니다!

## 임포트 후 {#after-import}

대규모 레지스트리는 임포트 후 가비지 컬렉션 검토를 위해 수백만 또는 수천만 개의 블롭이 대기 중일 수 있습니다. 이는 예상된 현상이며 기본 워커 간격에서는 처리하는 데 시간이 소요됩니다.

예상되는 결과와 처리 속도를 높이는 방법에 대한 지침은 다음을 참조하세요:

- [임포트 후](container_registry_metadata_database.md#post-import) \- 임포트 완료 후 예상되는 동작에 대한 개요입니다.
- [온라인 가비지 컬렉션의 상태 확인](container_registry_metadata_database.md#check-the-health-of-online-garbage-collection) \- 가비지 컬렉션 검토 큐를 모니터링합니다.
- [가비지 컬렉터 워커 간격 조정](container_registry_metadata_database.md#adjust-the-garbage-collector-worker-interval) \- 대규모 백로그에 대해 일시적으로 처리 속도를 높입니다.
