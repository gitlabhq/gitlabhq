---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 컨테이너 레지스트리 메타데이터 데이터베이스 문제 해결
description: 컨테이너 레지스트리 메타데이터 데이터베이스의 문제를 해결합니다.
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

## 오류: `there are pending database migrations` {#error-there-are-pending-database-migrations}

컨테이너 레지스트리가 업데이트되었고 대기 중인 스키마 마이그레이션이 있으면 컨테이너 레지스트리가 다음 오류 메시지와 함께 시작에 실패합니다:

```shell
FATA[0000] configuring application: there are pending database migrations, use the 'registry database migrate' CLI command to check and apply them
```

이 문제를 해결하려면 [데이터베이스 마이그레이션 적용](container_registry_metadata_database.md#apply-database-migrations)의 단계를 따르세요.

버전 18.3 이전에는 각 버전 업그레이드 시 데이터베이스 마이그레이션을 수동으로 적용해야 합니다.

### 오류: `offline garbage collection is no longer possible` {#error-offline-garbage-collection-is-no-longer-possible}

컨테이너 레지스트리가 메타데이터 데이터베이스를 사용하고 [오프라인 가비지 컬렉션](container_registry.md#container-registry-garbage-collection)을 실행하려고 하면 컨테이너 레지스트리가 다음 오류 메시지와 함께 실패합니다:

```shell
ERRO[0000] this filesystem is managed by the metadata database, and offline garbage collection is no longer possible, if you are not using the database anymore, remove the file at the lock_path in this log message lock_path=/docker/registry/lockfiles/database-in-use
```

다음 중 하나를 수행해야 합니다:

- 오프라인 가비지 컬렉션 사용을 중단합니다.
- 메타데이터 데이터베이스를 더 이상 사용하지 않으면 오류 메시지에 표시된 `lock_path`의 지정된 잠금 파일을 삭제합니다. 예를 들어 `/docker/registry/lockfiles/database-in-use` 파일을 삭제합니다.

### 오류: `cannot execute <STATEMENT> in a read-only transaction` {#error-cannot-execute-statement-in-a-read-only-transaction}

컨테이너 레지스트리가 다음 오류 메시지와 함께 [데이터베이스 마이그레이션 적용](container_registry_metadata_database.md#apply-database-migrations)에 실패할 수 있습니다:

```shell
err="ERROR: cannot execute CREATE TABLE in a read-only transaction (SQLSTATE 25006)"
```

또한 [온라인 가비지 컬렉션](container_registry.md#performing-garbage-collection-without-downtime)을 실행하려고 하면 컨테이너 레지스트리가 다음 오류 메시지와 함께 실패할 수 있습니다:

```shell
error="processing task: fetching next GC blob task: scanning GC blob task: ERROR: cannot execute SELECT FOR UPDATE in a read-only transaction (SQLSTATE 25006)"
```

PostgreSQL 콘솔에서 `default_transaction_read_only`과 `transaction_read_only`의 값을 확인하여 읽기 전용 트랜잭션이 비활성화되어 있는지 확인해야 합니다. 예를 들어:

```sql
# SHOW default_transaction_read_only;
 default_transaction_read_only
 -------------------------------
 on
(1 row)

# SHOW transaction_read_only;
 transaction_read_only
 -----------------------
 on
(1 row)
```

이 값 중 하나가 `on`로 설정되어 있으면 비활성화해야 합니다:

1. `postgresql.conf`을 편집하고 다음 값을 설정합니다:

   ```shell
   default_transaction_read_only=off
   ```

1. Postgres 서버를 다시 시작하여 이 설정을 적용합니다.
1. 필요한 경우 [데이터베이스 마이그레이션 적용](container_registry_metadata_database.md#apply-database-migrations)을 다시 시도합니다.
1. `sudo gitlab-ctl restart registry`을 실행하여 컨테이너 레지스트리를 다시 시작합니다.

### 오류: `cannot import all repositories while the tags table has entries` {#error-cannot-import-all-repositories-while-the-tags-table-has-entries}

[기존 컨테이너 레지스트리 메타데이터 가져오기](container_registry_metadata_database.md#enable-the-database-for-existing-registries)를 시도하고 다음 오류가 발생하면:

```shell
ERRO[0000] cannot import all repositories while the tags table has entries, you must truncate the table manually before retrying,
see https://docs.gitlab.com/administration/packages/container_registry_metadata_database/#troubleshooting
common_blobs=true dry_run=false error="tags table is not empty"
```

이 오류는 컨테이너 레지스트리 데이터베이스의 `tags` 테이블에 기존 항목이 있을 때 발생하며, 다음과 같은 경우에 발생할 수 있습니다:

- [1단계 가져오기](container_registry_metadata_database_one_step_import.md)를 시도했고 오류가 발생했습니다.
- [3단계 가져오기](container_registry_metadata_database_three_step_import.md) 프로세스를 시도했고 오류가 발생했습니다.
- 의도적으로 가져오기 프로세스를 중단했습니다.
- 이전 작업 중 하나 후에 다시 가져오기를 시도했습니다.
- 잘못된 구성 파일에 대해 가져오기를 실행했습니다.

이 문제를 해결하려면 태그 테이블에서 기존 항목을 삭제해야 합니다. PostgreSQL 인스턴스에서 테이블을 수동으로 자르려면:

1. `/etc/gitlab/gitlab.rb`을 편집하고 메타데이터 데이터베이스가 비활성화되어 있는지 확인합니다:

   ```ruby
   registry['database'] = {
     'enabled' => false,
   }
   ```

1. PostgreSQL 클라이언트를 사용하여 컨테이너 레지스트리 데이터베이스에 연결합니다.
1. `tags` 테이블을 자르고 기존 항목을 모두 제거합니다:

   ```sql
   TRUNCATE TABLE tags RESTART IDENTITY CASCADE;
   ```

1. `tags` 테이블을 자른 후 가져오기 프로세스를 다시 실행해 봅니다.

### 오류: `database-in-use lockfile exists` {#error-database-in-use-lockfile-exists}

[기존 컨테이너 레지스트리 메타데이터 가져오기](container_registry_metadata_database.md#enable-the-database-for-existing-registries)를 시도하고 다음 오류가 발생하면:

```shell
|  [0s] step two: import tags failed to import metadata: importing all repositories: 1 error occurred:
    * could not restore lockfiles: database-in-use lockfile exists
```

이 오류는 이전에 컨테이너 레지스트리를 가져왔고 모든 리포지토리 데이터(2단계) 가져오기를 완료했으며 `database-in-use`이 컨테이너 레지스트리 파일 시스템에 있을 때 발생합니다. 이 문제가 발생하면 임포터를 다시 실행하면 안 됩니다.

계속 진행해야 하면 파일 시스템에서 `database-in-use` 잠금 파일을 수동으로 삭제해야 합니다. 파일은 `/path/to/rootdirectory/docker/registry/lockfiles/database-in-use`에 있습니다.

### 오류: `pre importing all repositories: AccessDenied:` {#error-pre-importing-all-repositories-accessdenied}

[기존 컨테이너 레지스트리 가져오기](container_registry_metadata_database.md#enable-the-database-for-existing-registries)를 시도하고 AWS S3을 저장소 백엔드로 사용할 때 `AccessDenied` 오류가 발생할 수 있습니다:

```shell
/opt/gitlab/embedded/bin/registry database import --step-one /var/opt/gitlab/registry/config.yml
  [0s] step one: import manifests
  [0s] step one: import manifests failed to import metadata: pre importing all repositories: AccessDenied: Access Denied
```

명령을 실행하는 사용자가 올바른 [권한 범위](https://docker-docs.uclv.cu/registry/storage-drivers/s3/#s3-permission-scopes)를 가지고 있는지 확인합니다.

### 메타데이터 관리 문제로 인해 컨테이너 레지스트리가 시작되지 않음 {#registry-fails-to-start-due-to-metadata-management-issues}

컨테이너 레지스트리가 다음 오류 중 하나로 시작되지 않을 수 있습니다:

#### 오류: `registry filesystem metadata in use, please import data before enabling the database` {#error-registry-filesystem-metadata-in-use-please-import-data-before-enabling-the-database}

이 오류는 구성에서 데이터베이스가 활성화된 경우 발생하지만 아직 [기존 컨테이너 레지스트리 메타데이터를 가져오지](container_registry_metadata_database.md#enable-the-database-for-existing-registries) 않았습니다 `registry['database'] = { 'enabled' => true}`.

#### 오류: `registry metadata database in use, please enable the database` {#error-registry-metadata-database-in-use-please-enable-the-database}

이 오류는 [기존 컨테이너 레지스트리 메타데이터의 가져오기](container_registry_metadata_database.md#enable-the-database-for-existing-registries)를 메타데이터 데이터베이스에 완료했지만 구성에서 데이터베이스를 활성화하지 않았을 때 발생합니다.

#### 잠금 파일 확인 또는 생성 문제 {#problems-checking-or-creating-the-lock-files}

다음 오류 중 하나가 발생하면:

- `could not check if filesystem metadata is locked`
- `could not check if database metadata is locked`
- `failed to mark filesystem for database only usage`
- `failed to mark filesystem only usage`

컨테이너 레지스트리가 구성된 `rootdirectory`에 액세스할 수 없습니다. 이전에 작동하는 컨테이너 레지스트리가 있었다면 이 오류는 발생하지 않을 가능성이 높습니다. 구성 오류가 있는지 오류 로그를 검토합니다.

### 태그 삭제 후 저장소 사용량이 감소하지 않음 {#storage-usage-not-decreasing-after-deleting-tags}

기본적으로 온라인 가비지 컬렉터는 연결된 모든 태그가 삭제된 시간부터 48시간 후에만 참조되지 않은 계층 삭제를 시작합니다. 이 지연은 가비지 컬렉터가 장기 실행되거나 중단된 이미지 푸시에 방해가 되지 않도록 보장합니다. 계층은 컨테이너 레지스트리에 푸시되고 이미지 및 태그와 연결되기 때문입니다.

### 오류: `permission denied for schema public (SQLSTATE 42501)` {#error-permission-denied-for-schema-public-sqlstate-42501}

컨테이너 레지스트리 마이그레이션 또는 GitLab 업그레이드 중에 다음 오류 중 하나가 발생할 수 있습니다:

- `ERROR: permission denied for schema public (SQLSTATE 42501)`
- `ERROR: relation "public.blobs" does not exist (SQLSTATE 42P01)`

이러한 유형의 오류는 보안상의 이유로 공개 스키마에 대한 기본 CREATE 권한을 제거하는 PostgreSQL 15+의 변경으로 인해 발생합니다. 기본적으로 PostgreSQL 15+의 공개 스키마에서는 데이터베이스 소유자만 개체를 만들 수 있습니다.

오류를 해결하려면 다음 명령을 실행하여 컨테이너 레지스트리 데이터베이스의 컨테이너 레지스트리 사용자 소유자 권한을 부여합니다:

```sql
ALTER DATABASE <registry_database_name> OWNER TO <registry_user>;
```

이렇게 하면 컨테이너 레지스트리 사용자에게 테이블을 만들고 마이그레이션을 성공적으로 실행할 수 있는 필요한 권한이 제공됩니다.

### 오류: `database-in-use and filesystem-in-use lockfiles present` {#error-database-in-use-and-filesystem-in-use-lockfiles-present}

이 오류는 `filesystem-in-use`과 `database-in-use` 잠금 파일이 모두 구성된 컨테이너 레지스트리 저장소에 있고 모호한 컨테이너 레지스트리 상태를 나타낼 때 발생합니다.

이 오류를 해결하려면 컨테이너 레지스트리가 메타데이터 데이터베이스를 사용할 것인지 아니면 레거시 메타데이터 저장소를 사용할 것인지 결정해야 합니다.

컨테이너 레지스트리가 메타데이터 데이터베이스를 사용할 가능성이 높은 경우:

- 이전에 [기능 플래그 프로세스](container_registry_metadata_database.md#choose-the-right-import-method) 중 하나를 수행했습니다.
- 컨테이너 레지스트리 구성에 컨테이너 레지스트리가 활성화되어 있음을 나타냅니다.

`/etc/gitlab/gitlab.rb`의 파일을 확인하여 컨테이너 레지스트리가 활성화되었는지 확인합니다:

```ruby
registry['database'] = {
  'enabled' => true,
}
```

컨테이너 레지스트리가 데이터베이스를 사용할 것으로 확인되면 `/docker/registry/lockfiles/filesystem-in-use`에 있는 구성된 컨테이너 레지스트리 저장소에 있는 `filesystem-in-use` 잠금 파일을 삭제합니다.

또는 위의 시나리오가 참이 아니고 컨테이너 레지스트리가 레거시 메타데이터 저장소를 사용하기로 한 경우 `/docker/registry/lockfiles/database-in-use`에서 `database-in-use` 잠금 파일을 삭제합니다.

GitLab 18.8 및 18.9의 경우 `REGISTRY_FF_ENFORCE_LOCKFILES` 컨테이너 레지스트리 기능 플래그를 `false`로 설정하여 잠금 파일 검사를 비활성화할 수 있습니다. 검사를 비활성화하는 동안 이 오류는 컨테이너 레지스트리 데이터의 무결성을 보장하기 위한 것이며 사용 중인 메타데이터 저장소를 확인하는 것이 좋습니다. `REGISTRY_FF_ENFORCE_LOCKFILES` 기능 플래그는 GitLab 18.10에서 제거되었습니다. 자세한 내용은 [컨테이너 레지스트리 기능 플래그](container_registry.md#container-registry-feature-flags)를 참조하세요.
