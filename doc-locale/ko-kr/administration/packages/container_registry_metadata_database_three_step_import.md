---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 3단계 가져오기
description: 컨테이너 레지스트리 메타데이터 데이터베이스를 최소한의 다운타임으로 활성화합니다.
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

기존 컨테이너 레지스트리 메타데이터를 가져옵니다. 다음 절차는 더 큰 리포지토리(200GiB 이상)에 권장되거나, 가져오기를 완료하는 동안 다운타임을 최소화하려는 경우에 권장됩니다.

## 리포지토리 사전 가져오기(1단계) {#pre-import-repositories-step-one}

사용자는 1단계 가져오기가 [시간당 2~4TB의 속도](https://gitlab.com/gitlab-org/gitlab/-/issues/423459)로 완료되었다고 보고했습니다. 더 느린 속도에서 100TB 이상의 데이터를 가진 리포지토리는 48시간 이상 걸릴 수 있습니다.

1단계가 완료되는 동안 리포지토리를 정상적으로 계속 사용할 수 있습니다.

{{< tabs >}}

{{< tab title="GitLab 18.7 이상" >}}

1. `database` 섹션에서 데이터베이스가 비활성화되어 있는지 `/etc/gitlab/gitlab.rb` 파일에서 확인합니다:

   ```ruby
   registry['database'] = {
     'enabled' => false, # Must be false!
   }
   ```

1. 파일을 저장하고 [GitLab을 다시 구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)하세요.
1. [데이터베이스 마이그레이션 적용](container_registry_metadata_database.md#apply-database-migrations)합니다.
1. 첫 번째 단계를 실행하여 가져오기를 시작합니다:

   ```shell
   sudo gitlab-ctl registry-database import --step-one --log-to-stdout
   ```

{{< /tab >}}

{{< tab title="GitLab 18.3~18.6" >}}

1. `database` 섹션에서 데이터베이스가 비활성화되어 있는지 `/etc/gitlab/gitlab.rb` 파일에서 확인합니다:

   ```ruby
   registry['database'] = {
     'enabled' => false, # Must be false!
   }
   ```

1. 파일을 저장하고 [GitLab을 다시 구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)하세요.
1. [데이터베이스 마이그레이션 적용](container_registry_metadata_database.md#apply-database-migrations)합니다.
1. 첫 번째 단계를 실행하여 가져오기를 시작합니다:

   ```shell
   sudo -u registry gitlab-ctl registry-database import --step-one --log-to-stdout
   ```

{{< /tab >}}

{{< tab title="GitLab 17.5~18.2" >}}

전제 조건:

- [외부 데이터베이스](../postgresql/external.md#container-registry-metadata-database)를 만드세요.

1. `database` 섹션을 `/etc/gitlab/gitlab.rb` 파일에 추가하되, 메타데이터 데이터베이스는 비활성화 상태로 시작합니다:

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

1. 파일을 저장하고 [GitLab을 다시 구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)하세요.
1. 아직 하지 않았다면 [데이터베이스 마이그레이션 적용](container_registry_metadata_database.md#apply-database-migrations)합니다.
1. 첫 번째 단계를 실행하여 가져오기를 시작합니다:

   ```shell
   sudo gitlab-ctl registry-database import --step-one
   ```

{{< /tab >}}

{{< /tabs >}}

> [!note]
> 다음 단계를 가능한 한 빨리 예약하여 필요한 다운타임을 줄이도록 해야 합니다. 이상적으로는 1단계가 완료된 후 1주일 미만이어야 합니다. 1단계와 2단계 사이에 리포지토리에 기록되는 새로운 데이터는 2단계가 더 오래 걸리게 합니다.

## 모든 리포지토리 데이터 가져오기(2단계) {#import-all-repository-data-step-two}

이 단계에서는 리포지토리를 종료하거나 `read-only` 모드로 설정해야 합니다. 그러나 이 단계는 1단계보다 약 90% 더 빠르게 완료될 것으로 예상할 수 있습니다. 2단계가 실행되는 동안 충분한 다운타임을 허용합니다.

{{< tabs >}}

{{< tab title="GitLab 18.7 이상" >}}

1. 리포지토리가 `read-only` 모드로 설정되어 있는지 확인합니다.

   `/etc/gitlab/gitlab.rb`를 편집하고 `maintenance` 섹션을 `registry['storage']` 구성에 추가합니다. 예를 들어, `gcs` 백엔드 리포지토리가 `gs://my-company-container-registry` 버킷을 사용하는 경우, 구성은 다음과 같을 수 있습니다:

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

1. 파일을 저장하고 [GitLab을 다시 구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)하세요.
1. 2단계 가져오기를 실행합니다:

   ```shell
   sudo gitlab-ctl registry-database import --step-two --log-to-stdout
   ```

1. 명령이 성공적으로 완료되면 모든 이미지가 완전히 가져와집니다. 이제 데이터베이스를 활성화하고, 구성에서 읽기 전용 모드를 해제하고, 리포지토리 서비스를 시작할 수 있습니다:

   ```ruby
   registry['database'] = {
     'enabled' => true, # Must be set to true!
   }

   ## Object Storage - Container Registry
   registry['storage'] = {
     'gcs' => {
       'bucket' => '<my-company-container-registry>',
       'chunksize' => 5242880
     },
     'maintenance' => { # This section can be removed.
       'readonly' => {
         'enabled' => false
       }
     }
   }
   ```

1. 파일을 저장하고 [GitLab을 다시 구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)하세요.

{{< /tab >}}

{{< tab title="GitLab 18.3~18.6" >}}

1. 리포지토리가 `read-only` 모드로 설정되어 있는지 확인합니다.

   `/etc/gitlab/gitlab.rb`를 편집하고 `maintenance` 섹션을 `registry['storage']` 구성에 추가합니다. 예를 들어, `gcs` 백엔드 리포지토리가 `gs://my-company-container-registry` 버킷을 사용하는 경우, 구성은 다음과 같을 수 있습니다:

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

1. 파일을 저장하고 [GitLab을 다시 구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)하세요.
1. 2단계 가져오기를 실행합니다:

   ```shell
   sudo -u registry gitlab-ctl registry-database import --step-two --log-to-stdout
   ```

1. 명령이 성공적으로 완료되면 모든 이미지가 완전히 가져와집니다. 이제 데이터베이스를 활성화하고, 구성에서 읽기 전용 모드를 해제하고, 리포지토리 서비스를 시작할 수 있습니다:

   ```ruby
   registry['database'] = {
     'enabled' => true, # Must be set to true!
   }

   ## Object Storage - Container Registry
   registry['storage'] = {
     'gcs' => {
       'bucket' => '<my-company-container-registry>',
       'chunksize' => 5242880
     },
     'maintenance' => { # This section can be removed.
       'readonly' => {
         'enabled' => false
       }
     }
   }
   ```

1. 파일을 저장하고 [GitLab을 다시 구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)하세요.

{{< /tab >}}

{{< tab title="GitLab 17.5~18.2" >}}

1. 리포지토리가 `read-only` 모드로 설정되어 있는지 확인합니다.

   `/etc/gitlab/gitlab.rb`를 편집하고 `maintenance` 섹션을 `registry['storage']` 구성에 추가합니다. 예를 들어, `gcs` 백엔드 리포지토리가 `gs://my-company-container-registry` 버킷을 사용하는 경우, 구성은 다음과 같을 수 있습니다:

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

1. 파일을 저장하고 [GitLab을 다시 구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)하세요.
1. 2단계 가져오기를 실행합니다:

   ```shell
   sudo gitlab-ctl registry-database import --step-two
   ```

1. 명령이 성공적으로 완료되면 모든 이미지가 완전히 가져와집니다. 이제 데이터베이스를 활성화하고, 구성에서 읽기 전용 모드를 해제하고, 리포지토리 서비스를 시작할 수 있습니다:

   ```ruby
   registry['database'] = {
     'enabled' => true, # Must be set to true!
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
     'maintenance' => { # This section can be removed.
       'readonly' => {
         'enabled' => false
       }
     }
   }
   ```

1. 파일을 저장하고 [GitLab을 다시 구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)하세요.

{{< /tab >}}

{{< /tabs >}}

이제 모든 작업에 메타데이터 데이터베이스를 사용할 수 있습니다!

## 남은 데이터 가져오기(3단계) {#import-remaining-data-step-three}

리포지토리가 이제 메타데이터에 대해 데이터베이스를 완전히 사용하고 있지만, 사용하지 않을 수 있는 레이어 blob에 아직 액세스하지 못하여 이러한 blob이 온라인 가비지 컬렉터에 의해 제거되지 않습니다.

3단계가 완료되는 동안 리포지토리를 정상적으로 계속 사용할 수 있습니다.

프로세스를 완료하려면 마이그레이션의 최종 단계를 실행합니다:

{{< tabs >}}

{{< tab title="GitLab 18.7 이상" >}}

```shell
sudo gitlab-ctl registry-database import --step-three --log-to-stdout
```

{{< /tab >}}

{{< tab title="GitLab 18.3~18.6" >}}

```shell
sudo -u registry gitlab-ctl registry-database import --step-three --log-to-stdout
```

{{< /tab >}}

{{< tab title="GitLab 17.5~18.2" >}}

```shell
sudo gitlab-ctl registry-database import --step-three
```

{{< /tab >}}

{{< /tabs >}}

해당 명령이 성공적으로 종료되면 리포지토리 메타데이터가 이제 데이터베이스로 완전히 가져와집니다.

## 가져오기 후 {#after-import}

큰 리포지토리는 가져오기 후에 가비지 컬렉션 검토를 위해 대기 중인 수십만 개 또는 수백만 개의 blob을 가질 수 있습니다. 이는 예상되는 동작이며, 기본 작업자 간격에서 처리하는 데 시간이 걸립니다.

예상되는 사항 및 처리 속도를 높이는 방법에 대한 지침은 다음을 참조하세요:

- [가져오기 후](container_registry_metadata_database.md#post-import) 가져오기 완료 후 예상되는 동작의 개요입니다.
- [온라인 가비지 컬렉션의 상태 확인](container_registry_metadata_database.md#check-the-health-of-online-garbage-collection) 가비지 컬렉션 검토 큐를 모니터링합니다.
- [가비지 수집기 작업자 간격 조정](container_registry_metadata_database.md#adjust-the-garbage-collector-worker-interval)하여 대규모 백로그의 처리 속도를 일시적으로 높입니다.
