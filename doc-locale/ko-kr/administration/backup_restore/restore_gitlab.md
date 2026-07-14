---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 복원
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab 복원 작업은 백업에서 데이터를 복구하여 시스템 연속성을 유지하고 데이터 손실에서 복구합니다. 복원 작업:

- 데이터베이스 레코드 및 구성 복구
- Git 리포지토리, 컨테이너 레지스트리 이미지 및 업로드된 콘텐츠 복원
- 패키지 레지스트리 데이터 및 CI/CD 변수 복원
- 계정 및 그룹 설정 복원
- 프로젝트 및 그룹 위키 복구
- 프로젝트 수준 보안 파일 복원
- 외부 머지 리퀘스트 diff 복구

복원 프로세스에는 백업과 동일한 버전의 기존 GitLab 설치가 필요합니다. [전제 조건](#restore-prerequisites)을 따르고 프로덕션에서 사용하기 전에 전체 복원 프로세스를 테스트합니다.

## 복원 전제 조건 {#restore-prerequisites}

### 대상 GitLab 인스턴스가 이미 작동 중이어야 합니다 {#the-destination-gitlab-instance-must-already-be-working}

복원을 수행하기 전에 작동하는 GitLab 설치가 필요합니다. 복원 작업을 수행하는 시스템 사용자(`git`)는 일반적으로 데이터를 가져올 SQL 데이터베이스(`gitlabhq_production`)를 생성하거나 삭제할 수 없기 때문입니다.

### 대상 GitLab 인스턴스에 기존 데이터가 없어야 합니다 {#the-destination-gitlab-instance-must-not-have-existing-data}

복원 프로세스는 데이터 유형에 따라 기존 데이터를 다르게 처리합니다:

- PostgreSQL 데이터는 복원 프로세스 중에 자동으로 삭제됩니다.
- Git 리포지토리:  같은 이름의 리포지토리가 이미 있으면 "리포지토리가 이미 있음" 오류로 복원이 실패합니다. 자세한 내용은 [이슈 118459](https://gitlab.com/gitlab-org/gitlab/-/issues/118459)를 참조하세요.
- 파일 시스템 데이터는 복원 전에 별도 디렉터리로 이동하려고 시도합니다.
- 객체 스토리지 데이터는 자동으로 지워지지 않습니다. 고아 데이터를 유지하는 것을 피하기 위해 복원하기 전에 객체 스토리지 버킷을 수동으로 지워야 합니다.

안정적인 복원 프로세스를 위해, 예를 들어 프로덕션에서 스테이징으로의 복원을 자동화할 때는 백업과 동일한 버전의 새로운 GitLab 설치를 사용합니다.

SQL 데이터 복원은 PostgreSQL 확장이 소유한 뷰를 건너뜁니다.

### 대상 GitLab 인스턴스에 정확히 동일한 버전이 있어야 합니다 {#the-destination-gitlab-instance-must-have-the-exact-same-version}

백업이 생성된 GitLab과 정확히 동일한 버전 및 유형(CE 또는 EE)에만 백업을 복원할 수 있습니다. 예를 들어 CE 15.1.4입니다.

백업이 현재 설치와 다른 버전인 경우 백업을 복원하기 전에 GitLab 설치를 [다운그레이드](../../update/package/downgrade.md) 하거나 [업그레이드](../../update/package/_index.md)해야 합니다.

### GitLab 시크릿을 복원해야 합니다 {#gitlab-secrets-must-be-restored}

백업을 복원하려면 GitLab 시크릿도 복원해야 합니다. 새 GitLab 인스턴스로 마이그레이션하는 경우 이전 서버에서 GitLab 시크릿 파일을 복사해야 합니다. 데이터베이스 암호화 키, CI/CD 변수 및 2단계 인증에 사용되는 변수가 포함됩니다. 키가 없으면 2단계 인증 사용 가능 사용자의 액세스 손실 및 GitLab 러너가 로그인할 수 없는 등 여러 이슈가 발생합니다.

> [!warning]
> **WebAuthn devices are disabled when restoring to a different FQDN:** WebAuthn 등록(예: YubiKey)은 생성된 원본(도메인/호스트명)에 암호화 방식으로 바인딩됩니다. 다른 FQDN이 있는 GitLab 인스턴스로 백업을 복원하면 모든 WebAuthn 기기가 비활성화됩니다. 사용자는 복원이 완료된 후 WebAuthn 기기를 다시 등록해야 합니다.
>
> WebAuthn 및 호스트명 요구 사항에 대한 자세한 내용은 [2단계 인증](../../user/profile/account/two_factor_authentication.md#information-for-gitlab-administrators)을 참조하세요.

설치 방법에 따라 다음을 복원합니다:

{{< tabs >}}

{{< tab title="Linux 패키지" >}}

```plaintext
/etc/gitlab/gitlab-secrets.json
```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

[시크릿 복원](https://docs.gitlab.com/charts/backup-restore/restore/#restoring-the-secrets).

[GitLab Helm 차트 시크릿을 Linux 패키지 형식으로 변환할 수 있습니다](https://docs.gitlab.com/charts/installation/migration/helm_to_package/)(필요한 경우).

{{< /tab >}}

{{< tab title="Docker" >}}

`/etc/gitlab`을 `/srv/gitlab/config` 아래에 마운트한 경우:

```plaintext
/srv/gitlab/config/gitlab-secrets.json
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

```plaintext
/home/git/gitlab/.secret
```

{{< /tab >}}

{{< /tabs >}}

참고 항목:

- [CI/CD 변수](../../ci/variables/_index.md)
- [2단계 인증](../../user/profile/account/two_factor_authentication.md)
- [시크릿 이슈 해결](troubleshooting_backup_gitlab.md#when-the-secrets-file-is-lost)

### 특정 GitLab 구성이 원본 백업 환경과 일치해야 합니다 {#certain-gitlab-configuration-must-match-the-original-backed-up-environment}

이전 `/etc/gitlab/gitlab.rb` (Linux 패키지 설치의 경우) 또는 `/home/git/gitlab/config/gitlab.yml` (자체 컴파일 설치의 경우)과 TLS 또는 SSH 키 및 인증서를 별도로 복원해야 할 것입니다.

특정 구성은 PostgreSQL의 데이터와 연결되어 있습니다. 예를 들어:

- 원본 환경에 3개의 리포지토리 스토리지가 있는 경우(예: `default`, `my-storage-1`, `my-storage-2`), 대상 환경도 구성에서 정의된 최소한 해당 스토리지 이름을 가져야 합니다.
- 로컬 스토리지를 사용하는 환경에서 백업을 복원하면 대상 환경이 객체 스토리지를 사용하더라도 로컬 스토리지로 복원됩니다. 객체 스토리지로의 마이그레이션은 복원 전이나 후에 수행해야 합니다.

자세한 내용은 [백업에 포함되지 않은 데이터](backup_gitlab.md#data-not-included-in-a-backup)를 참조하세요.

### 마운트 지점인 디렉터리 복원 {#restoring-directories-that-are-mount-points}

마운트 지점인 디렉터리로 복원하는 경우 복원을 시도하기 전에 이 디렉터리가 비어 있는지 확인해야 합니다. 그렇지 않으면 GitLab이 새 데이터를 복원하기 전에 이 디렉터리를 이동하려고 하므로 오류가 발생합니다.

[NFS 마운트 구성](../nfs.md)에 대해 자세히 알아보세요.

## Linux 패키지 설치를 위한 복원 {#restore-for-linux-package-installations}

이 프로시저는 다음을 가정합니다:

- 백업이 생성된 것과 동일한 버전 및 유형(CE/EE)의 GitLab을 설치했습니다.
- `sudo gitlab-ctl reconfigure`을 최소한 한 번 실행했습니다.
- GitLab이 실행 중입니다. 실행 중이 아니면 `sudo gitlab-ctl start`을 사용하여 시작합니다.

먼저 백업 tar 파일이 `gitlab.rb` 구성 `gitlab_rails['backup_path']`에 설명된 백업 디렉터리에 있는지 확인합니다. 기본값은 `/var/opt/gitlab/backups`입니다. 백업 파일은 `git` 사용자가 소유해야 합니다.

```shell
sudo cp 11493107454_2018_04_25_10.6.4-ce_gitlab_backup.tar /var/opt/gitlab/backups/
sudo chown git:git /var/opt/gitlab/backups/11493107454_2018_04_25_10.6.4-ce_gitlab_backup.tar
```

데이터베이스에 연결된 프로세스를 중지합니다. GitLab의 나머지는 실행 중으로 유지합니다:

```shell
sudo gitlab-ctl stop puma
sudo gitlab-ctl stop sidekiq
# Verify
sudo gitlab-ctl status
```

다음으로 [복원 전제 조건](#restore-prerequisites) 단계를 완료했으며 원본 설치에서 GitLab 시크릿 파일을 복사한 후 `gitlab-ctl reconfigure`을 실행했는지 확인합니다.

다음으로 복원할 백업의 ID를 지정하여 백업을 복원합니다:

> [!warning]
> 다음 명령은 GitLab 데이터베이스의 내용을 덮어씁니다!

```shell
# NOTE: "_gitlab_backup.tar" is omitted from the name
sudo gitlab-backup restore BACKUP=11493107454_2018_04_25_10.6.4-ce
```

백업 tar 파일과 설치된 GitLab 버전 간에 GitLab 버전 불일치가 있으면 복원 명령이 오류 메시지로 중단됩니다:

```plaintext
GitLab version mismatch:
  Your current GitLab version (16.5.0-ee) differs from the GitLab version in the backup!
  Please switch to the following version and try again:
  version: 16.4.3-ee
```

올바른 GitLab 버전을 설치한 후 다시 시도합니다.

> [!warning]
> 복원 명령은 설치 시 PgBouncer를 사용하거나 Patroni 클러스터와 함께 사용할 때 [추가 매개변수](backup_gitlab.md#back-up-and-restore-for-installations-using-pgbouncer)가 필요합니다.

PostgreSQL 노드에서 reconfigure를 실행합니다:

```shell
sudo gitlab-ctl reconfigure
```

다음으로 GitLab을 시작하고 확인합니다:

```shell
sudo gitlab-ctl start
sudo gitlab-rake gitlab:check SANITIZE=true
```

데이터베이스 값을 복호화할 수 있는지 확인합니다. 특히 `/etc/gitlab/gitlab-secrets.json`이 복원된 경우 또는 다른 서버가 복원 대상인 경우입니다.

```shell
sudo gitlab-rake gitlab:doctor:secrets
```

추가 보증을 위해 업로드된 파일에 대한 무결성 검사를 수행할 수 있습니다:

```shell
sudo gitlab-rake gitlab:artifacts:check
sudo gitlab-rake gitlab:lfs:check
sudo gitlab-rake gitlab:uploads:check
```

복원이 완료된 후 데이터베이스 성능을 향상시키고 UI의 불일치를 방지하기 위해 데이터베이스 통계를 생성하는 것이 좋습니다:

1. [데이터베이스 콘솔](https://docs.gitlab.com/omnibus/settings/database/#connecting-to-the-postgresql-database)을 입력합니다.
1. 다음을 실행합니다:

   ```sql
   SET STATEMENT_TIMEOUT=0 ; ANALYZE VERBOSE;
   ```

복원 명령을 통합하는 것에 대한 진행 중인 논의가 있으며, 자세한 내용은 [이슈 276184](https://gitlab.com/gitlab-org/gitlab/-/issues/276184)를 참조하세요.

복원 후 확인 가이드:

- [GitLab 구성 확인](../raketasks/maintenance.md#check-gitlab-configuration)
- [데이터베이스 값을 복호화할 수 있는지 확인](../raketasks/check.md#verify-database-values-can-be-decrypted-using-the-current-secrets)
- [업로드된 파일 무결성 검사](../raketasks/check.md#uploaded-files-integrity):

## Docker 이미지 및 GitLab Helm 차트 설치를 위한 복원 {#restore-for-docker-image-and-gitlab-helm-chart-installations}

Docker 이미지 또는 Kubernetes 클러스터의 GitLab Helm 차트를 사용하는 GitLab 설치의 경우 복원 작업은 복원 디렉터리가 비어 있을 것으로 예상합니다. 그러나 Docker 및 Kubernetes 볼륨 마운트를 사용하면 Linux 운영 체제에서 찾을 수 있는 `lost+found` 디렉터리와 같은 볼륨 루트에서 일부 시스템 수준 디렉터리가 생성될 수 있습니다. 이 디렉터리는 일반적으로 `root`에서 소유하며, 복원 Rake 작업이 `git` 사용자로 실행되기 때문에 액세스 권한 오류를 발생시킬 수 있습니다. GitLab 설치를 복원하려면 사용자가 복원 대상 디렉터리가 비어 있는지 확인해야 합니다.

이 두 설치 유형 모두에서 백업 tarball을 백업 위치(기본 위치는 `/var/opt/gitlab/backups`)에서 사용 가능해야 합니다.

### Helm 차트 설치를 위한 복원 {#restore-for-helm-chart-installations}

GitLab Helm 차트는 [GitLab Helm 차트 설치 복원](https://docs.gitlab.com/charts/backup-restore/restore/#restoring-a-gitlab-installation)에서 문서화된 프로세스를 사용합니다.

### Docker 이미지 설치를 위한 복원 {#restore-for-docker-image-installations}

[Docker Swarm](../../install/docker/installation.md#install-gitlab-by-using-docker-swarm-mode)을 사용하는 경우 Puma가 종료되고 컨테이너 상태 확인이 실패하므로 복원 프로세스 중에 컨테이너가 다시 시작될 수 있습니다. 이 문제를 해결하려면 상태 확인 메커니즘을 일시적으로 비활성화합니다.

1. `docker-compose.yml`을(를) 편집합니다:

   ```yaml
   healthcheck:
     disable: true
   ```

1. 스택을 배포합니다:

   ```shell
   docker stack deploy --compose-file docker-compose.yml mystack
   ```

자세한 내용은 [이슈 6846](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6846 "GitLab restore can fail owing to gitlab-healthcheck")를 참조하세요.

복원 작업을 호스트에서 실행할 수 있습니다:

```shell
# Stop the processes that are connected to the database
docker exec -it <name of container> gitlab-ctl stop puma
docker exec -it <name of container> gitlab-ctl stop sidekiq

# Verify that the processes are all down before continuing
docker exec -it <name of container> gitlab-ctl status

# Run the restore. NOTE: "_gitlab_backup.tar" is omitted from the name
docker exec -it <name of container> gitlab-backup restore BACKUP=11493107454_2018_04_25_10.6.4-ce

# Restart the GitLab container
docker restart <name of container>

# Check GitLab
docker exec -it <name of container> gitlab-rake gitlab:check SANITIZE=true
```

## 자체 컴파일 설치를 위한 복원 {#restore-for-self-compiled-installations}

1. 먼저 백업 tar 파일이 `gitlab.yml` 구성에 설명된 백업 디렉터리에 있는지 확인합니다:

   ```yaml
   ## Backup settings
   backup:
     path: "tmp/backups"   # Relative paths are relative to Rails.root (default: tmp/backups/)
   ```

   기본값은 `/home/git/gitlab/tmp/backups`이며 `git` 사용자가 소유해야 합니다.

1. 백업 프로시저를 시작합니다:

   ```shell
   # Stop processes that are connected to the database
   sudo service gitlab stop

   sudo -u git -H bundle exec rake gitlab:backup:restore RAILS_ENV=production
   ```

   예제 출력:

   ```plaintext
   Unpacking backup... [DONE]
   Restoring database tables:
   -- create_table("events", {:force=>true})
     -> 0.2231s
   [...]
   - Loading fixture events...[DONE]
   - Loading fixture issues...[DONE]
   - Loading fixture keys...[SKIPPING]
   - Loading fixture merge_requests...[DONE]
   - Loading fixture milestones...[DONE]
   - Loading fixture namespaces...[DONE]
   - Loading fixture notes...[DONE]
   - Loading fixture projects...[DONE]
   - Loading fixture protected_branches...[SKIPPING]
   - Loading fixture schema_migrations...[DONE]
   - Loading fixture services...[SKIPPING]
   - Loading fixture snippets...[SKIPPING]
   - Loading fixture taggings...[SKIPPING]
   - Loading fixture tags...[SKIPPING]
   - Loading fixture users...[DONE]
   - Loading fixture users_projects...[DONE]
   - Loading fixture web_hooks...[SKIPPING]
   - Loading fixture wikis...[SKIPPING]
   Restoring repositories:
   - Restoring repository abcd... [DONE]
   - Object pool 1 ...
   Deleting tmp directories...[DONE]
   ```

1. `/home/git/gitlab/.secret`을 복원합니다(필요한 경우).
1. GitLab을 다시 시작합니다:

   ```shell
   sudo service gitlab restart
   ```

## 백업에서 하나 또는 몇 개의 프로젝트 또는 그룹만 복원 {#restoring-only-one-or-a-few-projects-or-groups-from-a-backup}

GitLab 인스턴스를 복원하는 데 사용되는 Rake 작업이 단일 프로젝트 또는 그룹 복원을 지원하지 않지만, 백업을 별도의 임시 GitLab 인스턴스로 복원한 후 프로젝트 또는 그룹을 내보내는 방법으로 해결할 수 있습니다:

1. [새 GitLab 설치](../../install/_index.md) 인스턴스를 복원하려는 백업된 인스턴스와 동일한 버전에서.
1. 백업을 이 새 인스턴스로 복원한 다음 [프로젝트](../../user/project/settings/import_export.md) 또는 [그룹](../../user/project/settings/import_export.md#migrate-groups-by-uploading-an-export-file-deprecated)을 내보냅니다. 내보낼 항목 및 내보내지 않을 항목에 대한 자세한 내용은 내보내기 기능의 설명서를 참조하세요.
1. 내보내기가 완료되면 이전 인스턴스로 이동한 다음 가져옵니다.
1. 원하는 프로젝트 또는 그룹을 가져오기가 완료된 후 새로운 임시 GitLab 인스턴스를 삭제할 수 있습니다.

개별 프로젝트 또는 그룹의 직접 복원을 제공하기 위한 기능 요청이 [이슈 #17517](https://gitlab.com/gitlab-org/gitlab/-/issues/17517)에서 논의 중입니다.

## 증분 리포지토리 백업 복원 {#restoring-an-incremental-repository-backup}

[증분 리포지토리 백업](backup_gitlab.md#incremental-repository-backups)을 `gitlab-backup`을 사용하여 생성할 때 결과 백업 아카이브에는 전체 복원에 필요한 모든 리포지토리 데이터가 포함되어 있습니다. 복원하려면 [다른 일반 백업 아카이브 복원](#restore-for-linux-package-installations)과 동일한 지침을 사용합니다.

내부적으로 증분 리포지토리 백업은 이전 백업 후 변경된 사항만 저장합니다. 증분 백업을 생성할 때 `gitlab-backup`은 원본 전체 백업 이후부터 모든 단계를 백업 아카이브에 번들화합니다. 이는 개별 리포지토리 백업 번들이 서로 종속되어 있더라도 아카이브가 자체적으로 포함되어 있음을 의미합니다.

[서버 측 리포지토리 백업](backup_gitlab.md#create-server-side-repository-backups)을 사용하면 백업 아카이브에 리포지토리 데이터가 포함되지 않습니다. 대신 리포지토리 데이터는 각 Gitaly 노드에 의해 객체 스토리지에 저장되며 각 증분은 별도의 객체로 저장됩니다. 서버 측 복원에서 Gitaly는 백업 매니페스트를 읽고 각 증분을 순서대로 적용합니다.

> [!warning]
> Object Storage에서 증분 백업 파일을 삭제하지 마세요. 중간 파일이 삭제된 경우(예: Object Storage 수명 주기 정책을 통해) 백업 체인이 끊어지고 백업을 복원할 수 없습니다.

## 복원 옵션 {#restore-options}

GitLab이 백업에서 복원하기 위해 제공하는 명령줄 도구는 더 많은 옵션을 수락할 수 있습니다.

### 둘 이상일 때 복원할 백업 지정 {#specify-backup-to-restore-when-there-are-more-than-one}

백업 파일은 [백업 ID로 시작](backup_archive_process.md#backup-id)하는 이름 지정 규칙을 사용합니다. 둘 이상의 백업이 있으면 환경 변수 `BACKUP=<backup-id>`을 설정하여 복원할 `<backup-id>_gitlab_backup.tar` 파일을 지정해야 합니다.

### 복원 중 프롬프트 비활성화 {#disable-prompts-during-restore}

백업에서 복원할 때 복원 스크립트는 확인을 요청합니다:

<!-- vale gitlab_base.Spelling = NO -->
- **Write to authorized_keys** 설정이 활성화된 경우 복원 스크립트가 `authorized_keys` 파일을 삭제하고 다시 빌드하기 전입니다.
<!-- vale gitlab_base.Spelling = YES -->
- 데이터베이스를 복원할 때 복원 스크립트가 기존의 모든 테이블을 제거하기 전입니다.
- 데이터베이스를 복원한 후 스키마 복원에 오류가 있는 경우 계속 진행하기 전입니다(추가 문제가 발생할 가능성이 높습니다).

이 프롬프트를 비활성화하려면 `GITLAB_ASSUME_YES` 환경 변수를 `1`로 설정합니다.

- Linux 패키지 설치:

  ```shell
  sudo GITLAB_ASSUME_YES=1 gitlab-backup restore
  ```

- 직접 컴파일한 설치:

  ```shell
  sudo -u git -H GITLAB_ASSUME_YES=1 bundle exec rake gitlab:backup:restore RAILS_ENV=production
  ```

`force=yes` 환경 변수도 이 프롬프트를 비활성화합니다.

### 복원 중 작업 제외 {#excluding-tasks-on-restore}

환경 변수 `SKIP`을 추가하여 복원 시 특정 작업을 제외할 수 있습니다. 그 값은 다음 옵션의 쉼표로 구분된 목록입니다:

- `db` (데이터베이스)
- `uploads` (첨부 파일)
- `builds` (CI 작업 출력 로그)
- `artifacts` (CI 작업 아티팩트)
- `lfs` (LFS 객체)
- `terraform_state` (Terraform 상태)
- `registry` (컨테이너 레지스트리 이미지)
- `pages` (Pages 콘텐츠)
- `repositories` (Git 리포지토리 데이터)
- `packages` (패키지)

특정 작업을 제외하려면:

- Linux 패키지 설치:

  ```shell
  sudo gitlab-backup restore BACKUP=<backup-id> SKIP=db,uploads
  ```

- 직접 컴파일한 설치:

  ```shell
  sudo -u git -H bundle exec rake gitlab:backup:restore BACKUP=<backup-id> SKIP=db,uploads RAILS_ENV=production
  ```

### 특정 리포지토리 스토리지 복원 {#restore-specific-repository-storages}

{{< history >}}

- [도입된](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86896) GitLab 15.0.

{{< /history >}}

> [!warning]
> GitLab 17.1 이하 버전이 [경합 상태의 영향을 받습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/158412)(데이터 손실을 초래할 수 있음). 이 문제는 포크된 리포지토리에 영향을 미치며 GitLab [객체 풀](../repository_storage_paths.md#hashed-object-pools)을 사용합니다. 데이터 손실을 방지하려면 GitLab 17.2 이상만 사용하여 백업을 복원합니다.

[여러 리포지토리 스토리지](../repository_storage_paths.md)를 사용할 때 `REPOSITORIES_STORAGES` 옵션을 사용하여 특정 리포지토리 스토리지에서 리포지토리를 별도로 복원할 수 있습니다. 옵션은 저장소 이름의 쉼표로 구분된 목록을 허용합니다.

예를 들어:

- Linux 패키지 설치:

  ```shell
  sudo gitlab-backup restore BACKUP=<backup-id> REPOSITORIES_STORAGES=storage1,storage2
  ```

- 직접 컴파일한 설치:

  ```shell
  sudo -u git -H bundle exec rake gitlab:backup:restore BACKUP=<backup-id> REPOSITORIES_STORAGES=storage1,storage2
  ```

### 특정 리포지토리 복원 {#restore-specific-repositories}

{{< history >}}

- [도입된](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88094) GitLab 15.1.

{{< /history >}}

> [!warning]
> GitLab 17.1 이하 버전이 [경합 상태의 영향을 받습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/158412)(데이터 손실을 초래할 수 있음). 이 문제는 포크된 리포지토리에 영향을 미치며 GitLab [객체 풀](../repository_storage_paths.md#hashed-object-pools)을 사용합니다. 데이터 손실을 방지하려면 GitLab 17.2 이상만 사용하여 백업을 복원합니다.

`REPOSITORIES_PATHS` 및 `SKIP_REPOSITORIES_PATHS` 옵션을 사용하여 특정 리포지토리를 복원할 수 있습니다. 두 옵션 모두 프로젝트 및 그룹 경로의 쉼표로 구분된 목록을 허용합니다. 그룹 경로를 지정하면 그룹의 모든 프로젝트 및 하위 그룹의 모든 리포지토리가 사용한 옵션에 따라 포함되거나 건너뜁니다. 그룹 및 프로젝트 모두 지정된 백업 또는 대상 인스턴스에 있어야 합니다.

> [!note]
> `REPOSITORIES_PATHS` 및 `SKIP_REPOSITORIES_PATHS` 옵션은 Git 리포지토리에만 적용됩니다. 프로젝트 또는 그룹 데이터베이스 항목에는 적용되지 않습니다. `SKIP=db`로 리포지토리 백업을 생성한 경우 자체적으로 새 인스턴스에 특정 리포지토리를 복원하는 데 사용할 수 없습니다.

예를 들어 그룹 A의 모든 프로젝트에 대한 모든 리포지토리를 복원하려면(`group-a`), 그룹 B의 프로젝트 C에 대한 리포지토리(`group-b/project-c`) 및 그룹 A의 프로젝트 D를 건너뛰려면(`group-a/project-d`):

- Linux 패키지 설치:

  ```shell
  sudo gitlab-backup restore BACKUP=<backup-id> REPOSITORIES_PATHS=group-a,group-b/project-c SKIP_REPOSITORIES_PATHS=group-a/project-d
  ```

- 직접 컴파일한 설치:

  ```shell
  sudo -u git -H bundle exec rake gitlab:backup:restore BACKUP=<backup-id> REPOSITORIES_PATHS=group-a,group-b/project-c SKIP_REPOSITORIES_PATHS=group-a/project-d
  ```

### 압축되지 않은 백업 복원 {#restore-untarred-backups}

`SKIP=tar`으로 만든 [압축되지 않은 백업](backup_gitlab.md#skipping-tar-creation)이 발견되고 `BACKUP=<backup-id>`으로 선택한 백업이 없으면 압축되지 않은 백업이 사용됩니다.

예를 들어:

- Linux 패키지 설치:

  ```shell
  sudo gitlab-backup restore
  ```

- 직접 컴파일한 설치:

  ```shell
  sudo -u git -H bundle exec rake gitlab:backup:restore
  ```

### 서버 측 리포지토리 백업을 사용하여 복원 {#restoring-using-server-side-repository-backups}

{{< history >}}

- [도입된](https://gitlab.com/gitlab-org/gitaly/-/issues/4941) `gitlab-backup`(GitLab 16.3).
- `gitlab-backup`에 대한 서버 측 지원을 통해 최신 백업 대신 지정된 백업을 복원합니다 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132188)(GitLab 16.6).
- 증분 백업을 생성하기 위한 `gitlab-backup`에 서버 측 지원 [도입됨](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6475)(GitLab 16.6).
- `backup-utility`에 서버 측 지원 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/438393)(GitLab 17.0).

{{< /history >}}

서버 측 백업이 수집되면 복원 프로세스는 [서버 측 리포지토리 백업 생성](backup_gitlab.md#create-server-side-repository-backups)에서 표시된 서버 측 복원 메커니즘을 사용하도록 기본값으로 설정됩니다. 각 리포지토리를 호스트하는 Gitaly 노드가 객체 스토리지에서 직접 필요한 백업 데이터를 가져오도록 백업 복원을 구성할 수 있습니다.

1. [Gitaly에서 서버 측 백업 대상 구성](../gitaly/configure_gitaly.md#configure-server-side-backups).
1. 서버 측 백업 복원 프로세스를 시작하고 복원하려는 [백업의 ID](backup_archive_process.md#backup-id)를 지정합니다:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

```shell
sudo gitlab-backup restore BACKUP=11493107454_2018_04_25_10.6.4-ce
```

{{< /tab >}}

{{< tab title="Self-compiled" >}}

```shell
sudo -u git -H bundle exec rake gitlab:backup:restore BACKUP=11493107454_2018_04_25_10.6.4-ce
```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

```shell
kubectl exec <Toolbox pod name> -it -- backup-utility --restore -t <backup_ID> --repositories-server-side
```

[cron 기반 백업](https://docs.gitlab.com/charts/backup-restore/backup/#cron-based-backup)을 사용할 때 `--repositories-server-side` 플래그를 추가 인수에 추가합니다.

{{< /tab >}}

{{< /tabs >}}

## 문제 해결 {#troubleshooting}

다음은 발생할 수 있는 가능한 문제와 잠재적 해결책입니다.

### Linux 패키지 설치에서 출력 경고를 사용하는 데이터베이스 백업 복원 {#restoring-database-backup-using-output-warnings-from-a-linux-package-installation}

백업 복원 절차를 사용하는 경우 다음과 같은 경고 메시지가 나타날 수 있습니다:

```plaintext
ERROR: must be owner of extension pg_trgm
ERROR: must be owner of extension btree_gist
ERROR: must be owner of extension plpgsql
WARNING:  no privileges could be revoked for "public" (two occurrences)
WARNING:  no privileges were granted for "public" (two occurrences)
```

이 경고 메시지에도 불구하고 백업이 성공적으로 복원되었습니다.

Rake 작업은 `gitlab` 사용자로 실행되며, 이는 데이터베이스에 대한 슈퍼유저 액세스 권한이 없습니다. 복원이 시작되면 `gitlab` 사용자로 실행되지만 액세스 권한이 없는 객체를 변경하려고 시도합니다. 이 객체는 데이터베이스 백업 또는 복원에 영향을 미치지 않지만 경고 메시지를 표시합니다.

자세한 정보는 다음을 참조하세요:

- PostgreSQL 이슈 추적:
  - [슈퍼유저가 아닙니다](https://www.postgresql.org/message-id/201110220712.30886.adrian.klaver@gmail.com).
  - [다른 소유자가 있습니다](https://www.postgresql.org/message-id/2039.1177339749@sss.pgh.pa.us).
- Stack Overflow:  [발생한 오류](https://stackoverflow.com/questions/4368789/error-must-be-owner-of-language-plpgsql).

### Git 서버 후크로 인한 복원 실패 {#restoring-fails-due-to-git-server-hook}

백업에서 복원할 때 다음이 참이면 오류가 발생할 수 있습니다:

- Git 서버 후크(`custom_hook`)는 [GitLab 버전 15.10 이하](../server_hooks.md) 방법을 사용하여 구성됩니다.
- GitLab 버전이 15.11 이상입니다.
- GitLab 관리 위치 외부의 디렉터리에 대한 심볼 링크를 생성했습니다.

오류는 다음과 같습니다:

```plaintext
{"level":"fatal","msg":"restore: pipeline: 1 failures encountered:\n - @hashed/path/to/hashed_repository.git (path/to_project): manager: restore custom hooks, \"@hashed/path/to/hashed_repository/<BackupID>_<GitLabVersion>-ee/001.custom_hooks.tar\": rpc error: code = Internal desc = setting custom hooks: generating prepared vote: walking directory: copying file to hash: read /mnt/gitlab-app/git-data/repositories/+gitaly/tmp/default-repositories.old.<timestamp>.<temporaryfolder>/custom_hooks/compliance-triggers.d: is a directory\n","pid":3256017,"time":"2023-08-10T20:09:44.395Z"}
```

이를 해결하려면 GitLab 버전 15.11 이상에 대해 Git [서버 후크](../server_hooks.md)를 업데이트하고 새 백업을 생성할 수 있습니다.

### `fapolicyd`을 사용할 때 리포지토리가 비어 있는 것으로 표시되는 성공적인 복원 {#successful-restore-with-repositories-showing-as-empty-when-using-fapolicyd}

보안 강화를 위해 `fapolicyd`을 사용할 때 GitLab은 복원이 성공했다고 보고할 수 있지만 리포지토리가 비어 있는 것으로 표시됩니다. 자세한 문제 해결 도움말은 [Gitaly 문제 해결 설명서](../gitaly/troubleshooting.md#repositories-are-shown-as-empty-after-a-gitlab-restore)를 참조하세요.
