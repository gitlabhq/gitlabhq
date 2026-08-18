---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 작업 아티팩트 문제 해결
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[작업 아티팩트](job_artifacts.md)로 작업할 때 다음의 문제가 발생할 수 있습니다.

## 특정 아티팩트를 검색하지 않는 작업 {#job-does-not-retrieve-certain-artifacts}

기본적으로 작업은 이전 스테이지의 모든 아티팩트를 가져오지만, `dependencies` 또는 `needs`를 사용하는 작업은 기본적으로 모든 작업의 아티팩트를 가져오지 않습니다.

이러한 키워드를 사용하면 작업의 일부만 아티팩트를 가져옵니다. 이 키워드를 사용하여 아티팩트를 가져오는 방법에 대한 정보는 키워드 참조를 검토하세요:

- [`dependencies`](../yaml/_index.md#dependencies)
- [`needs`](../yaml/_index.md#needs)
- [`needs:artifacts`](../yaml/_index.md#needsartifacts)

## 작업 아티팩트가 너무 많은 디스크 공간을 사용함 {#job-artifacts-use-too-much-disk-space}

작업 아티팩트가 너무 많은 디스크 공간을 사용하는 경우 [작업 아티팩트 관리 설명서](../../administration/cicd/job_artifacts_troubleshooting.md#job-artifacts-using-too-much-disk-space)를 참조하세요.

## 오류 메시지 `No files to upload` {#error-message-no-files-to-upload}

이 메시지는 러너가 업로드할 파일을 찾지 못했을 때 작업 로그에 나타납니다. 파일 경로가 잘못되었거나 파일이 생성되지 않았습니다. 작업 로그에서 파일명을 지정하고 생성되지 않은 이유를 설명하는 다른 오류 또는 경고를 확인할 수 있습니다.

더 자세한 작업 로그를 보려면 [CI/CD 디버그 로깅 활성화](../variables/variables_troubleshooting.md#enable-debug-logging)를 수행하고 작업을 다시 시도할 수 있습니다. 이 로깅은 파일이 생성되지 않은 이유에 대한 자세한 정보를 제공할 수 있습니다.

## Windows 러너에서 dotenv 아티팩트를 업로드할 때 오류 메시지 `FATAL: invalid argument` {#error-message-fatal-invalid-argument-when-uploading-a-dotenv-artifact-on-a-windows-runner}

PowerShell `echo` 명령은 UCS-2 LE BOM(바이트 순서 표시) 인코딩으로 파일을 작성하지만 UTF-8만 지원됩니다. [`dotenv`](../yaml/artifacts_reports.md) 아티팩트를 `echo`로 생성하려고 하면 `FATAL: invalid argument` 오류가 발생합니다.

대신 UTF-8을 사용하는 PowerShell `Add-Content`을 사용하세요:

```yaml
test-job:
  stage: test
  tags:
    - windows
  script:
    - echo "test job"
    - Add-Content -Path build.env -Value "MY_ENV_VAR=true"
  artifacts:
    reports:
      dotenv: build.env
```

## 작업 아티팩트가 만료되지 않음 {#job-artifacts-do-not-expire}

일부 작업 아티팩트가 예상대로 만료되지 않으면 [**가장 최근에 성공한 작업의 아티팩트 유지**](job_artifacts.md#keep-artifacts-from-most-recent-successful-jobs) 설정이 활성화되었는지 확인하세요.

이 설정이 활성화되면 각 ref의 최근 성공한 파이프라인의 작업 아티팩트는 만료되지 않으며 삭제되지 않습니다.

## 오류 메시지 `This job could not start because it could not retrieve the needed artifacts.` {#error-message-this-job-could-not-start-because-it-could-not-retrieve-the-needed-artifacts}

작업이 시작되지 않고 필요한 아티팩트를 가져올 수 없는 경우 이 오류 메시지가 반환됩니다. 이 오류는 다음과 같은 경우에 반환됩니다:

- 작업의 종속성을 찾을 수 없습니다. 기본적으로 이후 스테이지의 작업은 이전 스테이지의 모든 작업의 아티팩트를 가져오므로 이전 작업은 모두 종속성으로 간주됩니다. 작업이 [`dependencies`](../yaml/_index.md#dependencies) 키워드를 사용하는 경우 나열된 작업만 종속성으로 간주됩니다.
- 아티팩트가 이미 만료되었습니다. [`artifacts:expire_in`](../yaml/_index.md#artifactsexpire_in)를 사용하여 더 긴 만료 시간을 설정할 수 있습니다.
- 작업은 권한이 부족하여 관련 리소스에 액세스할 수 없습니다.

작업이 [`needs:artifacts`](../yaml/_index.md#needsartifacts) 키워드를 사용하는 경우 다음의 추가 문제 해결 단계를 참조하세요:

- [`needs:project`](#for-a-job-configured-with-needsproject)
- [`needs:pipeline:job`](#for-a-job-configured-with-needspipelinejob)

### `needs:project`로 구성된 작업 {#for-a-job-configured-with-needsproject}

`could not retrieve the needed artifacts.` 오류는 [`needs:project`](../yaml/_index.md#needsproject)를 사용하는 작업에서 발생할 수 있습니다:

```yaml
rspec:
  needs:
    - project: my-group/my-project
      job: dependency-job
      ref: master
      artifacts: true
```

이 오류를 해결하려면 다음을 확인하세요:

- 프로젝트 `my-group/my-project`는 Premium 구독 계획이 있는 그룹에 있습니다.
- 작업을 실행하는 사용자는 `my-group/my-project`의 리소스에 액세스할 수 있습니다.
- `project`, `job` 및 `ref` 조합이 존재하고 원하는 종속성을 결과로 생성합니다.
- 사용 중인 모든 변수가 올바른 값으로 평가됩니다.

`CI_JOB_TOKEN`을 사용하는 경우 토큰을 프로젝트의 [allowlist](ci_job_token.md#control-job-token-access-to-your-project)에 추가하여 다른 프로젝트의 아티팩트를 가져옵니다.

### `needs:pipeline:job`로 구성된 작업 {#for-a-job-configured-with-needspipelinejob}

`could not retrieve the needed artifacts.` 오류는 [`needs:pipeline:job`](../yaml/_index.md#needspipelinejob)를 사용하는 작업에서 발생할 수 있습니다:

```yaml
rspec:
  needs:
    - pipeline: $UPSTREAM_PIPELINE_ID
      job: dependency-job
      artifacts: true
```

이 오류를 해결하려면 다음을 확인하세요:

- `$UPSTREAM_PIPELINE_ID` 는 현재 파이프라인의 상위-하위 파이프라인 계층 구조에서 사용 가능합니다.
- `pipeline` 및 `job` 조합이 존재하고 기존 파이프라인으로 확인됩니다.
- `dependency-job`은 실행되었으며 성공적으로 완료되었습니다.

## 업그레이드 후 작업에 `UnlockPipelinesInQueueWorker`이 표시됨 {#jobs-show-unlockpipelinesinqueueworker-after-an-upgrade}

작업이 중단되고 `UnlockPipelinesInQueueWorker`을 나타내는 오류가 표시될 수 있습니다.

이 문제는 업그레이드 후에 발생합니다.

해결 방법은 `ci_unlock_pipelines_extra_low` 기능 플래그를 활성화하는 것입니다. 기능 플래그를 전환하려면 관리자여야 합니다.

GitLab.com: 

- 다음 [ChatOps](../chatops/_index.md) 명령을 실행하세요:

  ```ruby
  /chatops gitlab run feature set ci_unlock_pipelines_extra_low true
  ```

GitLab Self-Managed: 

- [기능 플래그 활성화](../../administration/feature_flags/_index.md) 이름 `ci_unlock_pipelines_extra_low`.

자세한 내용은 [머지 리퀘스트 140318](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140318#note_1718600424)의 댓글을 참조하세요.
