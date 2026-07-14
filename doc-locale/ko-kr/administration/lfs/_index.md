---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Self-Managed를 위해 Git LFS를 구성합니다.
title: GitLab Git Large File Storage(LFS) 관리
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

Git Large File Storage(LFS)를 사용하여 Git 리포지토리의 크기를 늘리거나 성능에 영향을 미치지 않으면서 대용량 파일을 저장합니다. LFS를 활성화하거나 비활성화하고, LFS 개체에 대해 로컬 또는 원격 스토리지를 구성하고, 스토리지 유형 간에 개체를 마이그레이션할 수 있습니다.

사용자 설명서는 [Git Large File Storage(LFS)](../../topics/git/lfs/_index.md)를 참조하세요.

전제 조건:

- 사용자는 [Git LFS 클라이언트](https://git-lfs.com/) 버전 1.1.0 이상 또는 1.0.2를 설치해야 합니다.

## LFS 활성화 또는 비활성화 {#enable-or-disable-lfs}

LFS는 기본적으로 활성화됩니다. 비활성화하려면:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을 편집합니다:

   ```ruby
   # Change to true to enable lfs - enabled by default if not defined
   gitlab_rails['lfs_enabled'] = false
   ```

1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을 편집합니다:

   ```yaml
   global:
     appConfig:
       lfs:
         enabled: false
   ```

1. 파일을 저장하고 새 값을 적용합니다:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`을 편집합니다:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['lfs_enabled'] = false
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="소스에서 직접 컴파일(source)" >}}

1. `/home/git/gitlab/config/gitlab.yml`을 편집합니다:

   ```yaml
   production: &base
     lfs:
       enabled: false
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

## 로컬 스토리지 경로 변경 {#change-local-storage-path}

Git LFS 개체는 크기가 클 수 있습니다. 기본적으로 GitLab이 설치된 서버에 저장됩니다.

> [!note]
> Docker 설치의 경우 데이터가 마운트되는 경로를 변경할 수 있습니다. Helm 차트의 경우 [object storage](https://docs.gitlab.com/charts/advanced/external-object-storage/)를 사용합니다.

기본 로컬 스토리지 경로 위치를 변경하려면:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을 편집합니다:

   ```ruby
   # /var/opt/gitlab/gitlab-rails/shared/lfs-objects by default.
   gitlab_rails['lfs_storage_path'] = "/mnt/storage/lfs-objects"
   ```

1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="소스에서 직접 컴파일(source)" >}}

1. `/home/git/gitlab/config/gitlab.yml`을 편집합니다:

   ```yaml
   # /home/git/gitlab/shared/lfs-objects by default.
   production: &base
     lfs:
       storage_path: /mnt/storage/lfs-objects
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

## 원격 object storage에 LFS 개체 저장 {#storing-lfs-objects-in-remote-object-storage}

원격 object storage에 LFS 개체를 저장할 수 있습니다. 이를 통해 로컬 디스크에 대한 읽기 및 쓰기를 줄이고 디스크 공간을 대폭 절약할 수 있습니다.

[consolidated object storage settings](../object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form)를 사용해야 합니다.

### Object storage로 마이그레이션 {#migrating-to-object-storage}

LFS 개체를 로컬 스토리지에서 object storage로 마이그레이션할 수 있습니다. 처리는 백그라운드에서 수행되며 다운타임이 필요하지 않습니다.

1. [object storage 구성](../object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form)
1. LFS 개체를 마이그레이션합니다:

   {{< tabs >}}

   {{< tab title="Linux 패키지(Omnibus)" >}}

   ```shell
   sudo gitlab-rake gitlab:lfs:migrate
   ```

   {{< /tab >}}

   {{< tab title="Docker" >}}

   ```shell
   sudo docker exec -t <container name> gitlab-rake gitlab:lfs:migrate
   ```

   {{< /tab >}}

   {{< tab title="소스에서 직접 컴파일(source)" >}}

   ```shell
   sudo -u git -H bundle exec rake gitlab:lfs:migrate RAILS_ENV=production
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. 선택사항. PostgreSQL 콘솔을 사용하여 진행 상황을 추적하고 모든 작업 LFS 개체가 성공적으로 마이그레이션되었는지 확인합니다.
   1. PostgreSQL 콘솔을 엽니다:

      {{< tabs >}}

      {{< tab title="Linux 패키지(Omnibus)" >}}

      ```shell
      sudo gitlab-psql
      ```

      {{< /tab >}}

      {{< tab title="Docker" >}}

      ```shell
      sudo docker exec -it <container_name> /bin/bash
      gitlab-psql
      ```

      {{< /tab >}}

      {{< tab title="소스에서 직접 컴파일(source)" >}}

      ```shell
      sudo -u git -H psql -d gitlabhq_production
      ```

      {{< /tab >}}

      {{< /tabs >}}

   1. 다음 SQL 쿼리로 모든 LFS 파일이 object storage로 마이그레이션되었는지 확인합니다. `objectstg`의 수는 `total`과(와) 같아야 합니다:

      ```shell
      gitlabhq_production=# SELECT count(*) AS total, sum(case when file_store = '1' then 1 else 0 end) AS filesystem, sum(case when file_store = '2' then 1 else 0 end) AS objectstg FROM lfs_objects;

      total | filesystem | objectstg
      ------+------------+-----------
       2409 |          0 |      2409
      ```

1. `lfs-objects` 디렉토리에 디스크 상의 파일이 없는지 확인합니다:

   {{< tabs >}}

   {{< tab title="Linux 패키지(Omnibus)" >}}

   ```shell
   sudo find /var/opt/gitlab/gitlab-rails/shared/lfs-objects -type f | grep -v tmp | wc -l
   ```

   {{< /tab >}}

   {{< tab title="Docker" >}}

   `/var/opt/gitlab`을(를) `/srv/gitlab`로 마운트했다고 가정합니다:

   ```shell
   sudo find /srv/gitlab/gitlab-rails/shared/lfs-objects -type f | grep -v tmp | wc -l
   ```

   {{< /tab >}}

   {{< tab title="소스에서 직접 컴파일(source)" >}}

   ```shell
   sudo find /home/git/gitlab/shared/lfs-objects -type f | grep -v tmp | wc -l
   ```

   {{< /tab >}}

   {{< /tabs >}}

### 로컬 스토리지로 다시 마이그레이션 {#migrating-back-to-local-storage}

> [!note]
> Helm 차트의 경우 [object storage](https://docs.gitlab.com/charts/advanced/external-object-storage/)를 사용해야 합니다.

로컬 스토리지로 다시 마이그레이션하려면:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. LFS 개체를 마이그레이션합니다:

   ```shell
   sudo gitlab-rake gitlab:lfs:migrate_to_local
   ```

1. `/etc/gitlab/gitlab.rb`을(를) 편집하고 LFS 개체에 대해 [object storage 비활성화](../object_storage.md#disable-object-storage-for-specific-features):

   ```ruby
   gitlab_rails['object_store']['objects']['lfs']['enabled'] = false
   ```

1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. LFS 개체를 마이그레이션합니다:

   ```shell
   sudo docker exec -t <container name> gitlab-rake gitlab:lfs:migrate_to_local
   ```

1. `docker-compose.yml`을(를) 편집하고 LFS 개체에 대해 object storage를 비활성화합니다:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['object_store']['objects']['lfs']['enabled'] = false
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="소스에서 직접 컴파일(source)" >}}

1. LFS 개체를 마이그레이션합니다:

   ```shell
   sudo -u git -H bundle exec rake gitlab:lfs:migrate_to_local RAILS_ENV=production
   ```

1. `/home/git/gitlab/config/gitlab.yml`을(를) 편집하고 LFS 개체에 대해 object storage를 비활성화합니다:

   ```yaml
   production: &base
     object_store:
       objects:
         lfs:
           enabled: false
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

## 순수 SSH 전송 프로토콜 {#pure-ssh-transfer-protocol}

{{< history >}}

- GitLab 17.2에서 [도입되었습니다](https://gitlab.com/groups/gitlab-org/-/epics/11872).
- GitLab 17.3에서 Helm 차트(Kubernetes)에 [도입되었습니다](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/3845).

{{< /history >}}

> [!warning]
> 이 기능은 [알려진 문제](https://github.com/git-lfs/git-lfs/issues/5880) 의 영향을 받습니다([Git LFS 3.6.0](https://github.com/git-lfs/git-lfs/blob/main/CHANGELOG.md#360-20-november-2024)에서 해결됨). 순수 SSH 프로토콜을 사용하여 여러 Git LFS 개체가 있는 리포지토리를 복제하면 `nil` 포인터 참조로 인해 클라이언트가 충돌할 수 있습니다.

[`git-lfs` 3.0.0](https://github.com/git-lfs/git-lfs/blob/main/CHANGELOG.md#300-24-sep-2021)은 HTTP 대신 SSH를 전송 프로토콜로 사용할 수 있는 지원이 릴리스되었습니다. SSH는 `git-lfs` 명령줄 도구에 의해 투명하게 처리됩니다.

순수 SSH 프로토콜 지원이 활성화되고 `git`이 SSH를 사용하도록 구성되면 모든 LFS 작업이 SSH를 통해 이루어집니다. 예를 들어 Git 원격이 `git@gitlab.com:gitlab-org/gitlab.git`일 때입니다. `git`과(와) `git-lfs`를 다른 프로토콜을 사용하도록 구성할 수 없습니다. 버전 3.0부터 `git-lfs`는 순수 SSH 프로토콜을 먼저 사용하려고 시도하며, 지원이 활성화되지 않았거나 사용 가능하지 않으면 HTTP로 대체됩니다.

전제 조건:

- `git-lfs` 버전은 [v3.5.1](https://github.com/git-lfs/git-lfs/releases/tag/v3.5.1) 이상이어야 합니다.

Git LFS를 순수 SSH 프로토콜을 사용하도록 전환하려면:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을 편집합니다:

   ```ruby
   gitlab_shell['lfs_pure_ssh_protocol'] = true
   ```

1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을 편집합니다:

   ```yaml
   gitlab:
     gitlab-shell:
       config:
         lfs:
           pureSSHProtocol: true
   ```

1. 파일을 저장하고 새 값을 적용합니다:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`을 편집합니다:

   ```yaml
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_shell['lfs_pure_ssh_protocol'] = true
   ```

1. 파일을 저장하고 GitLab 및 해당 서비스를 다시 시작합니다:

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="소스에서 직접 컴파일(source)" >}}

1. `/home/git/gitlab-shell/config.yml`을 편집합니다:

   ```yaml
   lfs:
      pure_ssh_protocol: true
   ```

1. 파일을 저장하고 GitLab Shell을 다시 시작합니다:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab-shell.target

   # For systems running SysV init
   sudo service gitlab-shell restart
   ```

{{< /tab >}}

{{< /tabs >}}

## 스토리지 통계 {#storage-statistics}

다음에서 그룹 및 프로젝트의 LFS 개체에 사용되는 총 스토리지를 볼 수 있습니다:

- **운영자** 영역
- [groups](../../api/groups.md) 및 [projects](../../api/projects.md) API

> [!note]
> 스토리지 통계는 각 LFS 개체를 프로젝트로 링크하는 모든 것에 대해 계산합니다.

## 관련 항목 {#related-topics}

- 블로그 게시물:  [Git LFS 시작하기](https://about.gitlab.com/blog/getting-started-with-git-lfs-tutorial/)
- 사용자 설명서:  [Git Large File Storage(LFS)](../../topics/git/lfs/_index.md)

## 문제 해결 {#troubleshooting}

### LFS 개체 누락 {#missing-lfs-objects}

LFS 개체 누락에 대한 오류는 다음 상황 중 하나에서 발생할 수 있습니다:

- LFS 개체를 디스크에서 object storage로 마이그레이션할 때 다음과 같은 오류 메시지가 표시됩니다:

  ```plaintext
  ERROR -- : Failed to transfer LFS object
  006622269c61b41bf14a22bbe0e43be3acf86a4a446afb4250c3794ea47541a7
  with error: No such file or directory @ rb_sysopen -
  /var/opt/gitlab/gitlab-rails/shared/lfs-objects/00/66/22269c61b41bf14a22bbe0e43be3acf86a4a446afb4250c3794ea47541a7
  ```

   (가독성을 위해 줄 바꿈이 추가되었습니다.)

- [LFS 개체의 무결성 검사](../raketasks/check.md#uploaded-files-integrity)를 `VERBOSE=1` 매개 변수로 실행할 때입니다.

데이터베이스에 디스크에 없는 LFS 개체의 레코드가 있을 수 있습니다. 데이터베이스 항목은 [개체의 새 복사본이 푸시되는 것을 방지할](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/49241) 수 있습니다. 이러한 참조를 삭제하려면:

1. [rails 콘솔 시작](../operations/rails_console.md)
1. rails 콘솔에서 누락된 것으로 보고되는 개체를 쿼리하여 파일 경로를 반환합니다:

   ```ruby
   lfs_object = LfsObject.find_by(oid: '006622269c61b41bf14a22bbe0e43be3acf86a4a446afb4250c3794ea47541a7')
   lfs_object.file.path
   ```

1. 디스크 또는 object storage에 존재하는지 확인합니다:

   ```shell
   ls -al /var/opt/gitlab/gitlab-rails/shared/lfs-objects/00/66/22269c61b41bf14a22bbe0e43be3acf86a4a446afb4250c3794ea47541a7
   ```

1. 파일이 없으면 Rails 콘솔을 사용하여 데이터베이스 레코드를 제거합니다:

   ```ruby
   # First delete the parent records and then destroy the record itself
   lfs_object.lfs_objects_projects.destroy_all
   lfs_object.destroy
   ```

#### 여러 누락된 LFS 개체 제거 {#remove-multiple-missing-lfs-objects}

여러 누락된 LFS 개체에 대한 참조를 한 번에 제거하려면:

1. [GitLab Rails 콘솔](../operations/rails_console.md#starting-a-rails-console-session)을(를) 엽니다.
1. 다음 스크립트를 실행합니다:

   ```ruby
   lfs_files_deleted = 0
   LfsObject.find_each do |lfs_file|
     next if lfs_file.file.file.exists?
     lfs_files_deleted += 1
     p "LFS file with ID #{lfs_file.id} and path #{lfs_file.file.path} is missing."
     # lfs_file.lfs_objects_projects.destroy_all     # Uncomment to delete parent records
     # lfs_file.destroy                              # Uncomment to destroy the LFS object reference
   end
   p "Count of identified/destroyed invalid references: #{lfs_files_deleted}"
   ```

이 스크립트는 데이터베이스의 모든 누락된 LFS 개체를 식별합니다. 레코드를 삭제하기 전에:

- 먼저 확인을 위해 누락된 파일에 대한 정보를 출력합니다.
- 주석 처리된 줄은 실수로 인한 삭제를 방지합니다. 주석 처리를 제거하면 스크립트가 식별된 레코드를 삭제합니다.
- 스크립트는 비교를 위해 삭제된 레코드의 최종 개수를 자동으로 출력합니다.

### TLS v1.3 서버에서 LFS 명령 실패 {#lfs-commands-fail-on-tls-v13-server}

GitLab을 [TLS v1.2 비활성화](https://docs.gitlab.com/omnibus/settings/nginx/) 하도록 구성하고 TLS v1.3 연결만 활성화하면 LFS 작업에 [Git LFS 클라이언트](https://git-lfs.com/) 버전 2.11.0 이상이 필요합니다. 버전 2.11.0보다 이전인 Git LFS 클라이언트를 사용하면 GitLab에서 오류를 표시합니다:

```plaintext
batch response: Post https://username:***@gitlab.example.com/tool/releases.git/info/lfs/objects/batch: remote error: tls: protocol version not supported
error: failed to fetch some objects from 'https://username:[MASKED]@gitlab.example.com/tool/releases.git/info/lfs'
```

TLS v1.3 구성 GitLab 서버를 통해 GitLab CI를 사용할 때 [GitLab Runner로 업그레이드](https://docs.gitlab.com/runner/install/) 해야 합니다. 버전 13.2.0 이상으로 업데이트하여 포함된 [GitLab Runner Helper 이미지](https://docs.gitlab.com/runner/configuration/advanced-configuration/#helper-image)와 함께 업데이트된 Git LFS 클라이언트 버전을 받습니다.

설치된 Git LFS 클라이언트의 버전을 확인하려면 이 명령을 실행합니다:

```shell
git lfs version
```

### `Connection refused` 오류 {#connection-refused-errors}

LFS 개체를 푸시하거나 미러링할 때 다음과 같은 오류가 표시되면:

- `dial tcp <IP>:443: connect: connection refused`
- `Connection refused - connect(2) for \"<target-or-proxy-IP>\" port 443`

방화벽 또는 프록시 규칙이 연결을 종료할 수 있습니다.

표준 Unix 도구 또는 수동 Git 푸시로 연결을 확인한 후 성공하면 규칙이 요청 크기와 관련될 수 있습니다.

### PDF 파일 보기 오류 {#error-viewing-a-pdf-file}

LFS가 object storage로 구성되고 `proxy_download`이 `false`로 설정된 경우 웹 브라우저에서 PDF 파일을 미리 볼 때 오류가 표시될 수 있습니다:

```plaintext
An error occurred while loading the file. Please try again later.
```

이는 CORS(Cross-Origin Resource Sharing) 제한으로 인해 발생합니다. 브라우저가 object storage에서 PDF를 로드하려고 시도하지만 GitLab 도메인이 object storage 도메인과 다르기 때문에 object storage 제공자가 요청을 거부합니다.

이 문제를 해결하려면 object storage 제공자의 CORS 설정을 구성하여 GitLab 도메인을 허용합니다. 자세한 내용은 다음 설명서를 참조하세요:

1. [AWS S3](https://repost.aws/knowledge-center/s3-configure-cors)
1. [Google Cloud Storage](https://cloud.google.com/storage/docs/using-cors)
1. [Azure Storage](https://learn.microsoft.com/en-us/rest/api/storageservices/cross-origin-resource-sharing--cors--support-for-the-azure-storage-services).

### `Forking in progress` 메시지에서 포크 작업 중단 {#fork-operation-stuck-on-forking-in-progress-message}

여러 LFS 파일이 있는 프로젝트를 포크하면 작업이 `Forking in progress` 메시지와 함께 중단될 수 있습니다. 이 문제가 발생하면 다음 단계에 따라 문제를 진단하고 해결합니다:

1. [`exceptions_json.log`](../logs/_index.md#exceptions_jsonlog) 파일에서 다음 오류 메시지를 확인합니다:

   ```plaintext
   "error_message": "Unable to fork project 12345 for repository
   @hashed/11/22/encoded-path -> @hashed/33/44/encoded-new-path:
   Source project has too many LFS objects"
   ```

   이 오류는 [issue 476693](https://gitlab.com/gitlab-org/gitlab/-/issues/476693)에 설명된 대로 100,000개의 LFS 파일의 기본 제한에 도달했음을 나타냅니다.

1. `GITLAB_LFS_MAX_OID_TO_FETCH` 변수의 값을 늘립니다:

   1. 구성 파일 `/etc/gitlab/gitlab.rb`을(를) 엽니다.
   1. 변수를 추가하거나 업데이트합니다:

      ```ruby
      gitlab_rails['env'] = {
         "GITLAB_LFS_MAX_OID_TO_FETCH" => "NEW_VALUE"
      }
      ```

      `NEW_VALUE`를 요구 사항에 따라 숫자로 바꿉니다.

1. 변경 사항을 적용합니다. 다음을 실행합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

   자세한 내용은 [Linux 패키지 설치 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)을(를) 참조하세요.

1. 포크 작업을 반복합니다.

> [!note]
> GitLab Helm 차트의 경우 [`extraEnv`](https://docs.gitlab.com/charts/charts/globals/#extraenv)을(를) 사용하여 환경 변수 `GITLAB_LFS_MAX_OID_TO_FETCH`를 구성합니다.
