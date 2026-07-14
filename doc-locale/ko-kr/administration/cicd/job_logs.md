---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 작업 로그
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

작업 로그는 러너가 작업을 처리하는 동안 전송됩니다. 작업 페이지, 파이프라인, 이메일 알림 등 여러 위치에서 로그를 확인할 수 있습니다.

## 데이터 플로우 {#data-flow}

일반적으로 작업 로그에는 `log`과 `archived log` 두 가지 상태가 있습니다. 다음 표에서 로그가 거치는 단계를 확인할 수 있습니다:

| 단계          | 상태        | 조건               | 데이터 플로우                                | 저장된 경로 |
| -------------- | ------------ | ----------------------- | -----------------------------------------| ----------- |
| 1: 패칭    | 로그          | 작업이 실행 중일 때   | 러너 => Puma => 파일 저장소 | `#{ROOT_PATH}/gitlab-ci/builds/#{YYYY_mm}/#{project_id}/#{job_id}.log` |
| 2: 아카이빙   | 보관된 로그 | 작업이 완료된 후 | Sidekiq이 로그를 아티팩트 폴더로 이동    | `#{ROOT_PATH}/gitlab-rails/shared/artifacts/#{disk_hash}/#{YYYY_mm_dd}/#{job_id}/#{job_artifact_id}/job.log` |
| 3: 업로드   | 보관된 로그 | 로그가 보관된 후 | Sidekiq이 보관된 로그를 [오브젝트 스토리지](#uploading-logs-to-object-storage)로 이동(구성된 경우) | `#{bucket_name}/#{disk_hash}/#{YYYY_mm_dd}/#{job_id}/#{job_artifact_id}/job.log` |

`ROOT_PATH` 값은 환경에 따라 다릅니다:

- Linux 패키지의 경우 `/var/opt/gitlab`입니다.
- 자체 컴파일된 설치의 경우 `/home/git/gitlab`입니다.

## 작업 로그 로컬 위치 변경 {#changing-the-job-logs-local-location}

> [!note]
> Docker 설치의 경우 데이터를 마운트하는 경로를 변경할 수 있습니다. Helm 차트의 경우 오브젝트 스토리지를 사용합니다.

작업 로그가 저장된 위치를 변경하려면:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. 선택사항. 기존 작업 로그가 있는 경우, Sidekiq을 임시로 중지하여 지속적 통합 데이터 처리를 일시 중지하세요:

   ```shell
   sudo gitlab-ctl stop sidekiq
   ```

1. `/etc/gitlab/gitlab.rb`에서 새 저장소 위치를 설정하세요:

   ```ruby
   gitlab_ci['builds_directory'] = '/mnt/gitlab-ci/builds'
   ```

1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. `rsync`을 사용하여 작업 로그를 현재 위치에서 새 위치로 이동하세요:

   ```shell
   sudo rsync -avzh --remove-source-files --ignore-existing --progress /var/opt/gitlab/gitlab-ci/builds/ /mnt/gitlab-ci/builds/
   ```

   새 작업 로그가 같은 로그의 이전 버전으로 덮어써지지 않도록 `--ignore-existing`을 사용하세요.

1. 지속적 통합 데이터 처리를 일시 중지하도록 선택한 경우 Sidekiq을 다시 시작할 수 있습니다:

   ```shell
   sudo gitlab-ctl start sidekiq
   ```

1. 이전 작업 로그 저장소 위치를 제거하세요:

   ```shell
   sudo rm -rf /var/opt/gitlab/gitlab-ci/builds
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. 선택사항. 기존 작업 로그가 있는 경우, Sidekiq을 임시로 중지하여 지속적 통합 데이터 처리를 일시 중지하세요:

   ```shell
   # For systems running systemd
   sudo systemctl stop gitlab-sidekiq

   # For systems running SysV init
   sudo service gitlab stop
   ```

1. `/home/git/gitlab/config/gitlab.yml`을 편집하여 새 저장소 위치를 설정하세요:

   ```yaml
   production: &base
     gitlab_ci:
       builds_path: /mnt/gitlab-ci/builds
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

1. `rsync`을 사용하여 작업 로그를 현재 위치에서 새 위치로 이동하세요:

   ```shell
   sudo rsync -avzh --remove-source-files --ignore-existing --progress /home/git/gitlab/builds/ /mnt/gitlab-ci/builds/
   ```

   새 작업 로그가 같은 로그의 이전 버전으로 덮어써지지 않도록 `--ignore-existing`을 사용하세요.

1. 지속적 통합 데이터 처리를 일시 중지하도록 선택한 경우 Sidekiq을 다시 시작할 수 있습니다:

   ```shell
   # For systems running systemd
   sudo systemctl start gitlab-sidekiq

   # For systems running SysV init
   sudo service gitlab start
   ```

1. 이전 작업 로그 저장소 위치를 제거하세요:

   ```shell
   sudo rm -rf /home/git/gitlab/builds
   ```

{{< /tab >}}

{{< /tabs >}}

## 오브젝트 스토리지에 로그 업로드 {#uploading-logs-to-object-storage}

보관된 로그는 [작업 아티팩트](job_artifacts.md)로 간주됩니다. 따라서 [오브젝트 스토리지 통합을 설정](job_artifacts.md#using-object-storage)하면, 작업 로그가 다른 작업 아티팩트와 함께 자동으로 마이그레이션됩니다.

[데이터 플로우](#data-flow)의 "단계 3: 업로드"를 참조하여 프로세스를 학습하세요.

## 최대 로그 파일 크기 {#maximum-log-file-size}

GitLab의 작업 로그 파일 크기 제한은 기본적으로 100메가바이트입니다. 제한을 초과하는 모든 작업은 실패로 표시되고 러너에 의해 삭제됩니다. 자세한 내용은 [작업 로그의 최대 파일 크기](../instance_limits.md#maximum-file-size-for-job-logs)를 참조하세요.

## 로컬 디스크 사용 방지 {#prevent-local-disk-usage}

작업 로그에 대한 로컬 디스크 사용을 방지하려면 다음 옵션 중 하나를 사용할 수 있습니다:

- [증분 로깅](#configure-incremental-logging)을 켜세요.
- [작업 로그 위치](#changing-the-job-logs-local-location)를 NFS 드라이브로 설정하세요.

## 작업 로그를 제거하는 방법 {#how-to-remove-job-logs}

이전 작업 로그를 자동으로 만료하는 방법은 없습니다. 그러나 너무 많은 공간을 차지하는 경우 로그를 제거해도 안전합니다. 로그를 수동으로 제거하면, UI의 작업 출력이 비어있게 됩니다.

GitLab CLI를 사용하여 작업 로그를 삭제하는 방법에 대한 자세한 내용은 [작업 로그 삭제](../../user/storage_management_automation.md#delete-job-logs)를 참조하세요.

Helm 차트의 경우, 오브젝트 스토리지와 함께 제공되는 저장소 관리 도구를 사용합니다.

또는 셸 명령으로 작업 로그를 삭제할 수 있습니다. 예를 들어, 60일 이상 된 모든 작업 로그를 삭제하려면, GitLab 인스턴스의 셸에서 다음 명령을 실행하세요.

> [!warning]
> 다음 명령은 로그 파일을 영구적으로 삭제하며 되돌릴 수 없습니다.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

```shell
find /var/opt/gitlab/gitlab-rails/shared/artifacts -name "job.log" -mtime +60 -delete
```

{{< /tab >}}

{{< tab title="Docker" >}}

`/var/opt/gitlab`을 `/srv/gitlab`로 마운트했다고 가정하면:

```shell
find /srv/gitlab/gitlab-rails/shared/artifacts -name "job.log" -mtime +60 -delete
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

```shell
find /home/git/gitlab/shared/artifacts -name "job.log" -mtime +60 -delete
```

{{< /tab >}}

{{< /tabs >}}

로그가 삭제된 후, [업로드된 파일의 무결성](../raketasks/check.md#uploaded-files-integrity)을 확인하는 Rake 작업을 실행하여 손상된 파일 참조를 찾을 수 있습니다. 자세한 내용은 [누락된 아티팩트에 대한 참조 삭제](../raketasks/check.md#delete-references-to-missing-artifacts) 방법을 참조하세요.

## 증분 로깅 {#incremental-logging}

증분 로깅은 작업 로그가 처리되고 저장되는 방식을 변경하여 확장 배포에서의 성능을 향상합니다.

기본적으로 작업 로그는 러너r에서 청크 단위로 전송되고 디스크에 임시로 캐시됩니다. 작업이 완료되면, 백그라운드 작업이 로그를 아티팩트 디렉터리 또는 구성된 경우 오브젝트 스토리지로 보관합니다.

증분 로깅을 사용하면, 로그는 파일 저장소 대신 Redis 및 영구 저장소에 저장됩니다. 이 방식은 다음과 같은 이점이 있습니다:

- 작업 로그에 대한 로컬 디스크 사용을 방지합니다.
- Rails와 Sidekiq 서버 간의 NFS 공유 필요를 제거합니다.
- 다중 노드 설치에서의 성능을 향상합니다.

증분 로깅 프로세스는 Redis를 임시 저장소로 사용하며 다음과 같이 진행됩니다:

1. 러너가 GitLab에서 작업을 선택합니다.
1. 러너가 GitLab에 로그 조각을 전송합니다.
1. GitLab은 `Gitlab::Redis::TraceChunks` 네임스페이스에 데이터를 추가합니다.
1. Redis의 데이터가 128KB에 도달하면, 데이터는 영구 저장소로 플러시됩니다.
1. 작업이 완료될 때까지 이전 단계가 반복됩니다.
1. 작업이 완료된 후, GitLab은 로그를 보관할 Sidekiq 워커를 스케줄합니다.
1. Sidekiq 워커는 로그를 오브젝트 스토리지로 보관하고 임시 데이터를 정리합니다.

Redis Cluster는 증분 로깅으로 지원되지 않습니다. 자세한 내용은 [이슈 224171](https://gitlab.com/gitlab-org/gitlab/-/issues/224171)을 참조하세요.

### 증분 로깅 구성 {#configure-incremental-logging}

증분 로깅을 켜기 전에, CI/CD 아티팩트, 로그 및 빌드에 대해 [오브젝트 스토리지를 구성](job_artifacts.md#using-object-storage)해야 합니다. 증분 로깅이 켜진 후, 파일을 디스크에 쓸 수 없으며, 잘못된 구성에 대한 보호가 없습니다.

증분 로그를 켜면, 실행 중인 작업 로그는 디스크에 계속 쓰여지지만, 새 작업은 증분 로깅을 사용합니다.

증분 로깅을 끄면, 실행 중인 작업은 증분 로깅을 계속 사용하지만, 새 작업은 디스크에 씁니다.

증분 로깅을 구성하려면:

- [관리 영역](../settings/continuous_integration.md#access-job-log-settings) 또는 [설정 API](../../api/settings.md)의 설정을 사용합니다.
