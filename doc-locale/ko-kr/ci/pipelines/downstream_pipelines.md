---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 상위-하위 파이프라인 및 다중 프로젝트 파이프라인을 트리거하고 관리합니다.
title: 다운스트림 파이프라인
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

다운스트림 파이프라인은 다른 파이프라인에 의해 트리거되는 모든 GitLab CI/CD 파이프라인입니다. 다운스트림 파이프라인은 이를 트리거한 업스트림 파이프라인과 독립적으로 동시에 실행됩니다.

- [상위-하위 파이프라인](downstream_pipelines.md#parent-child-pipelines)은 첫 번째 파이프라인과 동일한 프로젝트에서 트리거되는 다운스트림 파이프라인입니다.
- [다중 프로젝트 파이프라인](#multi-project-pipelines)은 첫 번째 파이프라인과 다른 프로젝트에서 트리거되는 다운스트림 파이프라인입니다.

경우에 따라 상위-하위 파이프라인과 다중 프로젝트 파이프라인을 비슷한 목적으로 사용할 수 있지만 [주요 차이점](pipeline_architectures.md)이 있습니다.

파이프라인 계층 구조는 기본적으로 최대 1000개의 다운스트림 파이프라인을 포함할 수 있습니다. 이 제한 및 변경 방법에 대한 자세한 내용은 [파이프라인 계층 구조 크기 제한](../../administration/cicd/limits.md#limit-pipeline-hierarchy-size)을 참조하세요.

## 상위-하위 파이프라인 {#parent-child-pipelines}

상위 파이프라인은 동일한 프로젝트에서 다운스트림 파이프라인을 트리거하는 파이프라인입니다. 다운스트림 파이프라인을 하위 파이프라인이라고 합니다.

하위 파이프라인:

- 상위 파이프라인과 동일한 프로젝트, ref 및 커밋 SHA 아래에서 실행됩니다.
- 파이프라인이 실행되는 ref의 전체 상태에 직접 영향을 주지 않습니다. 예를 들어 메인 브랜치에서 파이프라인이 실패하는 경우 "메인이 손상됨"이라고 말하는 것이 일반적입니다. 하위 파이프라인의 상태는 하위 파이프라인이 [`trigger:strategy`](../yaml/_index.md#triggerstrategy)으로 트리거되는 경우에만 ref의 상태에 영향을 줍니다.
- 파이프라인이 [`interruptible`](../yaml/_index.md#interruptible)로 구성된 경우 동일한 ref에 대해 새 파이프라인이 생성되면 자동으로 취소됩니다.
- 프로젝트의 파이프라인 목록에 표시되지 않습니다. 상위 파이프라인의 세부 정보 페이지에서만 하위 파이프라인을 볼 수 있습니다.

### 중첩 하위 파이프라인 {#nested-child-pipelines}

상위 파이프라인과 하위 파이프라인의 최대 깊이는 2개 수준의 하위 파이프라인입니다.

상위 파이프라인은 많은 하위 파이프라인을 트리거할 수 있으며, 이러한 하위 파이프라인은 자신의 하위 파이프라인을 트리거할 수 있습니다. 다른 수준의 하위 파이프라인을 트리거할 수 없습니다.

<i class="fa-youtube-play" aria-hidden="true"></i> 개요를 보려면 [중첩 동적 파이프라인](https://youtu.be/C5j3ju9je2M)을 참조하세요.

## 다중 프로젝트 파이프라인 {#multi-project-pipelines}

한 프로젝트의 파이프라인은 다른 프로젝트에서 다운스트림 파이프라인을 트리거할 수 있으며, 이를 다중 프로젝트 파이프라인이라고 합니다. 업스트림 파이프라인을 트리거하는 사용자가 다운스트림 파이프라인 프로젝트에서 파이프라인을 시작할 수 있어야 합니다. 그렇지 않으면 [다운스트림 파이프라인이 시작되지 못합니다](downstream_pipelines_troubleshooting.md#trigger-job-fails-and-does-not-create-multi-project-pipeline).

다중 프로젝트 파이프라인:

- 다른 프로젝트의 파이프라인에서 트리거되지만 업스트림 파이프라인(트리거)은 다운스트림 파이프라인(트리거됨)에 대해 많은 제어 권한이 없습니다. 그러나 다운스트림 파이프라인의 ref를 선택하고 CI/CD 변수를 전달할 수 있습니다.
- 실행되는 프로젝트의 ref의 전체 상태에 영향을 미치지만 업스트림 파이프라인의 ref 상태에는 영향을 주지 않습니다. 단, [`trigger:strategy`](../yaml/_index.md#triggerstrategy)으로 트리거된 경우는 제외됩니다.
- 업스트림 파이프라인에서 동일한 ref에 대해 새 파이프라인이 실행되는 경우 [`interruptible`](../yaml/_index.md#interruptible)을 사용할 때 다운스트림 파이프라인 프로젝트에서 자동으로 취소되지 않습니다. 다운스트림 파이프라인 프로젝트에서 동일한 ref에 대해 새 파이프라인이 트리거되는 경우 자동으로 취소될 수 있습니다.
- 다운스트림 파이프라인 프로젝트의 파이프라인 목록에 표시됩니다.
- 독립적이므로 중첩 제한이 없습니다.

공개 프로젝트를 사용하여 개인 프로젝트에서 다운스트림 파이프라인을 트리거하는 경우 기밀성 문제가 없는지 확인하세요. 업스트림 파이프라인의 파이프라인 페이지는 항상 다음을 표시합니다:

- 다운스트림 파이프라인 프로젝트의 이름입니다.
- 파이프라인의 상태입니다.

## `.gitlab-ci.yml` 파일의 작업에서 다운스트림 파이프라인 트리거 {#trigger-a-downstream-pipeline-from-a-job-in-the-gitlab-ciyml-file}

다운스트림 파이프라인을 트리거하는 작업을 생성하려면 `.gitlab-ci.yml` 파일에서 [`trigger`](../yaml/_index.md#trigger) 키워드를 사용합니다. 이 작업을 트리거 작업이라고 합니다.

예를 들어:

{{< tabs >}}

{{< tab title="상위-하위 파이프라인" >}}

```yaml
trigger_job:
  trigger:
    include:
      - local: path/to/child-pipeline.yml
```

{{< /tab >}}

{{< tab title="다중 프로젝트 파이프라인" >}}

```yaml
trigger_job:
  trigger:
    project: project-group/my-downstream-project
```

{{< /tab >}}

{{< /tabs >}}

트리거 작업이 시작된 후 작업의 초기 상태는 GitLab이 다운스트림 파이프라인을 생성하려고 시도하는 동안 `pending`입니다. 트리거 작업은 다운스트림 파이프라인이 성공적으로 생성되면 `passed`를 표시하고, 그렇지 않으면 `failed`을 표시합니다. 또는 [다운스트림 파이프라인의 상태를 표시하도록 트리거 작업을 설정](#mirror-the-status-of-a-downstream-pipeline-in-the-trigger-job)할 수 있습니다.

### `rules`을 사용하여 다운스트림 파이프라인 작업 제어 {#use-rules-to-control-downstream-pipeline-jobs}

CI/CD 변수 또는 [`rules`](../yaml/_index.md#rulesif) 키워드를 사용하여 [다운스트림 파이프라인 작업 동작 제어](../jobs/job_control.md)합니다.

[`trigger`](../yaml/_index.md#trigger) 키워드로 다운스트림 파이프라인을 트리거할 때 모든 작업에 대한 [`$CI_PIPELINE_SOURCE` 사전 정의 변수](../variables/predefined_variables.md)의 값은 다음과 같습니다:

- 다중 프로젝트 파이프라인의 경우 `pipeline`입니다.
- 상위-하위 파이프라인의 경우 `parent_pipeline`입니다.

예를 들어 머지 리퀘스트 파이프라인도 실행하는 프로젝트에서 다중 프로젝트 파이프라인의 작업을 제어하려면:

```yaml
job1:
  rules:
    - if: $CI_PIPELINE_SOURCE == "pipeline"
  script: echo "This job runs in multi-project pipelines only"

job2:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  script: echo "This job runs in merge request pipelines only"

job3:
  rules:
    - if: $CI_PIPELINE_SOURCE == "pipeline"
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  script: echo "This job runs in both multi-project and merge request pipelines"
```

### 다른 프로젝트에서 하위 파이프라인 구성 파일 사용 {#use-a-child-pipeline-configuration-file-in-a-different-project}

트리거 작업에서 [`include:project`](../yaml/_index.md#includeproject)을 사용하여 다른 프로젝트의 구성 파일로 하위 파이프라인을 트리거할 수 있습니다:

```yaml
microservice_a:
  trigger:
    include:
      - project: 'my-group/my-pipeline-library'
        ref: 'main'
        file: '/path/to/child-pipeline.yml'
```

### 여러 하위 파이프라인 구성 파일 병합 {#combine-multiple-child-pipeline-configuration-files}

하위 파이프라인을 정의할 때 최대 3개의 구성 파일을 포함할 수 있습니다. 하위 파이프라인의 구성은 병합된 모든 구성 파일로 구성됩니다:

```yaml
microservice_a:
  trigger:
    include:
      - local: path/to/microservice_a.yml
      - template: Jobs/SAST.gitlab-ci.yml
      - project: 'my-group/my-pipeline-library'
        ref: 'main'
        file: '/path/to/child-pipeline.yml'
```

### 동적 하위 파이프라인 {#dynamic-child-pipelines}

프로젝트에 저장된 정적 파일 대신 작업에서 생성된 YAML 파일에서 하위 파이프라인을 트리거할 수 있습니다. 이 기법은 변경된 콘텐츠를 대상으로 파이프라인을 생성하거나 대상 및 아키텍처의 행렬을 구축하는 데 매우 강력할 수 있습니다.

생성된 YAML 파일을 포함하는 아티팩트는 [인스턴스 제한](../../administration/cicd/limits.md#maximum-size-of-the-ci-artifacts-archive) 내에 있어야 합니다.

<i class="fa-youtube-play" aria-hidden="true"></i> 개요를 보려면 [동적으로 생성된 구성을 사용하여 하위 파이프라인 생성](https://youtu.be/nMdfus2JWHM)을 참조하세요.

동적 하위 파이프라인을 생성하는 예제 프로젝트는 [Jsonnet을 사용한 동적 하위 파이프라인](https://gitlab.com/gitlab-org/project-templates/jsonnet)을 참조하세요. 이 프로젝트는 데이터 템플릿 언어를 사용하여 `.gitlab-ci.yml`를 런타임에 생성하는 방법을 보여줍니다. [Dhall](https://dhall-lang.org/) 또는 [ytt](https://get-ytt.io/)와 같은 다른 템플릿 언어에 유사한 프로세스를 사용할 수 있습니다.

#### 동적 하위 파이프라인 트리거 {#trigger-a-dynamic-child-pipeline}

동적으로 생성된 구성 파일에서 하위 파이프라인을 트리거하려면:

1. 구성 파일을 작업에서 생성하고 [아티팩트](../yaml/_index.md#artifactspaths)로 저장합니다:

   ```yaml
   generate-config:
     stage: build
     script: generate-ci-config > generated-config.yml
     artifacts:
       paths:
         - generated-config.yml
   ```

1. 구성 파일을 생성한 작업 후에 실행하도록 트리거 작업을 구성합니다. `include: artifact`을 생성된 아티팩트로 설정하고 `include: job`를 아티팩트를 생성한 작업으로 설정합니다:

   ```yaml
   child-pipeline:
     stage: test
     trigger:
       include:
         - artifact: generated-config.yml
           job: generate-config
   ```

이 예제에서 GitLab은 `generated-config.yml`을 검색하고 해당 파일의 CI/CD 구성으로 하위 파이프라인을 트리거합니다.

아티팩트 경로는 러너가 아닌 GitLab에서 구문 분석되므로 경로는 GitLab을 실행하는 OS의 구문과 일치해야 합니다. GitLab이 Linux에서 실행 중이지만 테스트를 위해 Windows 러너를 사용하는 경우 트리거 작업의 경로 구분 기호는 `/`입니다. Windows 러너를 사용하는 작업의 다른 CI/CD 구성(예: 스크립트)은 ` \ `를 사용합니다.

동적 하위 파이프라인의 구성에서 `include` 섹션의 CI/CD 변수를 사용할 수 없습니다.

### 머지 리퀘스트 파이프라인과 함께 하위 파이프라인 실행 {#run-child-pipelines-with-merge-request-pipelines}

파이프라인(하위 파이프라인 포함)은 [`rules`](../yaml/_index.md#rules) 또는 [`workflow:rules`](../yaml/_index.md#workflowrules)을 사용하지 않을 때 기본적으로 브랜치 파이프라인으로 실행됩니다. [머지 리퀘스트 (상위) 파이프라인](merge_request_pipelines.md)에서 트리거될 때 실행하도록 하위 파이프라인을 구성하려면 `rules` 또는 `workflow:rules`을 사용합니다. 예를 들어 `rules`을 사용합니다:

1. 상위 파이프라인의 트리거 작업을 머지 리퀘스트에서 실행하도록 설정합니다:

   ```yaml
   trigger-child-pipeline-job:
     trigger:
       include: path/to/child-pipeline-configuration.yml
     rules:
       - if: $CI_PIPELINE_SOURCE == "merge_request_event"
   ```

1. `rules`을 사용하여 상위 파이프라인에 의해 트리거될 때 실행하도록 하위 파이프라인 작업을 구성합니다:

   ```yaml
   job1:
     script: echo "This child pipeline job runs any time the parent pipeline triggers it."
     rules:
       - if: $CI_PIPELINE_SOURCE == "parent_pipeline"

   job2:
     script: echo "This child pipeline job runs only when the parent pipeline is a merge request pipeline"
     rules:
       - if: $CI_MERGE_REQUEST_ID
   ```

하위 파이프라인에서 `$CI_PIPELINE_SOURCE`은 항상 `parent_pipeline`의 값을 가지므로:

- `if: $CI_PIPELINE_SOURCE == "parent_pipeline"`을 사용하여 하위 파이프라인 작업이 항상 실행되도록 보장할 수 있습니다.
- 머지 리퀘스트 파이프라인에 대해 하위 파이프라인 작업이 실행되도록 구성하는 데 `if: $CI_PIPELINE_SOURCE == "merge_request_event"`을 사용할 수 없습니다. 대신 `if: $CI_MERGE_REQUEST_ID`을 사용하여 상위 파이프라인이 머지 리퀘스트 파이프라인일 때만 실행하도록 하위 파이프라인 작업을 설정합니다. 상위 파이프라인의 [`CI_MERGE_REQUEST_*` 사전 정의 변수](../variables/predefined_variables.md#predefined-variables-for-merge-request-pipelines)가 하위 파이프라인 작업으로 전달됩니다.

### 다중 프로젝트 파이프라인에 대한 브랜치 지정 {#specify-a-branch-for-multi-project-pipelines}

다중 프로젝트 파이프라인을 트리거할 때 사용할 브랜치를 지정할 수 있습니다. GitLab은 브랜치 헤드의 커밋을 사용하여 다운스트림 파이프라인을 생성합니다. 예를 들어:

```yaml
staging:
  stage: deploy
  trigger:
    project: my/deployment
    branch: stable-11-2
```

사용:

- 다운스트림 파이프라인 프로젝트의 전체 경로를 지정하는 `project` 키워드입니다. [변수 확장](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)을 사용할 수 있습니다.
- `project`으로 지정된 프로젝트에서 브랜치 또는 [태그](../../user/project/repository/tags/_index.md)의 이름을 지정하는 `branch` 키워드입니다. 변수 확장을 사용할 수 있습니다.

## API를 사용하여 다중 프로젝트 파이프라인 트리거 {#trigger-a-multi-project-pipeline-by-using-the-api}

[CI/CD 작업 토큰 (`CI_JOB_TOKEN`)](../jobs/ci_job_token.md)을 [파이프라인 트리거 토큰 API 엔드포인트](../../api/pipeline_triggers.md#trigger-a-pipeline-with-a-token)와 함께 사용하여 CI/CD 작업 내에서 다중 프로젝트 파이프라인을 트리거할 수 있습니다. GitLab은 작업 토큰으로 트리거된 파이프라인을 API 호출을 수행한 작업을 포함하는 파이프라인의 다운스트림 파이프라인으로 설정합니다.

예를 들어:

```yaml
trigger_pipeline:
  stage: deploy
  script:
    - |
      curl --request POST \
        --form "token=$CI_JOB_TOKEN" \
        --form ref=main \
        --url "https://gitlab.example.com/api/v4/projects/9/trigger/pipeline"
  rules:
    - if: $CI_COMMIT_TAG
  environment: production
```

## 다운스트림 파이프라인 보기 {#view-a-downstream-pipeline}

[파이프라인 세부 정보 페이지](_index.md#pipeline-details)에서 다운스트림 파이프라인은 그래프 오른쪽에 카드 목록으로 표시됩니다. 이 보기에서 다음을 수행할 수 있습니다:

- 트리거 작업을 선택하여 트리거된 다운스트림 파이프라인의 작업을 봅니다.
- **작업 펼침** {{< icon name="chevron-lg-right" >}}을 파이프라인 카드에서 선택하여 다운스트림 파이프라인의 작업으로 보기를 확장합니다. 한 번에 하나의 다운스트림 파이프라인을 볼 수 있습니다.
- 파이프라인 카드 위에 마우스를 놓으면 다운스트림 파이프라인을 트리거한 작업이 강조 표시됩니다.

### 다운스트림 파이프라인의 실패 및 취소된 작업 다시 시도 {#retry-failed-and-canceled-jobs-in-a-downstream-pipeline}

실패 및 취소된 작업을 다시 시도하려면 **재시도** ({{< icon name="retry" >}})을 선택합니다:

- 다운스트림 파이프라인의 세부 정보 페이지에서.
- 파이프라인 그래프 보기의 파이프라인 카드에서.

### 다운스트림 파이프라인 다시 생성 {#recreate-a-downstream-pipeline}

해당 트리거 작업을 다시 시도하여 다운스트림 파이프라인을 다시 생성할 수 있습니다. 새로 생성된 다운스트림 파이프라인은 파이프라인 그래프의 현재 다운스트림 파이프라인을 대체합니다.

다운스트림 파이프라인을 다시 생성하려면:

- 파이프라인 그래프 보기의 트리거 작업 카드에서 **다시 실행** ({{< icon name="retry" >}})을 선택합니다.

### 다운스트림 파이프라인 취소 {#cancel-a-downstream-pipeline}

여전히 실행 중인 다운스트림 파이프라인을 취소하려면 **취소** ({{< icon name="cancel" >}})을 선택합니다:

- 다운스트림 파이프라인의 세부 정보 페이지에서.
- 파이프라인 그래프 보기의 파이프라인 카드에서.

### 다운스트림 파이프라인에서 상위 파이프라인 자동 취소 {#auto-cancel-the-parent-pipeline-from-a-downstream-pipeline}

하위 파이프라인을 구성하여 작업 중 하나가 실패하는 즉시 [자동 취소](../yaml/_index.md#workflowauto_cancelon_job_failure)하도록 할 수 있습니다.

상위 파이프라인은 다음의 경우에만 하위 파이프라인의 작업이 실패할 때 자동으로 취소됩니다:

- 상위 파이프라인도 작업 실패 시 자동 취소하도록 설정되어 있습니다.
- 트리거 작업이 [`strategy: mirror`](../yaml/_index.md#triggerstrategy)으로 구성되었습니다.

예를 들어:

- `.gitlab-ci.yml`의 내용:

  ```yaml
  workflow:
    auto_cancel:
      on_job_failure: all

  trigger_job:
    trigger:
      include: child-pipeline.yml
      strategy: mirror

  job3:
    script:
      - sleep 120
  ```

- `child-pipeline.yml`의 내용

  ```yaml
  # Contents of child-pipeline.yml
  workflow:
    auto_cancel:
      on_job_failure: all

  job1:
    script: sleep 60

  job2:
    script:
      - sleep 30
      - exit 1
  ```

이 예에서:

1. 상위 파이프라인이 하위 파이프라인 및 `job3`을 동시에 트리거합니다
1. 하위 파이프라인의 `job2`이 실패하고 하위 파이프라인이 취소되며 `job1`도 중지됩니다
1. 하위 파이프라인이 취소되었으므로 상위 파이프라인이 자동 취소됩니다

### 트리거 작업에서 다운스트림 파이프라인의 상태 미러링 {#mirror-the-status-of-a-downstream-pipeline-in-the-trigger-job}

[`trigger: strategy`](../yaml/_index.md#triggerstrategy)을 사용하여 트리거 작업에서 다운스트림 파이프라인의 상태를 미러링할 수 있습니다:

`strategy: mirror`을 사용하면 트리거 작업은 항상 다운스트림 파이프라인과 동일한 상태를 갖습니다.

{{< tabs >}}

{{< tab title="상위-하위 파이프라인" >}}

```yaml
trigger_job:
  trigger:
    include:
      - local: path/to/child-pipeline.yml
    strategy: mirror
```

{{< /tab >}}

{{< tab title="다중 프로젝트 파이프라인" >}}

```yaml
trigger_job:
  trigger:
    project: my/project
    strategy: mirror
```

{{< /tab >}}

{{< /tabs >}}

`strategy: depend`은 권장되지 않습니다. 트리거 작업 상태가 항상 다운스트림 파이프라인의 상태와 일치하지 않기 때문입니다. [`trigger:strategy` 참조의 추가 세부 정보](../yaml/_index.md#triggerstrategy)를 참조하세요.

### 파이프라인 그래프에서 다중 프로젝트 파이프라인 보기 {#view-multi-project-pipelines-in-pipeline-graphs}

{{< history >}}

- GitLab Premium에서 GitLab Free로 [이동됨](https://gitlab.com/gitlab-org/gitlab/-/issues/422282) (16.8).

{{< /history >}}

다중 프로젝트 파이프라인을 트리거한 후 다운스트림 파이프라인이 [파이프라인 그래프](_index.md#view-pipelines)의 오른쪽에 표시됩니다.

[파이프라인 미니 그래프](_index.md#pipeline-mini-graphs)에서 다운스트림 파이프라인이 미니 그래프의 오른쪽에 표시됩니다.

## 머지 리퀘스트의 하위 파이프라인 보고서 보기 {#view-child-pipeline-reports-in-merge-requests}

{{< history >}}

- GitLab 18.6에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/18311)되었습니다.
- 하위 파이프라인의 보안 보고서가 GitLab 18.9에 [도입](https://gitlab.com/groups/gitlab-org/-/work_items/18377)되었습니다.

{{< /history >}}

머지 리퀘스트 위젯의 하위 파이프라인에서 보고서를 보고 다운로드할 수 있습니다. 이는 여러 파이프라인을 수동으로 탐색하지 않고도 파이프라인 계층 구조 전체의 테스트 결과 및 품질 검사의 통합 보기를 제공하여 오류와 취약점을 식별합니다.

하위 파이프라인에서 지원되는 보고서 유형은 다음과 같습니다:

- 단위 테스트 보고서 (JUnit)
- 코드 품질 보고서
- Terraform 보고서
- 메트릭 보고서
- 보안 보고서 (SAST, 시크릿 검색, 종속성 검사, 컨테이너 검사, DAST, API 퍼징)

보안 보고서는 동일한 프로젝트의 하위 파이프라인, 동적으로 생성된 하위 파이프라인 및 파이프라인 실행 정책으로 생성된 파이프라인과 함께 작동합니다. [스캔 실행 정책](../../user/application_security/policies/scan_execution_policies.md)의 보고서는 지원되지 않습니다.

테스트 결과 및 [보안 발견](../../user/application_security/detect/security_scanning_results.md)이 하위 파이프라인에서 상위 파이프라인의 **테스트** 및 **보안** 탭에도 나타납니다.

하위 파이프라인 보안 발견이 [머지 리퀘스트 승인 정책](../../user/application_security/policies/merge_request_approval_policies.md)을 트리거할 수 있습니다. 하위 파이프라인이 취약점을 감지하면 병합하기 전에 추가 승인이 필요할 수 있습니다.

하위 파이프라인의 보고서가 머지 리퀘스트 위젯에 표시되도록 하려면 아티팩트 보고서를 생성하는 하위 파이프라인에 [`strategy: depend`](../yaml/_index.md#triggerstrategy) 또는 [`strategy: mirror`](../yaml/_index.md#triggerstrategy)을 사용합니다. 예를 들어:

```yaml
test-backend:
  trigger:
    include: backend-tests.yml
    strategy: depend

test-frontend:
  trigger:
    include: frontend-tests.yml
    strategy: depend
```

이러한 전략 없이는 상위 파이프라인이 완료된 후 하위 파이프라인이 완료되므로 보고서가 머지 리퀘스트에 나타나지 않습니다.

## 업스트림 파이프라인에서 아티팩트 가져오기 {#fetch-artifacts-from-an-upstream-pipeline}

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< tabs >}}

{{< tab title="상위-하위 파이프라인" >}}

[`needs:pipeline:job`](../yaml/_index.md#needspipelinejob)을 사용하여 업스트림 파이프라인에서 아티팩트를 가져옵니다:

1. 업스트림 파이프라인에서 [`artifacts`](../yaml/_index.md#artifacts) 키워드로 작업에 아티팩트를 저장한 후 트리거 작업으로 다운스트림 파이프라인을 트리거합니다:

   ```yaml
   build_artifacts:
     stage: build
     script:
       - echo "This is a test artifact!" >> artifact.txt
     artifacts:
       paths:
         - artifact.txt

   deploy:
     stage: deploy
     trigger:
       include:
         - local: path/to/child-pipeline.yml
     variables:
       PARENT_PIPELINE_ID: $CI_PIPELINE_ID
   ```

1. 다운스트림 파이프라인의 작업에서 `needs:pipeline:job`을 사용하여 성공한 작업의 아티팩트를 가져옵니다.

   ```yaml
   test:
     stage: test
     script:
       - cat artifact.txt
     needs:
       - pipeline: $PARENT_PIPELINE_ID
         job: build_artifacts
   ```

   `job`을 아티팩트를 생성한 업스트림 파이프라인의 작업으로 설정합니다.

{{< /tab >}}

{{< tab title="다중 프로젝트 파이프라인" >}}

[`needs:project`](../yaml/_index.md#needsproject)을 사용하여 업스트림 파이프라인에서 아티팩트를 가져옵니다:

1. 업스트림 파이프라인 프로젝트의 작업 토큰 범위 허용 목록에 다운스트림 파이프라인 프로젝트를 [추가](../jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist)합니다.
1. 업스트림 파이프라인에서 [`artifacts`](../yaml/_index.md#artifacts) 키워드로 작업에 아티팩트를 저장한 후 트리거 작업으로 다운스트림 파이프라인을 트리거합니다:

   ```yaml
   build_artifacts:
     stage: build
     script:
       - echo "This is a test artifact!" >> artifact.txt
     artifacts:
       paths:
         - artifact.txt

   deploy:
     stage: deploy
     trigger: my/downstream_project   # Path to the project to trigger a pipeline in
   ```

1. 다운스트림 파이프라인의 작업에서 `needs:project`을 사용하여 성공한 작업의 아티팩트를 가져옵니다.

   ```yaml
   test:
     stage: test
     script:
       - cat artifact.txt
     needs:
       - project: my/upstream_project
         job: build_artifacts
         ref: main
         artifacts: true
   ```

   설정:

   - `job`을 아티팩트를 생성한 업스트림 파이프라인의 작업으로 설정합니다.
   - `ref`을 브랜치로 설정합니다.
   - `artifacts`을 `true`로 설정합니다.

{{< /tab >}}

{{< /tabs >}}

> [!warning]
> 업스트림 파이프라인 작업이 완료된 후 다운스트림 파이프라인 작업이 시작되는지 확인하세요. 그렇지 않으면 아티팩트를 가져올 수 없습니다. [`needs`](../yaml/_index.md#needs)을 사용하여 다운스트림 파이프라인 작업이 업스트림 파이프라인 작업을 기다리도록 합니다.
>
> 자세한 내용은 [이슈 356016](https://gitlab.com/gitlab-org/gitlab/-/issues/356016)을 참조하세요.

### 업스트림 파이프라인 머지 리퀘스트 파이프라인에서 아티팩트 가져오기 {#fetch-artifacts-from-an-upstream-merge-request-pipeline}

`needs:project`을 사용하여 [다운스트림 파이프라인에 아티팩트를 전달](#fetch-artifacts-from-an-upstream-pipeline)할 때 `ref` 값은 보통 `main` 또는 `development`와 같은 브랜치 이름입니다.

[머지 리퀘스트 파이프라인](merge_request_pipelines.md)의 경우 `ref` 값은 `refs/merge-requests/<id>/head` 형식이며, 여기서 `id`는 머지 리퀘스트 ID입니다. [`CI_MERGE_REQUEST_REF_PATH`](../variables/predefined_variables.md#predefined-variables-for-merge-request-pipelines) CI/CD 변수를 사용하여 이 참조를 검색할 수 있습니다. 머지 리퀘스트 파이프라인에서 브랜치 이름을 `ref`로 사용하지 마세요. 다운스트림 파이프라인이 최신 브랜치 파이프라인에서 아티팩트를 가져오려고 시도하기 때문입니다.

업스트림 `merge request` 파이프라인 대신 `branch` 파이프라인에서 아티팩트를 가져오려면 `CI_MERGE_REQUEST_REF_PATH`을 [CI/CD 변수 상속](#pass-yaml-defined-cicd-variables)을 사용하여 다운스트림 파이프라인으로 전달합니다:

1. 업스트림 파이프라인 프로젝트의 작업 토큰 범위 허용 목록에 다운스트림 파이프라인 프로젝트를 [추가](../jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist)합니다.
1. 업스트림 파이프라인의 작업에서 [`artifacts`](../yaml/_index.md#artifacts) 키워드를 사용하여 아티팩트를 저장합니다.
1. 다운스트림 파이프라인을 트리거하는 작업에서 `$CI_MERGE_REQUEST_REF_PATH` 변수를 전달합니다:

   ```yaml
   build_artifacts:
     rules:
       - if: $CI_PIPELINE_SOURCE == 'merge_request_event'
     stage: build
     script:
       - echo "This is a test artifact!" >> artifact.txt
     artifacts:
       paths:
         - artifact.txt

   upstream_job:
     rules:
       - if: $CI_PIPELINE_SOURCE == 'merge_request_event'
     variables:
       UPSTREAM_REF: $CI_MERGE_REQUEST_REF_PATH
     trigger:
       project: my/downstream_project
       branch: my-branch
   ```

1. 다운스트림 파이프라인의 작업에서 `needs:project`을 사용하고 전달된 변수를 `ref`로 사용하여 업스트림 파이프라인에서 아티팩트를 가져옵니다:

   ```yaml
   test:
     stage: test
     script:
       - cat artifact.txt
     needs:
       - project: my/upstream_project
         job: build_artifacts
         ref: $UPSTREAM_REF
         artifacts: true
   ```

이 방법을 사용하여 업스트림 파이프라인 머지 리퀘스트 파이프라인에서 아티팩트를 가져올 수 있지만 [병합된 결과 파이프라인](merged_results_pipelines.md)에서는 가져올 수 없습니다.

## 다운스트림 파이프라인에 입력값 전달 {#pass-inputs-to-a-downstream-pipeline}

[`inputs`](../inputs/_index.md) 키워드를 사용하여 다운스트림 파이프라인에 입력값을 전달할 수 있습니다. 입력값은 변수에 비해 타입 검사, 옵션을 통한 유효성 검사, 설명 및 기본값을 포함한 이점을 제공합니다.

먼저 `spec:inputs`을 사용하여 대상 구성 파일에서 입력 매개변수를 정의합니다:

```yaml
# Target pipeline configuration
spec:
  inputs:
    environment:
      description: "Deployment environment"
      options: [staging, production]
    version:
      type: string
      description: "Application version"
```

그런 다음 파이프라인을 트리거할 때 값을 제공합니다:

{{< tabs >}}

{{< tab title="상위-하위 파이프라인" >}}

```yaml
staging:
  trigger:
    include:
      - local: path/to/child-pipeline.yml
        inputs:
          environment: staging
          version: "1.0.0"
```

{{< /tab >}}

{{< tab title="다중 프로젝트 파이프라인" >}}

```yaml
staging:
  trigger:
    project: my-group/my-deployment-project
    inputs:
      environment: staging
      version: "1.0.0"
```

{{< /tab >}}

{{< /tabs >}}

## 다운스트림 파이프라인에 CI/CD 변수 전달 {#pass-cicd-variables-to-a-downstream-pipeline}

변수가 생성되거나 정의된 위치에 따라 몇 가지 다른 방법을 사용하여 [CI/CD 변수](../variables/_index.md)을 다운스트림 파이프라인에 전달할 수 있습니다.

### YAML 정의 CI/CD 변수 전달 {#pass-yaml-defined-cicd-variables}

> [!note]
> 입력값은 향상된 보안 및 유연성을 제공하므로 CI/CD 변수 대신 파이프라인 구성에 권장됩니다.

`variables` 키워드를 사용하여 CI/CD 변수를 다운스트림 파이프라인에 전달할 수 있습니다. 이러한 변수는 [CI/CD 변수 우선순위](../variables/_index.md#cicd-variable-precedence)를 위한 파이프라인 변수입니다.

예를 들어:

{{< tabs >}}

{{< tab title="상위-하위 파이프라인" >}}

```yaml
variables:
  VERSION: "1.0.0"

staging:
  variables:
    ENVIRONMENT: staging
  stage: deploy
  trigger:
    include:
      - local: path/to/child-pipeline.yml
```

{{< /tab >}}

{{< tab title="다중 프로젝트 파이프라인" >}}

```yaml
variables:
  VERSION: "1.0.0"

staging:
  variables:
    ENVIRONMENT: staging
  stage: deploy
  trigger: my-group/my-deployment-project
```

{{< /tab >}}

{{< /tabs >}}

`ENVIRONMENT` 변수는 다운스트림 파이프라인에 정의된 모든 작업에서 사용 가능합니다.

`VERSION` 기본값 변수는 파이프라인의 모든 작업(트리거 작업 포함)이 [기본 `variables`](../yaml/_index.md#default-variables)을 상속하기 때문에 다운스트림 파이프라인에서도 사용 가능합니다.

#### 기본값 변수가 전달되지 않도록 방지 {#prevent-default-variables-from-being-passed}

[`inherit:variables`](../yaml/_index.md#inheritvariables)를 사용하여 기본 CI/CD 변수가 다운스트림 파이프라인에 도달하지 않도록 중지할 수 있습니다. 상속할 특정 변수를 나열하거나 모든 기본값 변수를 차단할 수 있습니다.

예를 들어:

{{< tabs >}}

{{< tab title="상위-하위 파이프라인" >}}

```yaml
variables:
  DEFAULT_VAR: value

trigger-job:
  inherit:
    variables: false
  variables:
    JOB_VAR: value
  trigger:
    include:
      - local: path/to/child-pipeline.yml
```

{{< /tab >}}

{{< tab title="다중 프로젝트 파이프라인" >}}

```yaml
variables:
  DEFAULT_VAR: value

trigger-job:
  inherit:
    variables: false
  variables:
    JOB_VAR: value
  trigger: my-group/my-project
```

{{< /tab >}}

{{< /tabs >}}

`DEFAULT_VAR` 변수는 트리거된 파이프라인에서 사용 가능하지 않지만 `JOB_VAR`는 사용 가능합니다.

### 사전 정의 변수 전달 {#pass-a-predefined-variable}

업스트림 파이프라인에 대한 정보를 [사전 정의 CI/CD 변수](../variables/predefined_variables.md)를 사용하여 전달하려면 보간을 사용합니다. 사전 정의 변수를 트리거 작업의 새 작업 변수로 저장하여 다운스트림 파이프라인으로 전달합니다. 예를 들어:

{{< tabs >}}

{{< tab title="상위-하위 파이프라인" >}}

```yaml
trigger-job:
  variables:
    PARENT_BRANCH: $CI_COMMIT_REF_NAME
  trigger:
    include:
      - local: path/to/child-pipeline.yml
```

{{< /tab >}}

{{< tab title="다중 프로젝트 파이프라인" >}}

```yaml
trigger-job:
  variables:
    UPSTREAM_BRANCH: $CI_COMMIT_REF_NAME
  trigger: my-group/my-project
```

{{< /tab >}}

{{< /tabs >}}

`UPSTREAM_BRANCH` 변수는 업스트림 파이프라인의 `$CI_COMMIT_REF_NAME` 사전 정의 CI/CD 변수의 값을 포함하며 다운스트림 파이프라인에서 사용 가능합니다.

이 방법을 사용하여 다중 프로젝트 파이프라인에 [마스킹된 변수](../variables/_index.md#mask-a-cicd-variable)를 전달하지 마세요. CI/CD 변수 마스킹 구성이 다운스트림 파이프라인으로 전달되지 않으며 변수가 다운스트림 파이프라인 프로젝트의 작업 로그에서 마스킹 해제될 수 있습니다.

이 방법을 사용하여 [작업 전용 변수](../variables/predefined_variables.md#variable-availability)를 다운스트림 파이프라인으로 전달할 수 없습니다. 트리거 작업에서 사용할 수 없기 때문입니다.

업스트림 파이프라인은 다운스트림 파이프라인보다 우선합니다. 업스트림 파이프라인 및 다운스트림 파이프라인 프로젝트 모두에 정의된 이름이 같은 두 변수가 있는 경우 업스트림 파이프라인 프로젝트에 정의된 변수가 우선합니다.

### 작업에서 생성된 dotenv 변수 전달 {#pass-dotenv-variables-created-in-a-job}

dotenv CI/CD 변수 상속을 사용하여 CI/CD 변수를 다운스트림 파이프라인에 전달할 수 있습니다.

자세한 내용은 [CI/CD 변수를 다운스트림 파이프라인에 전달](../variables/dotenv_variables.md#pass-variables-to-downstream-pipelines)을 참조하세요.

### 다운스트림 파이프라인으로 전달할 변수 유형 제어 {#control-what-type-of-variables-to-forward-to-downstream-pipelines}

[`trigger:forward` 키워드](../yaml/_index.md#triggerforward)를 사용하여 다운스트림 파이프라인으로 전달할 변수 유형을 지정합니다. 전달된 변수는 트리거 변수로 간주되며 [최우선 순위](../variables/_index.md#cicd-variable-precedence)를 가집니다.

## 배포를 위한 다운스트림 파이프라인 {#downstream-pipelines-for-deployments}

{{< history >}}

- GitLab 16.4에 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/369061)되었습니다.

{{< /history >}}

[`environment`](../yaml/_index.md#environment) 키워드를 [`trigger`](../yaml/_index.md#trigger)과 함께 사용할 수 있습니다. 배포 및 애플리케이션 프로젝트를 별도로 관리하는 경우 트리거 작업에서 `environment`을 사용할 수 있습니다.

```yaml
deploy:
  trigger:
    project: project-group/my-downstream-project
  environment: production
```

다운스트림 파이프라인은 인프라를 프로비저닝하고, 지정된 환경에 배포하며, 업스트림 파이프라인에 배포 상태를 반환할 수 있습니다.

업스트림 파이프라인 프로젝트에서 [환경 및 배포 보기](../environments/_index.md#view-environments-and-deployments)를 수행할 수 있습니다.

### 고급 예제 {#advanced-example}

이 예제 구성의 동작은 다음과 같습니다:

- 업스트림 파이프라인 프로젝트는 브랜치 이름을 기반으로 환경 이름을 동적으로 구성합니다.
- 업스트림 파이프라인 프로젝트는 `UPSTREAM_*` 변수를 사용하여 다운스트림 파이프라인 프로젝트에 배포 컨텍스트를 전달합니다.

업스트림 파이프라인 프로젝트의 `.gitlab-ci.yml`:

```yaml
stages:
  - deploy
  - cleanup

.downstream-deployment-pipeline:
  variables:
    UPSTREAM_PROJECT_ID: $CI_PROJECT_ID
    UPSTREAM_ENVIRONMENT_NAME: $CI_ENVIRONMENT_NAME
    UPSTREAM_ENVIRONMENT_ACTION: $CI_ENVIRONMENT_ACTION
  trigger:
    project: project-group/deployment-project
    branch: main
    strategy: mirror

deploy-review:
  stage: deploy
  extends: .downstream-deployment-pipeline
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    on_stop: stop-review

stop-review:
  stage: cleanup
  extends: .downstream-deployment-pipeline
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    action: stop
  when: manual
```

다운스트림 파이프라인 프로젝트의 `.gitlab-ci.yml`:

```yaml
deploy:
  script: echo "Deploy to ${UPSTREAM_ENVIRONMENT_NAME} for ${UPSTREAM_PROJECT_ID}"
  rules:
    - if: $CI_PIPELINE_SOURCE == "pipeline" && $UPSTREAM_ENVIRONMENT_ACTION == "start"

stop:
  script: echo "Stop ${UPSTREAM_ENVIRONMENT_NAME} for ${UPSTREAM_PROJECT_ID}"
  rules:
    - if: $CI_PIPELINE_SOURCE == "pipeline" && $UPSTREAM_ENVIRONMENT_ACTION == "stop"
```
