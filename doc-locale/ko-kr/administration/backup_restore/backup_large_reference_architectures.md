---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 대규모 참조 아키텍처 백업 및 복원
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab 백업은 데이터 일관성을 보존하고 대규모 GitLab 배포에서 재해 복구를 가능하게 합니다. 이 프로세스는:

- 분산 저장소 구성 요소 전체에서 데이터 백업을 조정합니다.
- 여러 테라바이트 크기의 PostgreSQL 데이터베이스를 보존합니다.
- 외부 서비스의 객체 저장소 데이터를 보호합니다.
- 대규모 Git 리포지토리 컬렉션에 대한 백업 무결성을 유지합니다.
- 구성 및 비밀 파일의 복구 가능한 복사본을 생성합니다.
- 최소 가동 중지 시간으로 시스템 데이터의 복원을 가능하게 합니다.

3,000명 이상의 사용자를 지원하는 참조 아키텍처를 실행하는 GitLab 환경에 대한 이러한 절차를 따르고, 클라우드 기반 데이터베이스 및 객체 저장소에 대한 특별한 고려 사항을 적용합니다.

> [!note]
> 이 문서는 다음을 사용하는 환경을 위한 것입니다:
>
> - [Linux 패키지(Omnibus) 및 클라우드 네이티브 하이브리드 참조 아키텍처 60 RPS / 3,000명 이상의 사용자](../reference_architectures/_index.md)
> - [Amazon RDS](https://aws.amazon.com/rds/)(PostgreSQL 데이터용)
> - [Amazon S3](https://aws.amazon.com/s3/)(객체 저장소용)
> - [객체 저장소](../object_storage.md) 에서 [Blob](backup_gitlab.md#blobs) 및 [컨테이너 레지스트리](backup_gitlab.md#container-registry)를 포함하여 가능한 모든 것을 저장합니다.

## 일일 백업 구성 {#configure-daily-backups}

### PostgreSQL 데이터 백업 구성 {#configure-backup-of-postgresql-data}

[백업 명령](backup_gitlab.md)은 `pg_dump`을 사용하는데, 이는 [100GB 이상의 데이터베이스에는 적합하지 않습니다](backup_gitlab.md#postgresql-databases). 네이티브이고 강력한 백업 기능이 있는 PostgreSQL 솔루션을 선택해야 합니다.

{{< tabs >}}

{{< tab title="AWS" >}}

1. [AWS Backup 구성](https://docs.aws.amazon.com/aws-backup/latest/devguide/creating-a-backup-plan.html)을 통해 RDS(및 S3) 데이터를 백업합니다. 최대 보호를 위해 [지속적 백업과 스냅샷 백업을 모두 구성](https://docs.aws.amazon.com/aws-backup/latest/devguide/point-in-time-recovery.html)합니다.
1. AWS Backup을 구성하여 백업을 별도 지역으로 복사합니다. AWS가 백업을 수행할 때, 백업은 백업이 저장된 지역에서만 복원할 수 있습니다.
1. AWS Backup이 예약된 백업을 적어도 한 번 실행한 후에는 필요에 따라 [주문형 백업을 생성](https://docs.aws.amazon.com/aws-backup/latest/devguide/recov-point-create-on-demand-backup.html)할 수 있습니다.

{{< /tab >}}

{{< tab title="Google" >}}

[Google Cloud SQL 데이터의 자동 일일 백업을 예약](https://cloud.google.com/sql/docs/postgres/backup-recovery/backing-up#schedulebackups)합니다. 일일 백업은 [최대 1년까지 보유](https://cloud.google.com/sql/docs/postgres/backup-recovery/backups#retention)할 수 있으며, 포인트 인 타임 복구를 위해 기본적으로 트랜잭션 로그를 7일 동안 보유할 수 있습니다.

{{< /tab >}}

{{< /tabs >}}

### 객체 저장소 데이터 백업 구성 {#configure-backup-of-object-storage-data}

[객체 저장소](../object_storage.md) ([NFS 제외](../nfs.md) )는 [블롭](backup_gitlab.md#blobs) 및 [컨테이너 레지스트리](backup_gitlab.md#container-registry)를 포함하여 GitLab 데이터를 저장하는 데 권장됩니다.

{{< tabs >}}

{{< tab title="AWS" >}}

AWS Backup을 구성하여 S3 데이터를 백업합니다. 이는 [PostgreSQL 데이터 백업 구성](#configure-backup-of-postgresql-data) 중일 때 동시에 수행할 수 있습니다.

{{< /tab >}}

{{< tab title="Google" >}}

1. [GCS에서 백업 버킷 생성](https://cloud.google.com/storage/docs/creating-buckets)합니다.
1. [Storage Transfer Service 작업을 생성](https://cloud.google.com/storage-transfer/docs/create-transfers)하여 각 GitLab 객체 저장소 버킷을 백업 버킷으로 복사합니다. 이 작업을 한 번 생성한 후 [매일 실행하도록 예약](https://cloud.google.com/storage-transfer/docs/schedule-transfer-jobs)할 수 있습니다. 그러나 이는 새로운 객체 저장소 데이터와 이전 객체 저장소 데이터를 혼합하므로 GitLab에서 삭제된 파일이 백업에 여전히 존재합니다. 이는 복원 후 저장소를 낭비하지만 그 외에는 문제가 아닙니다. GitLab 데이터베이스에 존재하지 않으므로 이러한 파일은 GitLab 사용자가 액세스할 수 없습니다. 복원 후 [이러한 고아 파일 중 일부를 삭제](../raketasks/cleanup.md#clean-up-project-upload-files-from-object-storage)할 수 있지만, 이 정리 Rake 작업은 파일 부분 집합에서만 작동합니다.
   1. `When to overwrite`의 경우 `Never`를 선택합니다. GitLab 객체 저장 파일은 변경 불가능하도록 되어 있습니다. 악의적인 행위자가 GitLab 파일을 변경하는 데 성공한 경우 이 선택이 도움이 될 수 있습니다.
   1. `When to delete`의 경우 `Never`를 선택합니다. 백업 버킷을 소스로 동기화하는 경우 소스에서 파일이 실수로 또는 악의적으로 삭제되었을 때 복구할 수 없습니다.
1. 또는 객체 저장소를 일별로 분리된 버킷 또는 하위 디렉터리로 백업할 수 있습니다. 이는 복원 후 고아 파일 문제를 피하고 필요한 경우 파일 버전의 백업을 지원합니다. 하지만 백업 저장소 비용이 크게 증가합니다. 이는 [Cloud Scheduler로 트리거된 Cloud Function](https://cloud.google.com/scheduler/docs/tut-gcf-pub-sub)을 사용하거나 cronjob으로 실행되는 스크립트를 사용하여 수행할 수 있습니다. 부분 예제:

   ```shell
   # Set GCP project so you don't have to specify it in every command
   gcloud config set project example-gcp-project-name

   # Grant the Storage Transfer Service's hidden service account permission to write to the backup bucket. The integer 123456789012 is the GCP project's ID.
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.objectAdmin gs://backup-bucket

   # Grant the Storage Transfer Service's hidden service account permission to list and read objects in the source buckets. The integer 123456789012 is the GCP project's ID.
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-artifacts
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-ci-secure-files
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-dependency-proxy
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-lfs
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-mr-diffs
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-packages
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-pages
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-registry
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-terraform-state
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-uploads

   # Create transfer jobs for each bucket, targeting a subdirectory in the backup bucket.
   today=$(date +%F)
   gcloud transfer jobs create gs://gitlab-bucket-artifacts/ gs://backup-bucket/$today/artifacts/ --name "$today-backup-artifacts"
   gcloud transfer jobs create gs://gitlab-bucket-ci-secure-files/ gs://backup-bucket/$today/ci-secure-files/ --name "$today-backup-ci-secure-files"
   gcloud transfer jobs create gs://gitlab-bucket-dependency-proxy/ gs://backup-bucket/$today/dependency-proxy/ --name "$today-backup-dependency-proxy"
   gcloud transfer jobs create gs://gitlab-bucket-lfs/ gs://backup-bucket/$today/lfs/ --name "$today-backup-lfs"
   gcloud transfer jobs create gs://gitlab-bucket-mr-diffs/ gs://backup-bucket/$today/mr-diffs/ --name "$today-backup-mr-diffs"
   gcloud transfer jobs create gs://gitlab-bucket-packages/ gs://backup-bucket/$today/packages/ --name "$today-backup-packages"
   gcloud transfer jobs create gs://gitlab-bucket-pages/ gs://backup-bucket/$today/pages/ --name "$today-backup-pages"
   gcloud transfer jobs create gs://gitlab-bucket-registry/ gs://backup-bucket/$today/registry/ --name "$today-backup-registry"
   gcloud transfer jobs create gs://gitlab-bucket-terraform-state/ gs://backup-bucket/$today/terraform-state/ --name "$today-backup-terraform-state"
   gcloud transfer jobs create gs://gitlab-bucket-uploads/ gs://backup-bucket/$today/uploads/ --name "$today-backup-uploads"
   ```

   1. 이러한 Transfer Job은 실행 후 자동으로 삭제되지 않습니다. 스크립트에서 이전 작업의 정리를 구현할 수 있습니다.
   1. 예제 스크립트는 이전 백업을 삭제하지 않습니다. 원하는 보존 정책에 따라 이전 백업의 정리를 구현할 수 있습니다.
1. 백업이 Cloud SQL 백업과 동일한 시간 또는 이후에 수행되도록 하여 데이터 불일치를 줄입니다.

{{< /tab >}}

{{< /tabs >}}

### Git 리포지토리 백업 구성 {#configure-backup-of-git-repositories}

Gitaly 서버 측 백업을 수행하도록 cronjob을 설정합니다:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. 모든 Gitaly 노드에서 [서버 측 백업 구성](../gitaly/configure_gitaly.md#configure-server-side-backups)을 따라 Gitaly 서버 측 백업 대상을 구성합니다. 이 버킷은 리포지토리 데이터를 저장하기 위해 Gitaly에서만 독점적으로 사용됩니다.
1. Gitaly가 이전에 구성된 지정된 객체 저장소 버킷에서 모든 Git 리포지토리 데이터를 백업하는 동안, 백업 유틸리티 도구(`gitlab-backup`)는 추가 백업 데이터를 업로드합니다. 이 데이터는 복원을 위한 필수 메타데이터를 포함하는 `tar` 파일을 포함합니다. 다른 백업과 동일한 버킷을 사용하거나 별도의 버킷을 사용할 수 있습니다. [백업을 원격(클라우드) 저장소로 업로드](backup_gitlab.md#upload-backups-to-a-remote-cloud-storage)를 따라 이 백업 데이터가 원격(클라우드) 저장소에 제대로 업로드되도록 하여 업로드 버킷을 설정합니다.
1. (선택 사항) 이 백업 데이터의 내구성을 강화하려면 [객체 저장소 데이터 백업](#configure-backup-of-object-storage-data)에 추가하여 이전에 구성된 모든 버킷을 각 객체 저장소 공급자로 백업합니다.
1. Puma 또는 Sidekiq을 실행하는 노드인 GitLab Rails 노드로 SSH를 연결합니다.
1. Git 데이터의 전체 백업을 수행합니다. `REPOSITORIES_SERVER_SIDE` 변수를 사용하고 PostgreSQL 데이터를 건너뜁니다:

   ```shell
   sudo gitlab-backup create REPOSITORIES_SERVER_SIDE=true SKIP=db
   ```

   이는 Gitaly 노드가 Git 데이터와 일부 메타데이터를 원격 저장소로 업로드하도록 합니다. 업로드, 아티팩트 및 LFS와 같은 Blob은 `gitlab-backup` 명령이 기본적으로 객체 저장소를 백업하지 않으므로 명시적으로 건너뛸 필요가 없습니다.

1. 다음 단계에 필요한 백업의 [백업 ID](backup_archive_process.md#backup-id)를 기록합니다. 예를 들어, 백업 명령이 `2024-02-22 02:17:47 UTC -- Backup 1708568263_2024_02_22_16.9.0-ce is done.`를 출력하는 경우 백업 ID는 `1708568263_2024_02_22_16.9.0-ce`입니다.
1. 전체 백업이 Gitaly 백업 버킷과 일반 백업 버킷 모두에 데이터를 생성했는지 확인합니다.
1. [백업 명령](backup_gitlab.md#backup-command) 을 다시 실행하여 이번에는 [Git 리포지토리 증분 백업](backup_gitlab.md#incremental-repository-backups)을 지정하고 백업 ID를 지정합니다. 이전 단계의 예제 ID를 사용하면 명령은:

   ```shell
   sudo gitlab-backup create REPOSITORIES_SERVER_SIDE=true SKIP=db INCREMENTAL=yes PREVIOUS_BACKUP=1708568263_2024_02_22_16.9.0-ce
   ```

   `PREVIOUS_BACKUP`의 값은 이 명령에서 사용되지 않지만 명령에 필요합니다. 이 불필요한 요구 사항을 제거하기 위한 이슈가 있으며, [이슈 429141](https://gitlab.com/gitlab-org/gitlab/-/issues/429141)을 참조하세요.

1. 증분 백업이 성공했으며 객체 저장소에 데이터를 추가했는지 확인합니다.
1. [일일 백업을 수행하도록 cron 구성](backup_gitlab.md#configuring-cron-to-make-daily-backups)합니다. `root` 사용자의 crontab을 편집합니다:

   ```shell
   sudo su -
   crontab -e
   ```

1. 다음 줄을 추가하여 매달 매일 오전 2시에 백업을 예약합니다. 백업을 복원하는 데 필요한 증분 수를 제한하기 위해 매달 1일에는 Git 리포지토리의 전체 백업을 수행하고 나머지 날에는 증분 백업을 수행합니다.:

   ```plaintext
   0 2 1 * * /opt/gitlab/bin/gitlab-backup create REPOSITORIES_SERVER_SIDE=true SKIP=db CRON=1
   0 2 2-31 * * /opt/gitlab/bin/gitlab-backup create REPOSITORIES_SERVER_SIDE=true SKIP=db INCREMENTAL=yes PREVIOUS_BACKUP=1708568263_2024_02_22_16.9.0-ce CRON=1
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. 모든 Gitaly 노드에서 [서버 측 백업 구성](../gitaly/configure_gitaly.md#configure-server-side-backups)을 따라 Gitaly 서버 측 백업 대상을 구성합니다. 이 버킷은 리포지토리 데이터를 저장하기 위해 Gitaly에서만 독점적으로 사용됩니다.
1. Gitaly가 이전에 구성된 지정된 객체 저장소 버킷에서 모든 Git 리포지토리 데이터를 백업하는 동안, 백업 유틸리티 도구(`gitlab-backup`)는 추가 백업 데이터를 업로드합니다. 이 데이터는 복원을 위한 필수 메타데이터를 포함하는 `tar` 파일을 포함합니다. 다른 백업과 동일한 버킷을 사용하거나 별도의 버킷을 사용할 수 있습니다. [백업을 원격(클라우드) 저장소로 업로드](backup_gitlab.md#upload-backups-to-a-remote-cloud-storage)를 따라 이 백업 데이터가 원격(클라우드) 저장소에 제대로 업로드되도록 하여 업로드 버킷을 설정합니다.
1. (선택 사항) 이 백업 데이터의 내구성을 강화하려면 [객체 저장소 데이터 백업](#configure-backup-of-object-storage-data)에 추가하여 이전에 구성된 모든 버킷을 각 객체 저장소 공급자로 백업할 수 있습니다.
1. Puma 또는 Sidekiq을 실행하는 노드인 GitLab Rails 노드로 SSH를 연결합니다.
1. Git 데이터의 전체 백업을 수행합니다. `REPOSITORIES_SERVER_SIDE` 변수를 사용하고 다른 모든 데이터를 건너뜁니다:

   ```shell
   kubectl exec <Toolbox pod name> -it -- backup-utility --repositories-server-side --skip db,builds,pages,registry,uploads,artifacts,lfs,packages,external_diffs,terraform_state,pages,ci_secure_files
   ```

   이는 Gitaly 노드가 Git 데이터와 일부 메타데이터를 원격 저장소로 업로드하도록 합니다. [Toolbox 포함 도구](https://docs.gitlab.com/charts/charts/gitlab/toolbox/#toolbox-included-tools)를 참조하세요.

1. 전체 백업이 Gitaly 백업 버킷과 일반 백업 버킷 모두에 데이터를 생성했는지 확인합니다. 증분 리포지토리 백업은 서버 측 리포지토리 백업이 있는 `backup-utility`에서 지원되지 않으며, [차트 이슈 3421](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3421)을 참조하세요.
1. [일일 백업을 수행하도록 cron 구성](https://docs.gitlab.com/charts/backup-restore/backup/#cron-based-backup)합니다. 구체적으로, `gitlab.toolbox.backups.cron.extraArgs`을 다음을 포함하도록 설정합니다:

   ```shell
   --repositories-server-side --skip db --skip repositories --skip uploads --skip builds --skip artifacts --skip pages --skip lfs --skip terraform_state --skip registry --skip packages --skip ci_secure_files
   ```

{{< /tab >}}

{{< /tabs >}}

### 구성 파일 백업 구성 {#configure-backup-of-configuration-files}

구성 및 비밀이 배포 외부에서 정의되고 이후에 배포로 배포되는 경우 백업 전략의 구현은 특정 설정 및 요구 사항에 따라 달라집니다. 예를 들어 [AWS Secret Manager](https://aws.amazon.com/secrets-manager/) 에 비밀을 저장하고 [여러 지역으로 복제](https://docs.aws.amazon.com/secretsmanager/latest/userguide/create-manage-multi-region-secrets.html)한 후 비밀을 자동으로 백업하도록 스크립트를 구성할 수 있습니다.

구성 및 비밀이 배포 내부에서만 정의되는 경우:

1. [구성 파일 저장](backup_gitlab.md#storing-configuration-files)은 구성 및 비밀 파일을 추출하는 방법을 설명합니다.
1. 이 파일은 별도의 제한적인 객체 저장소 계정으로 업로드해야 합니다.

## 백업 복원 {#restore-a-backup}

GitLab 인스턴스의 백업을 복원합니다.

### 필수 요구 사항 {#prerequisites}

백업을 복원하기 전에:

1. [작동하는 대상 GitLab 인스턴스](restore_gitlab.md#the-destination-gitlab-instance-must-already-be-working)를 선택합니다.
1. 대상 GitLab 인스턴스가 AWS 백업이 저장된 지역에 있는지 확인합니다.
1. [대상 GitLab 인스턴스가 백업 데이터가 생성된 것과 정확히 동일한 버전 및 유형(CE 또는 EE)의 GitLab을 사용](restore_gitlab.md#the-destination-gitlab-instance-must-have-the-exact-same-version)하는지 확인합니다. 예를 들어 CE 15.1.4입니다.
1. [백업된 비밀을 대상 GitLab 인스턴스로 복원](restore_gitlab.md#gitlab-secrets-must-be-restored)합니다.
1. 대상 GitLab 인스턴스에 [동일한 리포지토리 저장소가 구성되어](restore_gitlab.md#certain-gitlab-configuration-must-match-the-original-backed-up-environment) 있는지 확인합니다. 추가 저장소는 괜찮습니다.
1. [객체 저장소가 구성되어](restore_gitlab.md#certain-gitlab-configuration-must-match-the-original-backed-up-environment) 있는지 확인합니다.
1. 새 비밀 또는 구성을 사용하고 복원 중에 예상치 못한 구성 변경을 처리하지 않으려면:

   - 모든 노드에 대한 Linux 패키지 설치:
     1. 대상 GitLab 인스턴스를 [다시 구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.
     1. 대상 GitLab 인스턴스를 [다시 시작](../restart_gitlab.md#restart-a-linux-package-installation)합니다.

   - Helm 차트(Kubernetes) 설치:

     1. 모든 GitLab Linux 패키지 노드에서 다음을 실행합니다:

        ```shell
        sudo gitlab-ctl reconfigure
        sudo gitlab-ctl start
        ```

     1. 차트를 배포하여 실행 중인 GitLab 인스턴스를 보유하고 있는지 확인합니다. 다음 명령을 실행하여 Toolbox pod가 활성화되고 실행 중인지 확인합니다:

        ```shell
        kubectl get pods -lrelease=RELEASE_NAME,app=toolbox
        ```

     1. Webservice, Sidekiq 및 Toolbox pod를 다시 시작해야 합니다. 이러한 pod를 다시 시작하는 가장 안전한 방법은 다음을 실행하는 것입니다:

        ```shell
        kubectl delete pods -lapp=sidekiq,release=<helm release name>
        kubectl delete pods -lapp=webservice,release=<helm release name>
        kubectl delete pods -lapp=toolbox,release=<helm release name>
        ```

1. 대상 GitLab 인스턴스가 여전히 작동하는지 확인합니다. 예를 들어:

   - [상태 확인 끝점](../monitoring/health_check.md)에 요청을 만듭니다.
   - [GitLab 확인 Rake 작업 실행](../raketasks/maintenance.md#check-gitlab-configuration)합니다.

1. PostgreSQL 데이터베이스에 연결하는 GitLab 서비스를 중지합니다.

   - Puma 또는 Sidekiq을 실행하는 모든 노드에서 Linux 패키지 설치를 실행합니다:

     ```shell
     sudo gitlab-ctl stop
     ```

   - Helm 차트(Kubernetes) 설치:

     1. 이후 다시 시작을 위해 데이터베이스 클라이언트의 현재 복제본 수를 기록합니다:

        ```shell
        kubectl get deploy -n <namespace> -lapp=sidekiq,release=<helm release name> -o jsonpath='{.items[].spec.replicas}{"\n"}'
        kubectl get deploy -n <namespace> -lapp=webservice,release=<helm release name> -o jsonpath='{.items[].spec.replicas}{"\n"}'
        kubectl get deploy -n <namespace> -lapp=prometheus,release=<helm release name> -o jsonpath='{.items[].spec.replicas}{"\n"}'
        ```

     1. 복원 프로세스에 방해가 되는 잠금을 방지하기 위해 데이터베이스의 클라이언트를 중지합니다:

        ```shell
        kubectl scale deploy -lapp=sidekiq,release=<helm release name> -n <namespace> --replicas=0
        kubectl scale deploy -lapp=webservice,release=<helm release name> -n <namespace> --replicas=0
        kubectl scale deploy -lapp=prometheus,release=<helm release name> -n <namespace> --replicas=0
        ```

### 객체 저장소 데이터 복원 {#restore-object-storage-data}

{{< tabs >}}

{{< tab title="AWS" >}}

각 버킷은 AWS 내에서 별도의 백업으로 존재하며 각 백업을 기존 또는 새 버킷으로 복원할 수 있습니다.

1. 버킷을 복원하려면 올바른 권한이 있는 IAM 역할이 필요합니다:

   - `AWSBackupServiceRolePolicyForBackup`
   - `AWSBackupServiceRolePolicyForRestores`
   - `AWSBackupServiceRolePolicyForS3Restore`
   - `AWSBackupServiceRolePolicyForS3Backup`

1. 기존 버킷을 사용하는 경우 [액세스 제어 목록을 활성화](https://docs.aws.amazon.com/AmazonS3/latest/userguide/managing-acls.html)해야 합니다.
1. [기본 제공 도구를 사용하여 S3 버킷 복원](https://docs.aws.amazon.com/aws-backup/latest/devguide/restoring-s3.html)합니다.
1. 복원 작업이 실행되는 동안 [PostgreSQL 데이터 복원](#restore-postgresql-data)으로 이동할 수 있습니다.

{{< /tab >}}

{{< tab title="Google" >}}

1. [Storage Transfer Service 작업 생성](https://cloud.google.com/storage-transfer/docs/create-transfers)하여 백업된 데이터를 GitLab 버킷으로 전송합니다.
1. 전송 작업이 실행되는 동안 [PostgreSQL 데이터 복원](#restore-postgresql-data)으로 이동할 수 있습니다.

{{< /tab >}}

{{< /tabs >}}

### PostgreSQL 데이터 복원 {#restore-postgresql-data}

{{< tabs >}}

{{< tab title="AWS" >}}

1. [기본 제공 도구를 사용하여 AWS RDS 데이터베이스 복원](https://docs.aws.amazon.com/aws-backup/latest/devguide/restoring-rds.html)하면 새 RDS 인스턴스가 생성됩니다.
1. 새 RDS 인스턴스에는 다른 엔드포인트가 있으므로 새 데이터베이스를 가리키도록 대상 GitLab 인스턴스를 다시 구성해야 합니다:

   - Linux 패키지 설치의 경우 [패키지되지 않은 PostgreSQL 데이터베이스 관리 서버 사용](https://docs.gitlab.com/omnibus/settings/database/#using-a-non-packaged-postgresql-database-management-server)을 따릅니다.

   - Helm 차트(Kubernetes) 설치의 경우 [외부 데이터베이스를 사용하여 GitLab 차트 구성](https://docs.gitlab.com/charts/advanced/external-db/)을 따릅니다.

1. 다음으로 이동하기 전에 새 RDS 인스턴스가 생성되고 사용할 준비가 될 때까지 기다립니다.

{{< /tab >}}

{{< tab title="Google" >}}

1. [기본 제공 도구를 사용하여 Google Cloud SQL 데이터베이스 복원](https://cloud.google.com/sql/docs/postgres/backup-recovery/restoring)합니다.
1. 새 데이터베이스 인스턴스로 복원하는 경우 새 데이터베이스를 가리키도록 GitLab을 다시 구성합니다:

   - Linux 패키지 설치의 경우 [패키지되지 않은 PostgreSQL 데이터베이스 관리 서버 사용](https://docs.gitlab.com/omnibus/settings/database/#using-a-non-packaged-postgresql-database-management-server)을 따릅니다.

   - Helm 차트(Kubernetes) 설치의 경우 [외부 데이터베이스를 사용하여 GitLab 차트 구성](https://docs.gitlab.com/charts/advanced/external-db/)을 따릅니다.

1. 다음으로 이동하기 전에 Cloud SQL 인스턴스가 사용할 준비가 될 때까지 기다립니다.

{{< /tab >}}

{{< /tabs >}}

### Git 리포지토리 복원 {#restore-git-repositories}

[객체 저장소 데이터 복원](#restore-object-storage-data)의 일부로서 다음을 이미 수행했어야 합니다:

- Git 리포지토리의 Gitaly 서버 측 백업이 포함된 버킷을 복원했습니다.
- `*_gitlab_backup.tar` 파일이 포함된 버킷을 복원했습니다.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Puma 또는 Sidekiq을 실행하는 노드인 GitLab Rails 노드로 SSH를 연결합니다.
1. 백업 버킷에서 타임스탬프를 기반으로 `*_gitlab_backup.tar` 파일을 선택하여 복원한 PostgreSQL 및 객체 저장소 데이터와 정렬합니다.
1. `tar` 파일을 `/var/opt/gitlab/backups/`에 다운로드합니다.
1. 복원할 백업의 ID를 지정하여 백업을 복원하고 이름에서 `_gitlab_backup.tar`을 생략합니다:

   ```shell
   # This command will overwrite the contents of your GitLab database!
   sudo gitlab-backup restore BACKUP=11493107454_2018_04_25_10.6.4-ce SKIP=db
   ```

   백업 tar 파일과 설치된 GitLab 버전 사이에 GitLab 버전 불일치가 있는 경우 복원 명령이 오류 메시지로 중단됩니다. [올바른 GitLab 버전](https://packages.gitlab.com/ui/browse/gitlab)을 설치한 후 다시 시도합니다.

1. 다시 구성하고, 시작하고, GitLab을 [확인](../raketasks/maintenance.md#check-gitlab-configuration)합니다:

   1. 모든 PostgreSQL 노드에서 다음을 실행합니다:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

   1. 모든 Puma 또는 Sidekiq 노드에서 다음을 실행합니다:

      ```shell
      sudo gitlab-ctl start
      ```

   1. 한 개의 Puma 또는 Sidekiq 노드에서 다음을 실행합니다:

      ```shell
      sudo gitlab-rake gitlab:check SANITIZE=true
      ```

1. [데이터베이스 값이 해독될 수 있는지](../raketasks/check.md#verify-database-values-can-be-decrypted-using-the-current-secrets) 확인합니다. 특히 `/etc/gitlab/gitlab-secrets.json`이 복원되었거나 다른 서버가 복원의 대상인 경우:

   Puma 또는 Sidekiq 노드에서 다음을 실행합니다:

   ```shell
   sudo gitlab-rake gitlab:doctor:secrets
   ```

1. 추가 보증을 위해 [업로드된 파일에 대한 무결성 확인](../raketasks/check.md#uploaded-files-integrity)을 수행할 수 있습니다:

   Puma 또는 Sidekiq 노드에서 다음을 실행합니다:

   ```shell
   sudo gitlab-rake gitlab:artifacts:check
   sudo gitlab-rake gitlab:lfs:check
   sudo gitlab-rake gitlab:uploads:check
   ```

   누락되거나 손상된 파일이 발견된 경우 항상 백업 및 복원 프로세스가 실패했다는 것을 의미하지는 않습니다. 예를 들어 파일이 소스 GitLab 인스턴스에서 누락되거나 손상되었을 수 있습니다. 이전 백업을 교차 참조해야 할 수도 있습니다. GitLab을 새 환경으로 마이그레이션하는 경우 소스 GitLab 인스턴스에서 동일한 확인을 실행하여 무결성 확인 결과가 기존 또는 백업 및 복원 프로세스와 관련이 있는지 확인할 수 있습니다.

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. 도구 상자 pod로 SSH를 연결합니다.
1. 백업 버킷에서 타임스탬프를 기반으로 `*_gitlab_backup.tar` 파일을 선택하여 복원한 PostgreSQL 및 객체 저장소 데이터와 정렬합니다.
1. `tar` 파일을 `/var/opt/gitlab/backups/`에 다운로드합니다.
1. 복원할 백업의 ID를 지정하여 백업을 복원하고 이름에서 `_gitlab_backup.tar`을 생략합니다:

   ```shell
   # This command will overwrite the contents of Gitaly!
   kubectl exec <Toolbox pod name> -it -- backup-utility --restore -t 11493107454_2018_04_25_10.6.4-ce --skip db,builds,pages,registry,uploads,artifacts,lfs,packages,external_diffs,terraform_state,pages,ci_secure_files
   ```

   백업 tar 파일과 설치된 GitLab 버전 사이에 GitLab 버전 불일치가 있는 경우 복원 명령이 오류 메시지로 중단됩니다. [올바른 GitLab 버전](https://packages.gitlab.com/ui/browse/gitlab)을 설치한 후 다시 시도합니다.

1. 다시 시작하고 GitLab을 [확인](../raketasks/maintenance.md#check-gitlab-configuration)합니다:

   1. [전제 조건](#prerequisites)에 기록된 복제본 수를 사용하여 중지된 배포를 시작합니다:

      ```shell
      kubectl scale deploy -lapp=sidekiq,release=<helm release name> -n <namespace> --replicas=<original value>
      kubectl scale deploy -lapp=webservice,release=<helm release name> -n <namespace> --replicas=<original value>
      kubectl scale deploy -lapp=prometheus,release=<helm release name> -n <namespace> --replicas=<original value>
      ```

   1. Toolbox pod에서 다음을 실행합니다:

      ```shell
      sudo gitlab-rake gitlab:check SANITIZE=true
      ```

1. [데이터베이스 값이 해독될 수 있는지](../raketasks/check.md#verify-database-values-can-be-decrypted-using-the-current-secrets) 확인합니다. 특히 `/etc/gitlab/gitlab-secrets.json`이 복원되었거나 다른 서버가 복원의 대상인 경우:

   Toolbox pod에서 다음을 실행합니다:

   ```shell
   sudo gitlab-rake gitlab:doctor:secrets
   ```

1. 추가 보증을 위해 [업로드된 파일에 대한 무결성 확인](../raketasks/check.md#uploaded-files-integrity)을 수행할 수 있습니다:

   이러한 명령은 모든 행을 반복하므로 시간이 오래 걸릴 수 있습니다. 따라서 Toolbox pod 대신 GitLab Rails 노드에서 다음 명령을 실행합니다:

   ```shell
   sudo gitlab-rake gitlab:artifacts:check
   sudo gitlab-rake gitlab:lfs:check
   sudo gitlab-rake gitlab:uploads:check
   ```

   누락되거나 손상된 파일이 발견된 경우 항상 백업 및 복원 프로세스가 실패했다는 것을 의미하지는 않습니다. 예를 들어 파일이 소스 GitLab 인스턴스에서 누락되거나 손상되었을 수 있습니다. 이전 백업을 교차 참조해야 할 수도 있습니다. GitLab을 새 환경으로 마이그레이션하는 경우 소스 GitLab 인스턴스에서 동일한 확인을 실행하여 무결성 확인 결과가 기존 또는 백업 및 복원 프로세스와 관련이 있는지 확인할 수 있습니다.

{{< /tab >}}

{{< /tabs >}}

복원이 완료되어야 합니다.
