---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
ignore_in_report: true
title: "`gitlab-backup-cli`로 GitLab 백업 및 복원"
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed
- 상태:  실험

{{< /details >}}

{{< history >}}

- GitLab 17.0에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/11908)되었습니다. 이 기능은 [실험](../../policy/development_stages_support.md) 이며 [GitLab 테스트 계약](https://handbook.gitlab.com/handbook/legal/testing-agreement/)의 적용을 받습니다.

{{< /history >}}

이 도구는 개발 중이며 궁극적으로 [GitLab 백업 및 복원에 사용되는 Rake 작업](backup_gitlab.md)을 대체하기 위해 설계되었습니다. 다음 에픽에서 이 도구의 개발을 추적할 수 있습니다:  [Next Gen Scalable Backup and Restore](https://gitlab.com/groups/gitlab-org/-/epics/11577)

[피드백 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/457155)에서 도구에 대한 피드백을 환영합니다.

## 백업 수행 {#taking-a-backup}

현재 GitLab 설치의 백업을 수행하려면:

```shell
sudo gitlab-backup-cli backup all
```

### 객체 스토리지 백업 {#backing-up-object-storage}

Google Cloud만 지원됩니다. 더 많은 공급업체를 추가하려는 계획은 [에픽 11577](https://gitlab.com/groups/gitlab-org/-/epics/11577)을 참조하세요.

#### GCP {#gcp}

`gitlab-backup-cli`은 Google Cloud [Storage Transfer Service](https://cloud.google.com/storage-transfer-service/)를 사용하여 작업을 생성 및 실행하고 GitLab 데이터를 별도의 백업 버킷으로 복사합니다.

전제 조건:

- [서비스 계정 개요](https://cloud.google.com/iam/docs/service-account-overview)를 검토하여 서비스 계정으로 인증합니다.
- 이 문서는 백업 관리를 위해 전용 Google Cloud 서비스 계정을 설정하고 사용하고 있다고 가정합니다.
- 다른 자격 증명이 제공되지 않았으며 Google Cloud 내에서 실행 중인 경우 도구는 실행 중인 인프라의 액세스를 사용하려고 시도합니다. [보안상 이유](#security-considerations)로 도구를 별도의 자격 증명으로 실행하고 애플리케이션에서 생성된 백업에 대한 액세스를 제한해야 합니다.

백업을 생성하려면:

1. [역할 생성](https://cloud.google.com/iam/docs/creating-custom-roles):
   1. 다음 정의로 `role.yaml` 파일을 생성합니다:

   ```yaml
   ---
   description: Role for backing up GitLab object storage
   includedPermissions:
      - storagetransfer.jobs.create
      - storagetransfer.jobs.get
      - storagetransfer.jobs.run
      - storagetransfer.jobs.update
      - storagetransfer.operations.get
      - storagetransfer.projects.getServiceAccount
   stage: GA
   title: GitLab Backup Role
   ```

   1. 역할을 적용합니다:

      ```shell
      gcloud iam roles create --project=<YOUR_PROJECT_ID> <ROLE_NAME> --file=role.yaml
      ```

1. 백업용 서비스 계정을 생성하고 역할에 추가합니다:

   ```shell
   gcloud iam service-accounts create "gitlab-backup-cli" --display-name="GitLab Backup Service Account"
   # Get the service account email from the output of the following
   gcloud iam service-accounts list
   # Add the account to the role created previously
   gcloud projects add-iam-policy-binding <YOUR_PROJECT_ID> --member="serviceAccount:<SERVICE_ACCOUNT_EMAIL>" --role="roles/<ROLE_NAME>"
   ```

1. 서비스 계정으로 인증하려면 [서비스 계정 자격 증명](https://cloud.google.com/iam/docs/service-account-overview#credentials)을 참조하세요. 자격 증명을 파일로 저장하거나 미리 정의된 환경 변수에 저장할 수 있습니다.
1. [Google Cloud Storage](https://cloud.google.com/storage/)에서 백업할 대상 버킷을 생성합니다. 여기의 옵션은 요구 사항에 따라 크게 달라집니다.
1. 백업을 실행합니다:

   ```shell
   sudo gitlab-backup-cli backup all --backup-bucket=<BUCKET_NAME>
   ```

   컨테이너 레지스트리 버킷을 백업하려면 옵션 `--registry-bucket=<REGISTRY_BUCKET_NAME>`을 추가합니다.
1. 백업은 버킷의 각 객체 스토리지 유형에 대해 `backups/<BACKUP_ID>/<BUCKET>` 아래에 백업을 생성합니다.

## 백업 디렉터리 구조 {#backup-directory-structure}

백업 디렉터리 구조 예:

```plaintext
backups
└── 1714053314_2024_04_25_17.0.0-pre
    ├── artifacts.tar.gz
    ├── backup_information.json
    ├── builds.tar.gz
    ├── ci_secure_files.tar.gz
    ├── db
    │   ├── ci_database.sql.gz
    │   └── database.sql.gz
    ├── lfs.tar.gz
    ├── packages.tar.gz
    ├── pages.tar.gz
    ├── registry.tar.gz
    ├── repositories
    │   ├── default
    │   │   ├── @hashed
    │   │   └── @snippets
    │   └── manifests
    │       └── default
    ├── terraform_state.tar.gz
    └── uploads.tar.gz
```

`db` 디렉터리는 `pg_dump`를 사용하여 GitLab PostgreSQL 데이터베이스를 백업하고 [SQL 덤프](https://www.postgresql.org/docs/16/backup-dump.html)를 생성하는 데 사용됩니다. `pg_dump`의 출력은 압축된 SQL 파일을 생성하기 위해 `gzip`를 통해 파이프됩니다.

`repositories` 디렉터리는 GitLab 데이터베이스에서 발견된 Git 리포지토리를 백업하는 데 사용됩니다.

## 백업 ID {#backup-id}

백업 ID는 개별 백업을 식별합니다. GitLab을 복원해야 하고 여러 백업을 사용할 수 있는 경우 백업 아카이브의 백업 ID가 필요합니다.

백업은 `backup_path`에 설정된 디렉터리에 저장되며, 이는 `config/gitlab.yml` 파일에 지정됩니다.

- 기본적으로 백업은 `/var/opt/gitlab/backups`에 저장됩니다.
- 기본적으로 백업 디렉터리는 `backup_id`의 이름으로 지정되며, 여기서 `<backup-id>`는 백업 생성 시간과 GitLab 버전을 식별합니다.

예를 들어 백업 디렉터리 이름이 `1714053314_2024_04_25_17.0.0-pre`인 경우 생성 시간은 `1714053314_2024_04_25`로 표시되며 GitLab 버전은 17.0.0-pre입니다.

## 백업 메타데이터 파일 (`backup_information.json`) {#backup-metadata-file-backup_informationjson}

{{< history >}}

- 메타데이터 버전 2는 [GitLab 16.11](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149441)에서 도입되었습니다.

{{< /history >}}

`backup_information.json`은 백업 디렉터리에 있으며 백업에 대한 메타데이터를 저장합니다. 예를 들어:

```json
{
  "metadata_version": 2,
  "backup_id": "1714053314_2024_04_25_17.0.0-pre",
  "created_at": "2024-04-25T13:55:14Z",
  "gitlab_version": "17.0.0-pre"
}
```

## 백업 복원 {#restore-a-backup}

{{< history >}}

- GitLab 17.6에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/469247)되었습니다.

{{< /history >}}

전제 조건:

- `gitlab-backup-cli`을 사용하여 생성한 백업의 백업 ID를 보유하고 있습니다.

현재 GitLab 설치의 백업을 복원하려면:

- 다음 명령을 실행합니다:

  ```shell
  sudo gitlab-backup-cli restore all <backup_id>
  ```

### 객체 저장소 데이터 복원 {#restore-object-storage-data}

Google Cloud Storage에서 데이터를 복원할 수 있습니다. [에픽 11577](https://gitlab.com/groups/gitlab-org/-/epics/11577)은 다른 공급업체에 대한 지원을 추가할 것을 제안합니다.

전제 조건:

- `gitlab-backup-cli`을 사용하여 생성한 백업의 백업 ID를 보유하고 있습니다.
- 복원 위치에 필요한 권한을 구성했습니다.
- 객체 스토리지 구성 `gitlab.rb` 또는 `gitlab.yml` 파일을 설정했으며 백업 환경과 일치합니다.
- 스테이징 환경에서 복원 프로세스를 테스트했습니다.

객체 스토리지 데이터를 복원하려면:

- 다음 명령을 실행합니다:

  ```shell
  sudo gitlab-backup restore <backup_id>
  ```

복원 프로세스:

- 대상 버킷을 먼저 지우지 않습니다.
- 대상 버킷에서 동일한 파일명의 기존 파일을 덮어씁니다.
- 복원되는 데이터 양에 따라 상당한 시간이 소요될 수 있습니다.

복원 중에 항상 시스템 리소스를 모니터링합니다. 복원이 성공했는지 확인할 때까지 원본 파일을 유지합니다.

## 알려진 이슈 {#known-issues}

`gitlab-backup-cli`로 작업할 때 다음 이슈가 발생할 수 있습니다.

### 아키텍처 호환성 {#architecture-compatibility}

[1K 아키텍처](../reference_architectures/1k_users.md) 이외의 아키텍처에서 `gitlab-backup-cli` 도구를 사용하면 이슈가 발생할 수 있습니다. 이 도구는 1K 아키텍처에서만 지원되며 관련 환경에만 권장됩니다.

### 백업 전략 {#backup-strategy}

백업 중 기존 파일의 변경으로 인해 GitLab 인스턴스에 이슈가 발생할 수 있습니다. 이 이슈는 도구의 초기 버전이 [복사 전략](backup_gitlab.md#backup-strategy-option)을 사용하지 않기 때문에 발생합니다.

이 이슈의 해결 방법은 다음 중 하나입니다:

- GitLab 인스턴스를 [유지 보수 모드](../maintenance_mode/_index.md)로 전환합니다.
- 백업 중에 인스턴스 리소스를 보존하기 위해 서버로의 트래픽을 제한합니다.

복사 전략의 대안을 조사하고 있습니다. [이슈 428520](https://gitlab.com/gitlab-org/gitlab/-/issues/428520)을 참조하세요.

## 백업되는 데이터 {#what-data-is-backed-up}

1. Git 리포지토리 데이터
1. 데이터베이스
1. Blobs

## 백업되지 않는 데이터 {#what-data-is-not-backed-up}

1. 보안 암호 및 구성

   - [보안 암호 및 구성을 백업](backup_gitlab.md#storing-configuration-files)하는 방법에 대한 설명서를 참조하세요.

1. 일시적 및 캐시 데이터

   - Redis:  캐시
   - Redis:  Sidekiq 데이터
   - 로그
   - Elasticsearch
   - 관찰 가능성 데이터 / Prometheus 메트릭

## 보안 고려 사항 {#security-considerations}

동일한 자격 증명을 사용하는 대신 백업을 수행하는 데 필요한 권한만 있는 별도의 사용자 계정을 생성해야 합니다. 애플리케이션과 동일한 자격 증명으로 백업을 실행하는 것은 여러 이유로 보안이 좋지 않은 관행입니다:

- 최소 권한 원칙 - 백업 프로세스에는 일반 애플리케이션 작업에 필요한 것보다 더 광범위한 권한(예: 모든 데이터에 대한 읽기 액세스)이 필요합니다. 사용자 또는 프로세스는 기능을 수행하는 데 필요한 최소 액세스 권한을 가져야 합니다.
- 손상 위험 - 애플리케이션 자격 증명이 손상되면 공격자는 애플리케이션 및 모든 백업 데이터에 액세스할 수 있어 과거 데이터도 노출됩니다.
- 업무의 분리 - 백업 및 애플리케이션에 별도의 자격 증명을 사용하면 업무의 분리를 유지하는 데 도움이 됩니다. 이러한 분리를 통해 손상된 단일 계정으로 인한 광범위한 피해 가능성을 낮춥니다.
- 감사 추적 - 백업용 별도의 자격 증명을 사용하면 정기적인 애플리케이션 작업과 별개로 백업 활동을 추적 및 감시하기가 더 쉬워집니다.
- 세분화된 액세스 제어 - 다양한 자격 증명을 사용하면 더욱 세분화된 액세스 제어가 가능합니다. 백업 자격 증명에는 데이터에 대한 읽기 전용 액세스가 부여될 수 있으며, 애플리케이션 자격 증명은 특정 테이블 또는 스키마에 대한 읽기-쓰기 액세스가 필요할 수 있습니다.
- 규정 준수 요구 사항 - 많은 규정 표준 및 규정 준수 프레임워크(예: GDPR, HIPAA 또는 PCI-DSS)에서는 업무의 분리 및 액세스 제어를 요구하거나 강력히 권장하며, 이는 별도의 자격 증명으로 더 쉽게 달성할 수 있습니다.
- 수명 주기 관리 용이 - 애플리케이션 및 백업 프로세스는 서로 다른 수명 주기를 가질 수 있습니다. 별도의 자격 증명을 사용하면 이러한 수명 주기를 독립적으로 관리하기가 더 쉬워집니다. 예를 들어 다른 프로세스에 영향을 주지 않고 자격 증명을 회전하거나 취소할 수 있습니다.
- 애플리케이션 취약성 보호 - 애플리케이션에 SQL 삽입 또는 기타 형태의 무단 데이터 액세스를 허용하는 취약성이 있는 경우 별도의 백업 자격 증명을 사용하면 백업 프로세스에 추가 보호 계층이 추가됩니다.
