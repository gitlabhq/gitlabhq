---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
title: Geo와 Object Storage
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

{{< history >}}

- Object Storage에 저장된 파일의 검증이 GitLab 16.4에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/8056) 되었으며 [기능 플래그](../../feature_flags/_index.md) `geo_object_storage_verification`를 사용합니다. 기본적으로 활성화됨.

{{< /history >}}

Geo는 Object Storage(AWS S3 또는 기타 호환 객체 스토리지)와 함께 사용할 수 있습니다.

**세컨더리** 사이트는 다음 중 하나를 사용할 수 있습니다:

- **프라이머리** 사이트와 동일한 스토리지 버킷입니다.
- 복제된 스토리지 버킷입니다.
- 프라이머리가 로컬 스토리지를 사용하는 경우 로컬 스토리지입니다.

파일의 스토리지 방법(로컬 또는 객체 스토리지)은 데이터베이스에 기록되며, 데이터베이스는 **프라이머리** Geo 사이트에서 **세컨더리** Geo 사이트로 복제됩니다.

업로드된 객체에 액세스할 때 데이터베이스에서 스토리지 방법(로컬 또는 객체 스토리지)을 가져오므로, **세컨더리** Geo 사이트는 **프라이머리** Geo 사이트의 스토리지 방법과 일치해야 합니다.

따라서 **프라이머리** Geo 사이트가 객체 스토리지를 사용하면 **세컨더리** Geo 사이트도 사용해야 합니다.

다음을 수행하려면:

- GitLab에서 복제를 관리하도록 하려면 [GitLab 복제 활성화](#enabling-gitlab-managed-object-storage-replication)를 따르세요.
- 타사 서비스에서 복제를 관리하도록 하려면 [타사 복제 서비스](#third-party-replication-services)를 따르세요.

[GitLab과 함께 객체 스토리지 사용에 대해 자세히 알아보기](../../object_storage.md)

## Object Storage 검증 {#object-storage-verification}

Geo는 Object Storage에 저장된 파일을 검증하여 프라이머리와 세컨더리 사이트 간의 데이터 무결성을 보장합니다.

> [!warning]
> Object Storage 검증을 비활성화하는 것은 권장되지 않습니다. `geo_object_storage_verification` 기능 플래그를 비활성화하면 GitLab은 모든 기존 검증 상태 기록을 비동기적으로 삭제합니다.

`geo_object_storage_verification` 기능 플래그가 비활성화되면:

- Geo 검증 워커(`Geo::VerificationBatchWorker`)는 여전히 Sidekiq 로그에 나타날 수 있지만 검증은 수행되지 않습니다.
- 검증 기록 정리 중에 워커가 큐에 추가되어 남은 기록을 처리할 수 있습니다.

## GitLab 관리 객체 스토리지 복제 활성화 {#enabling-gitlab-managed-object-storage-replication}

{{< history >}}

- [GitLab 15.1에서 도입](https://gitlab.com/groups/gitlab-org/-/epics/5551)되었습니다.

{{< /history >}}

> [!warning]
> 문제가 발생한 경우 개별 파일을 수동으로 삭제하는 것을 피하세요. 이는 [데이터 불일치](#inconsistencies-after-the-migration)로 이어질 수 있습니다.

**세컨더리** 사이트는 **프라이머리** 사이트에서 저장한 파일을 로컬 파일 시스템에 저장되거나 객체 스토리지에 저장되어 있는지에 관계없이 복제할 수 있습니다.

GitLab 복제를 활성화하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **Geo** > **사이트**를 선택합니다.
1. **세컨더리** 사이트에서 **편집**을 선택합니다.
1. **Synchronization Settings** 섹션에서 **이 세컨더리 사이트가 Object Stroage에 콘텐츠를 복제하도록 허용** 확인란을 찾아 활성화합니다.

LFS의 경우 [LFS 객체 스토리지 설정](../../lfs/_index.md#storing-lfs-objects-in-remote-object-storage) 설명서를 따르세요.

CI 작업 아티팩트의 경우 [작업 아티팩트 객체 스토리지 구성](../../cicd/job_artifacts.md#using-object-storage) 설명서가 있습니다.

사용자 업로드의 경우 [업로드 객체 스토리지 구성](../../uploads.md#using-object-storage) 설명서가 있습니다.

**프라이머리** 사이트의 파일을 객체 스토리지로 마이그레이션하려면 **세컨더리**를 다음과 같은 방식으로 구성할 수 있습니다:

- 정확히 동일한 객체 스토리지를 사용합니다.
- 별도의 객체 스토어를 사용하지만 객체 스토리지 솔루션의 기본 제공 복제를 활용합니다.
- 별도의 객체 스토어를 사용하고 **이 세컨더리 사이트가 Object Stroage에 콘텐츠를 복제하도록 허용** 설정을 활성화합니다.

**이 세컨더리 사이트가 Object Stroage에 콘텐츠를 복제하도록 허용** 설정이 비활성화되어 있고 모든 파일을 로컬 스토리지에서 객체 스토리지로 마이그레이션한 경우, **운영자** > **Geo** > **사이트** 진행률 표시줄이 많이 **동기화할 항목 없음**을 표시합니다.

> [!warning]
> 데이터 손실을 방지하려면 프라이머리와 세컨더리 사이트에 대해 별도의 객체 스토어를 사용하는 경우에만 **이 세컨더리 사이트가 Object Stroage에 콘텐츠를 복제하도록 허용** 설정을 활성화해야 합니다.

GitLab은 다음 두 가지 모두에 해당하는 경우를 지원하지 않습니다:

- **프라이머리** 사이트가 로컬 스토리지를 사용합니다.
- **세컨더리** 사이트가 객체 스토리지를 사용합니다.

### 마이그레이션 후 불일치 {#inconsistencies-after-the-migration}

로컬에서 객체 스토리지로 마이그레이션할 때 데이터 불일치가 발생할 수 있으며, 이는 [객체 스토리지 문제 해결 섹션](../../object_storage.md#inconsistencies-after-migrating-to-object-storage)에서 자세히 설명됩니다.

## 타사 복제 서비스 {#third-party-replication-services}

Amazon S3를 사용할 때 [교차 지역 복제(CRR)](https://docs.aws.amazon.com/AmazonS3/latest/dev/crr.html)를 사용하여 **프라이머리** 사이트에서 사용하는 버킷과 **세컨더리** 사이트에서 사용하는 버킷 간에 자동 복제를 수행할 수 있습니다.

Google Cloud Storage를 사용하는 경우 [다중 지역 스토리지](https://cloud.google.com/storage/docs/storage-classes#multi-regional) 사용을 고려하세요. 또는 [스토리지 전송 서비스](https://cloud.google.com/storage-transfer/docs/overview)를 사용할 수 있지만, 이는 일일 동기화만 지원합니다.

수동 동기화 또는 `cron`에서 예약된 경우 다음을 참조하세요:

- [`s3cmd sync`](https://s3tools.org/s3cmd-sync)
- [`gsutil rsync`](https://cloud.google.com/storage/docs/gsutil/commands/rsync)
