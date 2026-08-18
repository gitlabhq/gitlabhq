---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "GitLab CI/CD ‘workflow’ 키워드를 사용하여 파이프라인 제어, 규칙 관리 및 중복 파이프라인 방지합니다."
title: 'workflow 키워드'
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[`workflow`](_index.md#workflow) 키워드를 `.gitlab-ci.yml` 파일에서 사용하여 파이프라인을 만드는 시기를 제어합니다.

`workflow` 키워드는 작업보다 먼저 평가됩니다. 예를 들어 작업이 태그에 대해 실행되도록 구성되어 있지만 워크플로우가 태그 파이프라인을 방지하면 작업은 실행되지 않습니다.

## `if` 절에 대한 일반적인 `workflow:rules` {#common-if-clauses-for-workflowrules}

`if` 절의 일반적인 예시 `workflow: rules`:

| 예시 규칙                                        | 세부 정보 |
|------------------------------------------------------|---------|
| `if: '$CI_PIPELINE_SOURCE == "merge_request_event"'` | 머지 리퀘스트 파이프라인이 실행되는 시기를 제어합니다. |
| `if: '$CI_PIPELINE_SOURCE == "push"'`                | 브랜치 파이프라인과 태그 파이프라인이 실행되는 시기를 제어합니다. |
| `if: $CI_COMMIT_TAG`                                 | 태그 파이프라인이 실행되는 시기를 제어합니다. |
| `if: $CI_COMMIT_BRANCH`                              | 브랜치 파이프라인이 실행되는 시기를 제어합니다. |

[`if` 절에 대한 일반적인 `rules`](../jobs/job_rules.md#common-if-clauses-with-predefined-variables)을 더 많은 예시를 보려면 참고하세요.

## `workflow: rules` 예시 {#workflow-rules-examples}

다음 예시에서:

- 파이프라인은 모든 `push` 이벤트(브랜치 변경 및 새 태그)에 대해 실행됩니다.
- `-draft`로 끝나는 커밋 메시지가 포함된 푸시 이벤트의 파이프라인은 `when: never`로 설정되어 있으므로 실행되지 않습니다.
- 스케줄 또는 머지 리퀘스트의 파이프라인도 실행되지 않습니다. 이는 어떤 규칙도 이들에 대해 참으로 평가되지 않기 때문입니다.

```yaml
workflow:
  rules:
    - if: $CI_COMMIT_MESSAGE =~ /-draft$/
      when: never
    - if: $CI_PIPELINE_SOURCE == "push"
```

이 예시는 엄격한 규칙을 가지고 있으며 다른 어떤 경우에도 파이프라인이 실행되지 않습니다.

또는 모든 규칙을 `when: never`로 설정하고 최종 `when: always` 규칙을 추가할 수 있습니다. `when: never` 규칙과 일치하는 파이프라인은 실행되지 않습니다. 다른 모든 파이프라인 유형이 실행됩니다. 예를 들어:

```yaml
workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
      when: never
    - if: $CI_PIPELINE_SOURCE == "push"
      when: never
    - when: always
```

이 예시는 스케줄 또는 `push`(브랜치 및 태그) 파이프라인을 방지합니다. 최종 `when: always` 규칙은 **including** 다른 모든 파이프라인 유형을 실행합니다. 머지 리퀘스트 파이프라인.

### 브랜치 파이프라인과 머지 리퀘스트 파이프라인 간의 전환 {#switch-between-branch-pipelines-and-merge-request-pipelines}

파이프라인을 브랜치 파이프라인에서 [머지 리퀘스트 파이프라인](../pipelines/merge_request_pipelines.md)으로 전환하려면 머지 리퀘스트를 만든 후에 `workflow: rules` 섹션을 `.gitlab-ci.yml` 파일에 추가하세요.

두 파이프라인 유형을 동시에 사용하면 [중복 파이프라인](../jobs/job_rules.md#avoid-duplicate-pipelines)이 동시에 실행될 수 있습니다. 중복 파이프라인을 방지하려면 [`CI_OPEN_MERGE_REQUESTS` 변수](../variables/predefined_variables.md)를 사용하세요.

다음 예시는 브랜치 및 머지 리퀘스트 파이프라인만 실행하지만 다른 경우에는 파이프라인을 실행하지 않는 프로젝트를 위한 것입니다. 실행 대상:

- 머지 리퀘스트가 브랜치에 대해 열려 있지 않을 때 브랜치 파이프라인입니다.
- 머지 리퀘스트가 브랜치에 대해 열려 있을 때 머지 리퀘스트 파이프라인입니다.

```yaml
workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH && $CI_OPEN_MERGE_REQUESTS
      when: never
    - if: $CI_COMMIT_BRANCH
```

GitLab이 트리거를 시도하는 경우:

- 머지 리퀘스트 파이프라인, 파이프라인을 시작합니다. 예를 들어, 머지 리퀘스트 파이프라인은 연결된 열려 있는 머지 리퀘스트가 있는 브랜치로의 푸시로 트리거될 수 있습니다.
- 브랜치 파이프라인, 하지만 머지 리퀘스트가 해당 브랜치에 대해 열려 있으면 브랜치 파이프라인을 실행하지 마세요. 예를 들어, 브랜치 파이프라인은 브랜치로의 변경, API 호출, 예약된 파이프라인 등으로 트리거될 수 있습니다.
- 브랜치 파이프라인, 하지만 브랜치에 대해 열려 있는 머지 리퀘스트가 없으면 브랜치 파이프라인을 실행합니다.

또한 기존 `workflow` 섹션에 규칙을 추가하여 머지 리퀘스트를 만들 때 브랜치 파이프라인에서 머지 리퀘스트 파이프라인으로 전환할 수 있습니다.

이 규칙을 `workflow` 섹션의 맨 위에 추가하고 그 뒤에 이미 있던 다른 규칙을 추가하세요:

```yaml
workflow:
  rules:
    - if: $CI_COMMIT_BRANCH && $CI_OPEN_MERGE_REQUESTS && $CI_PIPELINE_SOURCE == "push"
      when: never
    - # Previously defined workflow rules here
```

[파이프라인 트리거](../triggers/_index.md)는 브랜치에서 실행되므로 `$CI_COMMIT_BRANCH`이 설정되어 있으며 유사한 규칙에 의해 차단될 수 있습니다. 트리거된 파이프라인은 `trigger` 또는 `pipeline` 파이프라인 소스를 가지므로 `&& $CI_PIPELINE_SOURCE == "push"`은 규칙이 트리거된 파이프라인을 차단하지 않도록 합니다.

### 머지 리퀘스트 파이프라인을 사용한 Git Flow {#git-flow-with-merge-request-pipelines}

`workflow: rules`을 머지 리퀘스트 파이프라인과 함께 사용할 수 있습니다. 이러한 규칙을 사용하면 [머지 리퀘스트 파이프라인 기능](../pipelines/merge_request_pipelines.md)을 기능 브랜치와 함께 사용할 수 있으면서 소프트웨어의 여러 버전을 지원하기 위해 장기적인 브랜치를 유지할 수 있습니다.

예를 들어 머지 리퀘스트, 태그 및 보호된 브랜치에 대해서만 파이프라인을 실행하려면:

```yaml
workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_TAG
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    - if: $CI_COMMIT_REF_PROTECTED == "true"
```

이 예시는 기본 브랜치 또는 다른 장기적인 브랜치가 [보호됨](../../user/project/repository/branches/protected.md)이라고 가정합니다.

### 드래프트 머지 리퀘스트에 대한 파이프라인 건너뛰기 {#skip-pipelines-for-draft-merge-requests}

`workflow: rules`을 사용하여 드래프트 머지 리퀘스트에 대한 파이프라인을 건너뛸 수 있습니다. 이 방법은 개발이 완료될 때까지 계산 리소스를 절약합니다.

`CI_MERGE_REQUEST_DRAFT` 변수를 사용하여 머지 리퀘스트가 드래프트 상태인지 확인하세요. 이 변수는 GitLab이 지원하는 모든 드래프트 형식을 자동으로 감지합니다.

```yaml
workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event" && $CI_MERGE_REQUEST_DRAFT == "true"
      when: never
    - when: always

stages:
  - build

build-job:
  stage: build
  script:
    - echo "Testing"
```

> [!note]
> `CI_MERGE_REQUEST_DRAFT` 변수는 GitLab 17.10에서 도입되었습니다. 이전 버전의 경우 `CI_MERGE_REQUEST_TITLE`을 정규식과 함께 사용하세요.

## 문제 해결 {#troubleshooting}

### 머지 리퀘스트가 `Checking pipeline status.` 메시지로 인해 중단됨 {#merge-request-stuck-with-checking-pipeline-status-message}

머지 리퀘스트에 `Checking pipeline status.`이 표시되지만 메시지가 사라지지 않으면("스피너"가 계속 회전하면) `workflow:rules`로 인해 발생할 수 있습니다. 프로젝트에 [**파이프라인이 성공해야 함**](../../user/project/merge_requests/auto_merge.md#require-a-successful-pipeline-for-merge)이 활성화되어 있지만 `workflow:rules`이 머지 리퀘스트에 대한 파이프라인이 실행되는 것을 방지하면 이 문제가 발생할 수 있습니다.

예를 들어 이 워크플로우를 사용하면 머지 리퀘스트는 실행할 수 있는 파이프라인이 없으므로 병합할 수 없습니다:

```yaml
workflow:
  rules:
    - changes:
        - .gitlab/**/**.md
      when: never
```
