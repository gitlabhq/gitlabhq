---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "규칙, 조건 및 변수 표현식을 사용하여 작업이 실행되는 시점을 제어합니다."
title: 로 작업이 실행되는 시점 지정
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[`rules`](../yaml/_index.md#rules) 키워드를 사용하여 파이프라인에서 작업을 포함하거나 제외합니다.

규칙은 첫 번째 일치 항목이 나타날 때까지 순서대로 평가됩니다. 일치 항목이 발견되면 구성에 따라 작업이 파이프라인에 포함되거나 제외됩니다.

규칙은 작업이 실행되기 전에 평가되므로 작업 스크립트에서 만든 dotenv 변수를 규칙에서 사용할 수 없습니다.

## `rules` 예제 {#rules-examples}

다음 예제는 `if`를 사용하여 작업이 두 가지 특정 경우에만 실행되도록 정의합니다:

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      when: manual
      allow_failure: true
    - if: $CI_PIPELINE_SOURCE == "schedule"
```

- 파이프라인이 머지 리퀘스트용이면 첫 번째 규칙이 일치하고 작업이 다음 속성과 함께 머지 리퀘스트 파이프라인에 추가됩니다:
  - `when: manual` (수동 작업)
  - `allow_failure: true` (수동 작업이 실행되지 않아도 파이프라인이 계속 실행됨)
- 파이프라인이 머지 리퀘스트용이 아니면 첫 번째 규칙이 일치하지 않고 두 번째 규칙이 평가됩니다.
- 파이프라인이 예약된 파이프라인이면 두 번째 규칙이 일치하고 작업이 예약된 파이프라인에 추가됩니다. 정의된 속성이 없으므로 다음과 함께 추가됩니다:
  - `when: on_success` (기본값)
  - `allow_failure: false` (기본값)
- 다른 모든 경우에는 규칙이 일치하지 않으므로 작업이 다른 파이프라인에 추가되지 않습니다.

또는 몇 가지 경우에는 작업을 제외하고 다른 모든 경우에는 작업을 실행하는 규칙 집합을 정의할 수 있습니다:

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      when: never
    - if: $CI_PIPELINE_SOURCE == "schedule"
      when: never
    - when: on_success
```

- 파이프라인이 머지 리퀘스트용이면 작업이 파이프라인에 추가되지 않습니다.
- 파이프라인이 예약된 파이프라인이면 작업이 파이프라인에 추가되지 않습니다.
- 다른 모든 경우에는 작업이 `when: on_success`과(와) 함께 파이프라인에 추가됩니다.

> [!warning]
> `when` 절을 최종 규칙으로 사용하면(`when: never`을 포함하지 않음) 두 개의 동시 파이프라인이 시작될 수 있습니다. 푸시 파이프라인과 머지 리퀘스트 파이프라인은 모두 동일한 이벤트(열린 머지 리퀘스트의 소스 브랜치로 푸시)에 의해 트리거될 수 있습니다. [중복 파이프라인 방지](#avoid-duplicate-pipelines) 방법을 참조하여 자세한 내용을 확인하세요.

### 예약된 파이프라인용 작업 실행 {#run-jobs-for-scheduled-pipelines}

파이프라인이 예약된 경우에만 실행하도록 작업을 구성할 수 있습니다. 예를 들어:

```yaml
job:on-schedule:
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
  script:
    - make world

job:
  rules:
    - if: $CI_PIPELINE_SOURCE == "push"
  script:
    - make build
```

이 예제에서 `make world`은 예약된 파이프라인에서 실행되고 `make build`는 브랜치 및 태그 파이프라인에서 실행됩니다.

### 브랜치가 비어있으면 작업 건너뛰기 {#skip-jobs-if-the-branch-is-empty}

[`rules:changes:compare_to`](../yaml/_index.md#ruleschangescompare_to)를 사용하여 브랜치가 비어있을 때 작업을 건너뛰어 CI/CD 리소스를 절약합니다. 구성은 브랜치를 기본 브랜치와 비교하고 브랜치가:

- 변경된 파일이 없으면 작업이 실행되지 않습니다.
- 변경된 파일이 있으면 작업이 실행됩니다.

예를 들어 `main`을(를) 기본 브랜치로 하는 프로젝트에서:

```yaml
job:
  script:
    - echo "This job only runs for branches that are not empty"
  rules:
    - if: $CI_COMMIT_BRANCH
      changes:
        compare_to: 'refs/heads/main'
        paths:
          - '**/*'
```

이 작업의 규칙은 현재 브랜치의 모든 파일과 경로를 재귀적으로(`**/*`) `main` 브랜치와 비교합니다. 규칙이 일치하고 브랜치의 파일에 변경 사항이 있을 때만 작업이 실행됩니다.

`parallel:matrix` 작업의 경우 [`rules:changes` 경로에서 행렬 변수 사용](job_control.md#use-matrix-variables-in-rules)을(를) 통해 해당 행렬 값과 관련된 파일이 변경된 경우에만 각 작업 인스턴스를 실행할 수 있습니다.

## 파일이 없을 때 작업 실행 {#run-a-job-when-a-file-is-not-present}

`rules: exists`를 사용하여 특정 파일이 없을 때만 실행하도록 작업을 구성할 수 있습니다.

예를 들어 `example.yml` 파일이 없을 때 머지 리퀘스트 파이프라인에서 작업을 실행하려면:

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - exists:
      - "example_dir/example.yml"
      when: never
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

이 예제에서 `example_dir/example.yml` 파일이 브랜치에 있으면 작업이 실행되지 않습니다. 파일이 없으면 작업이 머지 리퀘스트 파이프라인에서 실행될 수 있습니다.

`parallel:matrix` 작업의 경우 [`rules:exists` 경로에서 행렬 변수 사용](job_control.md#use-matrix-variables-in-rules)을(를) 통해 특정 파일이 있을 때만 작업 인스턴스를 포함할 수 있습니다.

## 사전 정의된 변수가 있는 일반적인 `if` 절 {#common-if-clauses-with-predefined-variables}

`rules:if` 절은 일반적으로 [사전 정의된 CI/CD 변수](../variables/predefined_variables.md)와 함께 사용되며, 특히 `CI_PIPELINE_SOURCE`입니다.

다음 예제는 예약된 파이프라인이나 푸시 파이프라인(브랜치 또는 태그)에서 작업을 수동 작업으로 실행하며 `when: on_success` (기본값)입니다. 다른 파이프라인 유형에는 작업을 추가하지 않습니다.

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
      when: manual
      allow_failure: true
    - if: $CI_PIPELINE_SOURCE == "push"
```

다음 예제는 머지 리퀘스트 파이프라인 및 예약된 파이프라인에서 작업을 `when: on_success` 작업으로 실행합니다. 다른 파이프라인 유형에서는 실행되지 않습니다.

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_PIPELINE_SOURCE == "schedule"
```

일반적으로 사용되는 다른 `if` 절:

- `if: $CI_COMMIT_TAG`: 태그로 변경 사항을 푸시하면입니다.
- `if: $CI_COMMIT_BRANCH`: 모든 브랜치로 변경 사항을 푸시하면입니다.
- `if: $CI_COMMIT_BRANCH == "main"`: `main`로 변경 사항을 푸시하면입니다.
- `if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH`: 기본 브랜치로 변경 사항을 푸시하면입니다.
- `if: $CI_COMMIT_BRANCH =~ /regex-expression/`: 커밋 브랜치가 정규 표현식과 일치하면입니다.
- `if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH && $CI_COMMIT_TITLE =~ /Merge branch.*/`: 커밋 브랜치가 기본 브랜치이고 커밋 메시지 제목이 정규 표현식과 일치하면입니다.
- `if: $CUSTOM_VARIABLE == "value1"`: 사용자 정의 변수 `CUSTOM_VARIABLE`이(가) 정확히 `value1`이면입니다.

### 특정 파이프라인 유형에서만 작업 실행 {#run-jobs-only-in-specific-pipeline-types}

사전 정의된 CI/CD 변수를 `rules`과(와) 함께 사용하여 작업이 실행되어야 하는 파이프라인 유형을 선택할 수 있습니다.

다음 표는 사용할 수 있는 일부 변수와 해당 변수가 제어할 수 있는 파이프라인 유형을 나열합니다:

- Git `push` 이벤트로 브랜치로 실행되는 브랜치 파이프라인(새 커밋이나 태그 등)입니다.
- 새 Git 태그를 브랜치로 푸시할 때만 실행되는 태그 파이프라인입니다.
- 머지 리퀘스트에 변경 사항을 적용할 때 실행되는 머지 리퀘스트 파이프라인(새 커밋이나 머지 리퀘스트의 파이프라인 탭에서 **파이프라인 실행** 선택 등)입니다.
- 예약된 파이프라인입니다.

| 변수                                  | 브랜치 | 태그 | 머지 리퀘스트 | 예약됨 |
|--------------------------------------------|--------|-----|---------------|-----------|
| `CI_COMMIT_BRANCH`                         | 예    |     |               | 예       |
| `CI_COMMIT_TAG`                            |        | 예 |               | 예, 예약된 파이프라인이 태그에서 실행되도록 구성된 경우입니다. |
| `CI_PIPELINE_SOURCE = push`                | 예    | 예 |               |           |
| `CI_PIPELINE_SOURCE = schedule`            |        |     |               | 예       |
| `CI_PIPELINE_SOURCE = merge_request_event` |        |     | 예           |           |
| `CI_MERGE_REQUEST_IID`                     |        |     | 예           |           |

예를 들어 머지 리퀘스트 파이프라인 및 예약된 파이프라인에서는 실행되지만 브랜치 또는 태그 파이프라인에서는 실행되지 않도록 작업을 구성하려면:

```yaml
job1:
  script:
    - echo
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_PIPELINE_SOURCE == "schedule"
    - if: $CI_PIPELINE_SOURCE == "push"
      when: never
```

### `CI_PIPELINE_SOURCE` 사전 정의된 변수 {#ci_pipeline_source-predefined-variable}

`CI_PIPELINE_SOURCE` 변수를 사용하여 이러한 파이프라인 유형에 대해 작업을 추가할 시기를 제어합니다:

| 값                           | 설명 |
|---------------------------------|-------------|
| `api`                           | [파이프라인 API](../../api/pipelines.md#create-a-new-pipeline)에서 트리거된 파이프라인용입니다. |
| `chat`                          | [GitLab ChatOps](../chatops/_index.md) 명령을 사용하여 생성된 파이프라인용입니다. |
| `external`                      | GitLab이 아닌 다른 CI 서비스를 사용할 때입니다. |
| `external_pull_request_event`   | [GitHub의 외부 풀 리퀘스트](../ci_cd_for_external_repos/_index.md#pipelines-for-external-pull-requests)가 생성되거나 업데이트될 때입니다. |
| `merge_request_event`           | 머지 리퀘스트가 생성되거나 업데이트될 때 생성된 파이프라인용입니다. [머지 리퀘스트 파이프라인](../pipelines/merge_request_pipelines.md), [병합된 결과 파이프라인](../pipelines/merged_results_pipelines.md) 및 [머지 트레인](../pipelines/merge_trains.md)을(를) 활성화하는 데 필요합니다. |
| `ondemand_dast_scan`            | [DAST 온디맨드 스캔](../../user/application_security/dast/on-demand_scan.md) 파이프라인용입니다. |
| `ondemand_dast_validation`      | [DAST 온디맨드 검증](../../user/application_security/dast/profiles.md#site-profile-validation) 파이프라인용입니다. |
| `parent_pipeline`               | [상위 파이프라인](../pipelines/downstream_pipelines.md#parent-child-pipelines)에서 트리거된 하위 파이프라인용입니다. 상위 파이프라인에서 트리거될 수 있도록 하위 파이프라인 구성에서 이 파이프라인 소스를 사용합니다. |
| `pipeline`                      | [다중 프로젝트 파이프라인](../pipelines/downstream_pipelines.md#multi-project-pipelines)용입니다. |
| `push`                          | Git 푸시 이벤트에서 트리거된 파이프라인용(브랜치 및 태그 포함)입니다. |
| `schedule`                      | [예약된 파이프라인](../pipelines/schedules.md)용입니다. |
| `security_orchestration_policy` | [예약된 스캔 실행 정책](../../user/application_security/policies/scan_execution_policies.md) 파이프라인용입니다. |
| `trigger`                       | [트리거 토큰](../triggers/_index.md#configure-cicd-jobs-to-run-in-triggered-pipelines)을(를) 사용하여 생성된 파이프라인용입니다. |
| `web`                           | GitLab UI에서 **새 파이프라인**을(를) 선택하여 생성된 파이프라인용(프로젝트의 **빌드** > **파이프라인** 섹션)입니다. |
| `webide`                        | [Web IDE](../../user/project/web_ide/_index.md)를 사용하여 생성된 파이프라인용입니다. |

이러한 값은 [파이프라인 API 끝점](../../api/pipelines.md#list-project-pipelines)을(를) 사용할 때 `source` 매개변수에 대해 반환되는 값과 동일합니다.

## 복잡한 규칙 {#complex-rules}

`rules` 키워드(예: `if`, `changes` 및 `exists`)를 동일한 규칙에서 사용할 수 있습니다. 규칙은 포함된 모든 키워드가 참으로 평가될 때만 참으로 평가됩니다.

예를 들어:

```yaml
docker build:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - if: $VAR == "string value"
      changes:  # Include the job and set to when:manual if any of the follow paths match a modified file.
        - Dockerfile
        - docker/scripts/**/*
      when: manual
      allow_failure: true
```

`Dockerfile` 파일 또는 `/docker/scripts`의 모든 파일이 변경되고 `$VAR == "string value"`이면 작업이 수동으로 실행되고 실패할 수 있습니다.

더 복잡한 변수 표현식을 구성하기 위해 `&&` 및 `||`와(과) 함께 괄호를 사용할 수 있습니다.

```yaml
job1:
  script:
    - echo This rule uses parentheses.
  rules:
    - if: ($CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH || $CI_COMMIT_BRANCH == "develop") && $MY_VARIABLE
```

## 중복 파이프라인 방지 {#avoid-duplicate-pipelines}

작업이 `rules`을(를) 사용하면 커밋을 브랜치로 푸시하는 것과 같은 단일 작업이 여러 파이프라인을 트리거할 수 있습니다. 여러 파이프라인 유형에 대한 규칙을 명시적으로 구성하여 우발적으로 트리거할 필요는 없습니다.

예를 들어:

```yaml
job:
  script: echo "This job creates double pipelines!"
  rules:
    - if: $CUSTOM_VARIABLE == "false"
      when: never
    - when: always
```

이 작업은 `$CUSTOM_VARIABLE`이 거짓일 때는 실행되지 않지만 푸시(브랜치) 및 머지 리퀘스트 파이프라인을 포함한 다른 모든 파이프라인에서는 실행됩니다. 이 구성으로 열린 머지 리퀘스트의 소스 브랜치로 푸시할 때마다 중복 파이프라인이 발생합니다.

중복 파이프라인을 방지하려면 다음을 수행할 수 있습니다:

- [`workflow`](../yaml/_index.md#workflow)를 사용하여 실행할 수 있는 파이프라인 유형을 지정합니다.
- 규칙을 다시 작성하여 매우 구체적인 경우에만 작업을 실행하고 최종 `when` 규칙을 피합니다:

  ```yaml
  job:
    script: echo "This job does NOT create double pipelines!"
    rules:
      - if: $CUSTOM_VARIABLE == "true" && $CI_PIPELINE_SOURCE == "merge_request_event"
  ```

또한 작업 규칙을 변경하여 푸시(브랜치) 파이프라인 또는 머지 리퀘스트 파이프라인을 피함으로써 중복 파이프라인을 방지할 수 있습니다. 그러나 `- when: always` 규칙을 `workflow: rules` 없이 사용하면 GitLab에서 [파이프라인 경고](../debugging.md#pipeline-warnings)를 표시합니다.

예를 들어 다음은 중복 파이프라인을 발생시키지 않지만 `workflow: rules` 없이는 권장되지 않습니다:

```yaml
job:
  script: echo "This job does NOT create double pipelines!"
  rules:
    - if: $CI_PIPELINE_SOURCE == "push"
      when: never
    - when: always
```

[`workflow:rules` 중복 파이프라인을 방지](../yaml/workflow.md#switch-between-branch-pipelines-and-merge-request-pipelines)하는 동일한 작업에서 푸시 및 머지 리퀘스트 파이프라인을 모두 포함하면 안 됩니다:

```yaml
job:
  script: echo "This job creates double pipelines!"
  rules:
    - if: $CI_PIPELINE_SOURCE == "push"
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

또한 동일한 파이프라인에서 `only/except` 작업을 `rules` 작업과(과) 혼합하면 안 됩니다. YAML 오류를 발생시키지 않을 수 있지만 `only/except` 및 `rules`의 다른 기본 동작으로 인해 문제를 해결하기 어려운 문제가 발생할 수 있습니다:

```yaml
job-with-no-rules:
  script: echo "This job runs in branch pipelines."

job-with-rules:
  script: echo "This job runs in merge request pipelines."
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

열린 머지 리퀘스트가 있는 브랜치에 푸시된 모든 변경 사항에 대해 중복 파이프라인이 실행됩니다. 한 브랜치 파이프라인은 단일 작업(`job-with-no-rules`)을 실행하고 하나의 머지 리퀘스트 파이프라인은 다른 작업(`job-with-rules`)을 실행합니다. 규칙이 없는 작업은 [`except: merge_requests`](../yaml/deprecated_keywords.md#only--except)로 기본 설정되므로 `job-with-no-rules`은(는) 머지 리퀘스트를 제외한 모든 경우에 실행됩니다.

## 다양한 작업에서 규칙 재사용 {#reuse-rules-in-different-jobs}

[`!reference` 태그](../yaml/yaml_optimization.md#reference-tags)를 사용하여 여러 작업에서 규칙을 재사용합니다. `!reference` 규칙을 작업에 정의된 규칙과 함께 결합할 수 있습니다. 예를 들어:

```yaml
.default_rules:
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
      when: never
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

job1:
  rules:
    - !reference [.default_rules, rules]
  script:
    - echo "This job runs for the default branch, but not schedules."

job2:
  rules:
    - !reference [.default_rules, rules]
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  script:
    - echo "This job runs for the default branch, but not schedules."
    - echo "It also runs for merge requests."
```

## CI/CD 변수 표현식 {#cicd-variable-expressions}

[`rules:if`](../yaml/_index.md#rulesif)를 사용한 변수 표현식을 사용하여 작업을 파이프라인에 추가해야 할 시점을 제어합니다.

동등 연산자 `==` 및 `!=`를 사용하여 변수를 문자열과 비교할 수 있습니다. 작은 따옴표와 큰 따옴표 모두 유효합니다. 변수는 비교의 왼쪽에 있어야 합니다. 예를 들어:

- `if: $VARIABLE == "some value"`
- `if: $VARIABLE != "some value"`

두 변수의 값을 비교할 수 있습니다. 예를 들어:

- `if: $VARIABLE_1 == $VARIABLE_2`
- `if: $VARIABLE_1 != $VARIABLE_2`

변수를 `null` 키워드와 비교하여 변수가 정의되어 있는지 확인할 수 있습니다. 예를 들어:

- `if: $VARIABLE == null`
- `if: $VARIABLE != null`

변수가 정의되어 있지만 비어있는지 확인할 수 있습니다. 예를 들어:

- `if: $VARIABLE == ""`
- `if: $VARIABLE != ""`

표현식에서 변수 이름만 사용하여 변수가 정의되어 있고 비어있지 않은지 확인할 수 있습니다. 예를 들어:

- `if: $VARIABLE`

다음도 가능합니다:

- [변수 표현식에서 CI/CD 입력 사용](../inputs/examples.md#use-cicd-inputs-in-variable-expressions).
- [`parallel:matrix` 변수를 `rules:if` 표현식에서 사용](job_control.md#use-matrix-variables-in-rules).

### 변수를 정규 표현식과 비교 {#compare-a-variable-to-a-regular-expression}

`=~` 및 `!~` 연산자를 사용하여 변수 값의 정규 표현식 일치를 수행할 수 있습니다.

표현식은 다음과 같을 때 `true`로 평가됩니다:

- `=~`을(를) 사용할 때 일치 항목을 찾습니다.
- `!~`을(를) 사용할 때 일치 항목을 찾을 수 없습니다.

예를 들어:

- `if: $VARIABLE =~ /^content.*/`
- `if: $VARIABLE !~ /^content.*/`

또한:

- `/./`과(와) 같은 단일 문자 정규 표현식은 지원되지 않으며 `invalid expression syntax` 오류를 생성합니다.
- 패턴 매칭은 기본적으로 대소문자를 구분합니다. `i` 플래그 수정자를 사용하여 패턴을 대소문자를 구분하지 않도록 합니다. 예: `/pattern/i`.
- 정규 표현식으로 일치할 수 있는 것은 태그 또는 브랜치 이름뿐입니다. 리포지토리 경로는 항상 문자 그대로 일치됩니다.
- 전체 패턴은 `/`로 둘러싸여 있어야 합니다. 예를 들어 `issue-/.*/`를 사용하여 `issue-`으로 시작하는 모든 태그 이름이나 브랜치 이름을 일치시킬 수는 없지만 `/issue-.*/`를 사용할 수 있습니다.
- `@` 기호는 ref의 리포지토리 경로의 시작을 나타냅니다. 정규 표현식에서 `@` 문자가 포함된 ref 이름을 일치시키려면 16진 문자 코드 일치 `\x40`을(를) 사용해야 합니다.
- 앵커 `^` 및 `$`를 사용하여 정규 표현식이 태그 이름 또는 브랜치 이름의 부분 문자열만 일치하지 않도록 합니다. 예를 들어 `/^issue-.*$/`는 `/^issue-/`과(와) 동일하지만 `/issue/`만 해도 `severe-issues`이라는 브랜치와 일치합니다.
- 변수 패턴 매칭(정규 표현식 사용)은 [RE2 정규 표현식 구문](https://github.com/google/re2/wiki/Syntax)을(를) 사용합니다.

### 변수에 정규 표현식 저장 {#store-a-regular-expression-in-a-variable}

`=~` 및 `!~` 표현식의 오른쪽에 있는 변수는 정규 표현식으로 평가됩니다. 정규 표현식은 앞으로 빗금(`/`)으로 묶여 있어야 합니다. 예를 들어:

```yaml
variables:
  pattern: '/^ab.*/'

regex-job1:
  variables:
    teststring: 'abcde'
  script: echo "This job will run, because 'abcde' matches the /^ab.*/ pattern."
  rules:
    - if: '$teststring =~ $pattern'

regex-job2:
  variables:
    teststring: 'fghij'
  script: echo "This job will not run, because 'fghi' does not match the /^ab.*/ pattern."
  rules:
    - if: '$teststring =~ $pattern'
```

정규 표현식의 변수는 확장되지 않습니다. 예를 들어:

```yaml
variables:
  string1: 'regex-job1'
  string2: 'regex-job2'
  pattern: '/$string2/'

regex-job1:
  script: echo "This job will NOT run, because the 'string1' variable inside the regex pattern is not expanded."
  rules:
    - if: '$CI_JOB_NAME =~ /$string1/'

regex-job2:
  script: echo "This job will NOT run, because the 'string2' variable inside the 'pattern' variable is not expanded."
  rules:
    - if: '$CI_JOB_NAME =~ $pattern'
```

### 변수 표현식 결합 {#join-variable-expressions-together}

`&&` (및) 또는 `||` (또는)를 사용하여 여러 표현식을 결합할 수 있습니다. 예를 들어:

- `$VARIABLE1 =~ /^content.*/ && $VARIABLE2 == "something"`
- `$VARIABLE1 =~ /^content.*/ && $VARIABLE2 =~ /thing$/ && $VARIABLE3`
- `$VARIABLE1 =~ /^content.*/ || $VARIABLE2 =~ /thing$/ && $VARIABLE3`

괄호를 사용하여 표현식을 그룹화할 수 있습니다. 괄호는 `&&` 및 `||`보다 우선 순위가 높으므로 괄호로 묶인 표현식이 먼저 평가되고 그 결과가 표현식의 나머지에 사용됩니다. 연산자의 우선 순위의 경우 `&&`은(는) `||`보다 먼저 평가됩니다.

괄호를 중첩하여 복잡한 조건을 만들고 괄호 안의 가장 안쪽 표현식이 먼저 평가됩니다. 예를 들어:

- `($VARIABLE1 =~ /^content.*/ || $VARIABLE2) && ($VARIABLE3 =~ /thing$/ || $VARIABLE4)`
- `($VARIABLE1 =~ /^content.*/ || $VARIABLE2 =~ /thing$/) && $VARIABLE3`
- `$CI_COMMIT_BRANCH == "my-branch" || (($VARIABLE1 == "thing" || $VARIABLE2 == "thing") && $VARIABLE3)`

### 표현식 부정 {#negate-expressions}

{{< history >}}

- GitLab 18.11에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219430).

{{< /history >}}

`!` 연산자를 사용하여 표현식 또는 표현식의 일부를 부정할 수 있습니다. 예를 들어:

- `if: "!$VAR1"`: 변수가 비어있거나 정의되지 않을 때 참입니다.
- `if: !($VAR1 == "my variable")`: 변수 값이 `my variable`과(와) 일치하지 않을 때 참입니다.
- `if: $VAR1 && !$VAR2`: `VAR1`가 존재하고 비어있지 않으며 `VAR2`이 존재하지 않거나 비어있을 때 참입니다.
- `if: !($VAR1 || $VAR2)`: 두 변수가 모두 존재하지 않거나 비어있을 때만 참입니다.
- `if: !($VAR1 && $VAR2)`: 변수 중 하나가 존재하지 않거나 비어있을 때 참입니다.

> [!warning]
> `!` 연산자는 변수가 비어있는지 또는 정의되지 않았는지 확인하며, 값이 `false` 또는 `0`인지 여부는 확인하지 않습니다. 예를 들어:
>
> - `!"false"`은(는) `false`로 평가됩니다. 문자열 `"false"`이 비어있지 않기 때문입니다(비어있지 않은 문자열은 참입니다).
> - `!"0"`도 `false`로 평가됩니다. 문자열이 비어있지 않기 때문입니다.
> - `!""`은(는) `true`로 평가됩니다. 문자열이 비어있기 때문입니다(빈 문자열은 거짓입니다).
>
> 특정 값을 확인하려면 비교 연산자(예: `!($VAR == "false")` 또는 `!($VAR == "0")`)를 사용합니다.

## `only` 또는 `except`에서 `rules`으로 마이그레이션 {#migrate-from-only-or-except-to-rules}

`rules` 및 CI/CD 변수 표현식을 사용하여 더 이상 사용되지 않는 [`only` 및 `except` 키워드](../yaml/deprecated_keywords.md#only--except)와 동일한 동작을 재현합니다.

예를 들어 이 더 이상 사용되지 않는 구성으로 시작하면:

```yaml
job1:
  script: echo
  only:
    - main
    - /^stable-branch.*$/
    - schedules

job2:
  script: echo
  except:
    - main
    - /^issue-.*$/
    - merge_requests
```

이 예에서:

- `job1`은(는) 다음 경우 파이프라인에서 실행되도록 `only`를 사용합니다:
  - 브랜치는 기본 브랜치(`main`)입니다.
  - 브랜치 이름이 패턴 `/^stable-branch.*$/`과(와) 일치합니다.
  - 파이프라인이 일정에 따라 실행됩니다.
- `job2`은(는) 다음 경우 파이프라인을 건너뛰도록 `except`를 사용합니다:
  - 브랜치는 기본 브랜치(`main`)입니다.
  - 브랜치 이름이 패턴 `/^issue-.*$/`과(와) 일치합니다.
  - 파이프라인은 머지 리퀘스트 파이프라인입니다.

`rules`을(를) 사용하여 유사한 파이프라인 구성을 생성하려면 CI/CD 변수 표현식을 사용합니다. 예를 들어 `only` 및 `except`에서 `rules`로 직접 마이그레이션하려면:

```yaml
job1:
  script: echo
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    - if: $CI_COMMIT_BRANCH =~ /^stable-branch.*$/
    - if: $CI_PIPELINE_SOURCE == "schedule"

job2:
  script: echo
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      when: never
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      when: never
    - if: $CI_COMMIT_BRANCH =~ /^issue-.*$/
      when: never
    - when: on_success
```

두 작업 모두 `rules`과(와) 같은 방식으로 `only` 및 `except`과(와) 같은 동작을 수행합니다. 그러나 `job2`를 단순화하여 `when: never` 규칙을 피할 수 있습니다.

`job2`이 실행되지 않아야 하는 경우가 아니라 실행되어야 하는 경우에 대한 규칙을 정의합니다. 예를 들어 `job2`이 기본 브랜치를 제외한 모든 브랜치에서 실행되고 태그에서도 실행되어야 하는 경우:

```yaml
job2:
  script: echo
  rules:
    - if: $CI_COMMIT_BRANCH != $CI_DEFAULT_BRANCH
    - if: $CI_COMMIT_TAG
```

이 예제에서 `job2`은 브랜치가 기본 브랜치가 아닐 때와 새 Git 태그가 생성될 때 실행됩니다. 그렇지 않으면 작업이 실행되지 않습니다.

## 문제 해결 {#troubleshooting}

### `=~`을(를) 사용한 정규 표현식 일치의 예상치 못한 동작 {#unexpected-behavior-from-regular-expression-matching-with-}

`=~` 문자를 사용할 때 비교의 오른쪽에 항상 유효한 정규 표현식이 포함되어 있는지 확인합니다.

비교의 오른쪽이 `/` 문자로 묶인 유효한 정규 표현식이 아니면 표현식이 예상치 못한 방식으로 평가됩니다. 이 경우 비교는 왼쪽이 오른쪽의 부분 문자열인지 확인합니다. 예를 들어 `"23" =~ "1234"`은(는) 참으로 평가되지만 `"23" =~ /1234/`은(는) 거짓으로 평가됩니다.

파이프라인을 이 동작에 의존하도록 구성하면 안 됩니다.
