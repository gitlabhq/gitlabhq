---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 작업 아티팩트 관리
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

이것은 관리 설명서입니다. GitLab CI/CD 파이프라인에서 아티팩트를 사용하는 방법을 알아보려면 [작업 아티팩트 구성 설명서](../../ci/jobs/job_artifacts.md)를 참조하세요.

아티팩트는 작업이 완료된 후 연결된 파일 및 디렉토리 목록입니다. 이 기능은 모든 GitLab 설치에서 기본적으로 활성화됩니다.

## 작업 아티팩트 비활성화 {#disabling-job-artifacts}

아티팩트를 사이트 전체에서 비활성화하려면:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   gitlab_rails['artifacts_enabled'] = false
   ```

1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을(를) 편집합니다:

   ```yaml
   global:
     appConfig:
       artifacts:
         enabled: false
   ```

1. 파일을 저장하고 새 값을 적용합니다:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`을(를) 편집합니다:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['artifacts_enabled'] = false
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. `/home/git/gitlab/config/gitlab.yml`을(를) 편집합니다:

   ```yaml
   production: &base
     artifacts:
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

## 작업 아티팩트 저장 {#storing-job-artifacts}

러너는 작업 아티팩트를 포함하는 아카이브를 GitLab에 업로드할 수 있습니다. 기본적으로 이는 작업이 성공할 때 수행되지만 실패 시 또는 항상 [`artifacts:when`](../../ci/yaml/_index.md#artifactswhen) 매개변수를 사용하여 수행할 수도 있습니다.

대부분의 아티팩트는 러너에 의해 코디네이터로 전송되기 전에 압축됩니다. 이에 대한 예외는 [보고서 아티팩트](../../ci/yaml/_index.md#artifactsreports)로, 업로드 후 압축됩니다.

### 로컬 스토리지 사용 {#using-local-storage}

Linux package를 사용하거나 직접 컴파일된 설치가 있는 경우 아티팩트가 로컬에 저장되는 위치를 변경할 수 있습니다.

> [!note]
> Docker 설치의 경우 데이터를 마운트하는 경로를 변경할 수 있습니다. Helm chart의 경우 [object storage](https://docs.gitlab.com/charts/advanced/external-object-storage/)를 사용하세요.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

아티팩트는 기본적으로 `/var/opt/gitlab/gitlab-rails/shared/artifacts`에 저장됩니다.

1. 저장소 경로를 `/mnt/storage/artifacts`로 변경하려면 `/etc/gitlab/gitlab.rb`를 편집하고 다음 줄을 추가하세요:

   ```ruby
   gitlab_rails['artifacts_path'] = "/mnt/storage/artifacts"
   ```

1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

아티팩트는 기본적으로 `/home/git/gitlab/shared/artifacts`에 저장됩니다.

1. 저장소 경로를 `/mnt/storage/artifacts`로 변경하려면 `/home/git/gitlab/config/gitlab.yml`를 편집하고 다음 줄을 추가하거나 수정하세요:

   ```yaml
   production: &base
     artifacts:
       enabled: true
       path: /mnt/storage/artifacts
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

### object storage 사용 {#using-object-storage}

GitLab이 설치된 로컬 디스크를 사용하여 아티팩트를 저장하지 않으려면 대신 AWS S3 같은 object storage를 사용할 수 있습니다.

GitLab을 object storage에 아티팩트를 저장하도록 구성하는 경우 [작업 로그에 대한 로컬 디스크 사용 제거](job_logs.md#prevent-local-disk-usage)를 고려할 수도 있습니다. 두 경우 모두 작업 로그는 작업이 완료될 때 아카이브되어 object storage로 이동됩니다.

> [!warning]
> 다중 서버 설정에서는 [작업 로그에 대한 로컬 디스크 사용 제거](job_logs.md#prevent-local-disk-usage) 옵션 중 하나를 사용해야 하며, 그렇지 않으면 작업 로그가 손실될 수 있습니다.

[통합 object storage 설정](../object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form)을 사용해야 합니다.

### object storage로 마이그레이션 {#migrating-to-object-storage}

작업 아티팩트를 로컬 스토리지에서 object storage로 마이그레이션할 수 있습니다. 처리는 백그라운드 워커에서 수행되며 **no downtime**이 필요합니다.

1. [object storage 구성](#using-object-storage)하세요.
1. 아티팩트 마이그레이션:

   {{< tabs >}}

   {{< tab title="Linux package (Omnibus)" >}}

   ```shell
   sudo gitlab-rake gitlab:artifacts:migrate
   ```

   {{< /tab >}}

   {{< tab title="Docker" >}}

   ```shell
   sudo docker exec -t <container name> gitlab-rake gitlab:artifacts:migrate
   ```

   {{< /tab >}}

   {{< tab title="Self-compiled (source)" >}}

   ```shell
   sudo -u git -H bundle exec rake gitlab:artifacts:migrate RAILS_ENV=production
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. 선택사항. PostgreSQL 콘솔을 사용하여 진행 상황을 추적하고 모든 작업 아티팩트가 성공적으로 마이그레이션되었는지 확인합니다.
   1. PostgreSQL 콘솔을 열세요:

      {{< tabs >}}

      {{< tab title="Linux package (Omnibus)" >}}

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

      {{< tab title="Self-compiled (source)" >}}

      ```shell
      sudo -u git -H psql -d gitlabhq_production
      ```

      {{< /tab >}}

      {{< /tabs >}}

   1. 다음 SQL 쿼리를 사용하여 모든 아티팩트가 object storage로 마이그레이션되었는지 확인합니다. `objectstg`의 수가 `total`와 같아야 합니다:

      ```shell
      gitlabhq_production=# SELECT count(*) AS total, sum(case when file_store = '1' then 1 else 0 end) AS filesystem, sum(case when file_store = '2' then 1 else 0 end) AS objectstg FROM p_ci_job_artifacts;

      total | filesystem | objectstg
      ------+------------+-----------
         19 |          0 |        19
      ```

1. `artifacts` 디렉토리에 디스크의 파일이 없는지 확인하세요:

   {{< tabs >}}

   {{< tab title="Linux package (Omnibus)" >}}

   ```shell
   sudo find /var/opt/gitlab/gitlab-rails/shared/artifacts -type f | grep -v tmp | wc -l
   ```

   {{< /tab >}}

   {{< tab title="Docker" >}}

   `/var/opt/gitlab`을 `/srv/gitlab`로 마운트했다고 가정하면:

   ```shell
   sudo find /srv/gitlab/gitlab-rails/shared/artifacts -type f | grep -v tmp | wc -l
   ```

   {{< /tab >}}

   {{< tab title="Self-compiled (source)" >}}

   ```shell
   sudo find /home/git/gitlab/shared/artifacts -type f | grep -v tmp | wc -l
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. [Geo](../geo/_index.md) 가 활성화된 경우 [모든 작업 아티팩트 재검증](../geo/replication/troubleshooting/synchronization_verification.md#reverify-one-component-on-all-sites)하세요.

경우에 따라 [orphan 아티팩트 파일 정리 Rake 작업](../raketasks/cleanup.md#remove-orphan-artifact-files)을 실행하여 orphan 아티팩트를 정리해야 합니다.

### object storage에서 로컬 스토리지로 마이그레이션 {#migrating-from-object-storage-to-local-storage}

아티팩트를 로컬 스토리지로 다시 마이그레이션하려면:

1. `gitlab-rake gitlab:artifacts:migrate_to_local`를 실행하세요.
1. [아티팩트 저장소를 선택적으로 비활성화](../object_storage.md#disable-object-storage-for-specific-features)하세요 `gitlab.rb`에서.
1. [GitLab 다시 구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)하세요.

GitLab 18.6 이전에는 원격에서 로컬 스토리지로의 마이그레이션으로 인해 [아티팩트가 잘못된 파일 이름으로 복사](job_artifacts_troubleshooting.md#job-artifacts-can-have-wrong-filenames)될 수 있었습니다.

## 아티팩트 만료 {#expiring-artifacts}

[`artifacts:expire_in`](../../ci/yaml/_index.md#artifactsexpire_in)를 사용하여 아티팩트의 만료를 설정하면 해당 날짜가 지난 직후에 삭제 표시됩니다. 그렇지 않으면 [아티팩트 만료 기본 설정](../settings/continuous_integration.md#set-default-artifacts-expiration)에 따라 만료됩니다.

아티팩트는 `expire_build_artifacts_worker` cron 작업에 의해 삭제되며, Sidekiq이 7분마다 실행합니다([Cron](../../topics/cron/_index.md) 구문에서 `*/7 * * * *`).

만료된 아티팩트가 삭제되는 기본 일정을 변경하려면:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`를 편집하고 다음 줄을 추가하세요(이미 존재하고 주석 처리된 경우 주석 해제). cron 구문으로 일정을 대체하세요:

   ```ruby
   gitlab_rails['expire_build_artifacts_worker_cron'] = "*/7 * * * *"
   ```

1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을(를) 편집합니다:

   ```yaml
   global:
     appConfig:
       cron_jobs:
         expire_build_artifacts_worker:
           cron: "*/7 * * * *"
   ```

1. 파일을 저장하고 새 값을 적용합니다:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`을(를) 편집합니다:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['expire_build_artifacts_worker_cron'] = "*/7 * * * *"
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. `/home/git/gitlab/config/gitlab.yml`을(를) 편집합니다:

   ```yaml
   production: &base
     cron_jobs:
       expire_build_artifacts_worker:
         cron: "*/7 * * * *"
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

## 아티팩트의 최대 파일 크기 설정 {#set-the-maximum-file-size-of-the-artifacts}

아티팩트가 활성화된 경우 [**운영자** 영역 설정](../settings/continuous_integration.md#set-maximum-artifacts-size)을 통해 아티팩트의 최대 파일 크기를 변경할 수 있습니다.

## 스토리지 통계 {#storage-statistics}

다음에서 그룹 및 프로젝트의 작업 아티팩트에 사용되는 총 스토리지를 볼 수 있습니다:

- **운영자** 영역
- [그룹](../../api/groups.md) 및 [프로젝트](../../api/projects.md) API

## 구현 세부사항 {#implementation-details}

GitLab이 아티팩트 아카이브를 받으면 [GitLab Workhorse](https://gitlab.com/gitlab-org/gitlab-workhorse)에 의해 아카이브 메타데이터 파일도 생성됩니다. 이 메타데이터 파일은 아티팩트 아카이브 자체에 위치한 모든 항목을 설명합니다. 메타데이터 파일은 이진 형식으로 되어 있으며 추가 Gzip 압축이 있습니다.

GitLab은 공간, 메모리 및 디스크 I/O를 절약하기 위해 아티팩트 아카이브를 추출하지 않습니다. 대신 모든 관련 정보를 포함하는 메타데이터 파일을 검사합니다. 이는 아티팩트가 많거나 아카이브가 매우 큰 파일일 때 특히 중요합니다.

특정 파일을 선택할 때 [GitLab Workhorse](https://gitlab.com/gitlab-org/gitlab-workhorse)가 아카이브에서 추출하고 다운로드가 시작됩니다. 이 구현은 공간, 메모리 및 디스크 I/O를 절약합니다.
