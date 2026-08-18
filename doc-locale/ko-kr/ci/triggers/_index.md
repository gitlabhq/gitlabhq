---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API를 사용하여 파이프라인 트리거하기
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[파이프라인 트리거 API 엔드포인트](../../api/pipeline_triggers.md)로 API 호출을 사용하여 특정 브랜치 또는 태그에 대한 파이프라인을 트리거할 수 있습니다.

[CI/CD 작업에서 다운스트림 파이프라인 트리거](../pipelines/downstream_pipelines.md)를 `trigger` 키워드로 수행할 수도 있습니다.

[GitLab CI/CD로 마이그레이션](../migration/plan_a_migration.md)하는 경우 다른 공급자의 작업에서 API 엔드포인트를 호출하여 GitLab CI/CD 파이프라인을 트리거할 수 있습니다. 예를 들어 [Jenkins](../migration/jenkins.md) 또는 [CircleCI](../migration/circleci.md)에서 마이그레이션하는 과정의 일부입니다.

API를 사용하여 인증할 때 다음을 사용할 수 있습니다:

- [파이프라인 트리거 토큰](#create-a-pipeline-trigger-token)을 사용하여 브랜치 또는 태그 파이프라인을 [파이프라인 트리거 API 엔드포인트](../../api/pipeline_triggers.md)로 트리거합니다.
- [CI/CD 작업 토큰](../jobs/ci_job_token.md)을 사용하여 [다중 프로젝트 파이프라인 트리거](../pipelines/downstream_pipelines.md#trigger-a-multi-project-pipeline-by-using-the-api)합니다.
- 다른 [API 액세스 토큰](../../security/tokens/_index.md)을 사용하여 [프로젝트 파이프라인 API 엔드포인트](../../api/pipelines.md#create-a-new-pipeline)로 새 파이프라인을 생성합니다.

## 파이프라인 트리거 토큰 생성 {#create-a-pipeline-trigger-token}

브랜치 또는 태그에 대한 파이프라인 트리거 토큰을 생성하고 이를 사용하여 API 호출을 인증할 수 있습니다. 토큰은 사용자의 프로젝트 액세스 권한 및 권한을 가장합니다.

전제 조건:

- 프로젝트에 대해 Maintainer 또는 Owner 역할이 필요합니다.

트리거 토큰을 생성하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **파이프라인 트리거 토큰**을 확장합니다.
1. **새 토큰 추가**를 선택합니다.
1. 설명을 입력하고 **파이프라인 트리거 토큰 생성**을 선택합니다.
   - 생성한 모든 트리거의 전체 토큰을 보고 복사할 수 있습니다.
   - 다른 프로젝트 구성원이 생성한 토큰은 처음 4자만 볼 수 있습니다.

> [!warning]
> 토큰을 일반 텍스트로 공개 프로젝트에 저장하거나 악의적인 사용자가 액세스할 수 있는 방식으로 저장하는 것은 보안 위험입니다. 유출된 트리거 토큰을 사용하여 예약되지 않은 배포를 강제로 수행하거나 CI/CD 변수에 액세스하려고 시도하거나 기타 악의적인 용도로 사용할 수 있습니다. [마스킹된 CI/CD 변수](../variables/_index.md#mask-a-cicd-variable)는 트리거 토큰의 보안을 개선하는 데 도움이 됩니다. 토큰 보안 유지에 대한 자세한 내용은 [보안 고려 사항](../../security/tokens/_index.md#security-considerations)을 참조하세요.

## 파이프라인 트리거 {#trigger-a-pipeline}

[파이프라인 트리거 토큰을 생성](#create-a-pipeline-trigger-token)한 후 API에 액세스할 수 있는 도구나 웹후크를 사용하여 파이프라인을 트리거할 수 있습니다.

### cURL 사용 {#use-curl}

[파이프라인 트리거 API 엔드포인트](../../api/pipeline_triggers.md)를 사용하여 cURL로 파이프라인을 트리거할 수 있습니다. 예를 들어:

- 여러 줄 cURL 명령을 사용합니다:

  ```shell
  curl --request POST \
       --form token=<token> \
       --form ref=<ref_name> \
       "https://gitlab.example.com/api/v4/projects/<project_id>/trigger/pipeline"
  ```

- cURL을 사용하고 `<token>` 및 `<ref_name>`을 쿼리 문자열에 전달합니다:

  ```shell
  curl --request POST \
       "https://gitlab.example.com/api/v4/projects/<project_id>/trigger/pipeline?token=<token>&ref=<ref_name>"
  ```

각 예제에서 다음을 바꿉니다:

- URL을 `https://gitlab.com` 또는 인스턴스의 URL로 바꿉니다.
- `<token>`을 트리거 토큰으로 바꿉니다.
- `<ref_name>`을 브랜치 또는 태그 이름(예: `main`)으로 바꿉니다.
- `<project_id>`을 프로젝트 ID(예: `123456`)로 바꿉니다. 프로젝트 ID는 [프로젝트 개요 페이지](../../user/project/working_with_projects.md#find-the-project-id)에 표시됩니다.

### CI/CD 작업 사용 {#use-a-cicd-job}

파이프라인 트리거 토큰으로 CI/CD 작업을 사용하여 다른 파이프라인이 실행될 때 파이프라인을 트리거할 수 있습니다.

예를 들어, `project-A`에서 태그가 생성될 때 `project-B`의 `main` 브랜치에서 파이프라인을 트리거하려면 프로젝트 A의 `.gitlab-ci.yml` 파일에 다음 작업을 추가합니다:

```yaml
trigger_pipeline:
  stage: deploy
  script:
    - 'curl --fail --request POST --form token=$MY_TRIGGER_TOKEN --form ref=main "${CI_API_V4_URL}/projects/123456/trigger/pipeline"'
  rules:
    - if: $CI_COMMIT_TAG
  environment: production
```

이 예에서:

- `1234`은 `project-B`의 프로젝트 ID입니다. 프로젝트 ID는 [프로젝트 개요 페이지](../../user/project/working_with_projects.md#find-the-project-id)에 표시됩니다.
- [`rules`](../yaml/_index.md#rules)은 `project-A`에 태그가 추가될 때마다 작업을 실행하도록 합니다.
- `MY_TRIGGER_TOKEN`은 트리거 토큰을 포함하는 [마스킹된 CI/CD 변수](../variables/_index.md#mask-a-cicd-variable)입니다.

### 웹후크 사용 {#use-a-webhook}

다른 프로젝트의 웹후크에서 파이프라인을 트리거하려면 푸시 및 태그 이벤트에 대해 다음과 같은 웹후크 URL을 사용합니다:

```plaintext
https://gitlab.example.com/api/v4/projects/<project_id>/ref/<ref_name>/trigger/pipeline?token=<token>
```

바꿉니다:

- URL을 `https://gitlab.com` 또는 인스턴스의 URL로 바꿉니다.
- `<project_id>`을 프로젝트 ID(예: `123456`)로 바꿉니다. 프로젝트 ID는 [프로젝트 개요 페이지](../../user/project/working_with_projects.md#find-the-project-id)에 표시됩니다.
- `<ref_name>`을 브랜치 또는 태그 이름(예: `main`)으로 바꿉니다. 이 값은 웹후크 페이로드의 `ref_name`보다 우선합니다. 페이로드의 `ref`은 원본 리포지토리에서 트리거를 실행한 브랜치입니다. `ref_name`에 슬래시가 포함된 경우 URL 인코딩해야 합니다.
- `<token>`을 파이프라인 트리거 토큰으로 바꿉니다.

#### 웹후크 페이로드 액세스 {#access-webhook-payload}

웹후크를 사용하여 파이프라인을 트리거하는 경우 `TRIGGER_PAYLOAD` [사전 정의된 CI/CD 변수](../variables/predefined_variables.md)를 사용하여 웹후크 페이로드에 액세스할 수 있습니다. 페이로드는 [파일 유형 변수](../variables/_index.md#use-file-type-cicd-variables)로 표시되므로 `cat $TRIGGER_PAYLOAD` 또는 유사한 명령으로 데이터에 액세스할 수 있습니다.

### API 호출에서 CI/CD 변수 전달 {#pass-cicd-variables-in-the-api-call}

트리거 API 호출에서 원하는 수의 [CI/CD 변수](../variables/_index.md)를 전달할 수 있지만 [파이프라인 동작 제어를 위해 입력 사용](#pass-pipeline-inputs-in-the-api-call)은 CI/CD 변수보다 향상된 보안 및 유연성을 제공합니다.

이 변수는 [가장 높은 우선순위](../variables/_index.md#cicd-variable-precedence)를 가지며 같은 이름의 모든 변수를 재정의합니다.

매개변수는 `variables[key]=value` 형식입니다. 예를 들면:

```shell
curl --request POST \
     --form token=TOKEN \
     --form ref=main \
     --form "variables[UPLOAD_TO_S3]=true" \
     "https://gitlab.example.com/api/v4/projects/123456/trigger/pipeline"
```

트리거된 파이프라인의 CI/CD 변수는 각 작업 페이지에 표시되지만 Owner 및 Maintainer 역할을 가진 사용자만 값을 볼 수 있습니다.

![토큰 4e19의 CI 트리거 구성 패널로 UPLOAD_TO_CI가 true로 설정됨](img/trigger_variables_v11_6.png)

파이프라인 동작 제어를 위해 입력을 사용하면 CI/CD 변수보다 향상된 보안 및 유연성을 제공합니다.

### API 호출에서 파이프라인 입력 전달 {#pass-pipeline-inputs-in-the-api-call}

트리거 API 호출에서 파이프라인 입력을 전달할 수 있습니다. [입력](../inputs/_index.md)은 기본 제공 유효성 검사 및 문서화를 통해 파이프라인을 매개변수화하는 구조화된 방법을 제공합니다.

매개변수 형식은 `inputs[name]=value`입니다. 예를 들면:

```shell
curl --request POST \
     --form token=TOKEN \
     --form ref=main \
     --form "inputs[environment]=production" \
     "https://gitlab.example.com/api/v4/projects/123456/trigger/pipeline"
```

입력 값은 파이프라인의 `spec:inputs` 섹션에 정의된 유형 및 제약 조건에 따라 유효성이 검사됩니다:

```yaml
spec:
  inputs:
    environment:
      type: string
      description: "Deployment environment"
      options: [dev, staging, production]
      default: dev
```

## 파이프라인 트리거 토큰 해지 {#revoke-a-pipeline-trigger-token}

파이프라인 트리거 토큰을 해지하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **파이프라인 트리거**를 확장합니다.
1. 해지할 트리거 토큰의 왼쪽에서 **해지** ({{< icon name="remove" >}})를 선택합니다.

해지된 트리거 토큰은 다시 추가할 수 없습니다.

## 트리거된 파이프라인에서 실행할 CI/CD 작업 구성 {#configure-cicd-jobs-to-run-in-triggered-pipelines}

트리거된 파이프라인에서 작업 실행 시기를 [구성](../jobs/job_control.md)하려면 다음을 수행할 수 있습니다:

- [`rules`](../yaml/_index.md#rules)을 `$CI_PIPELINE_SOURCE` [사전 정의된 CI/CD 변수](../variables/predefined_variables.md)와 함께 사용합니다.
- [`only`/`except`](../yaml/deprecated_keywords.md#onlyrefs--exceptrefs) 키워드를 사용하되 `rules`가 기본 설정 키워드입니다.

| `$CI_PIPELINE_SOURCE` 값 | `only`/`except` 키워드 | 트리거 방법      |
|-----------------------------|--------------------------|---------------------|
| `trigger`                   | `triggers`               | [파이프라인 트리거 API](../../api/pipeline_triggers.md)를 사용하여 [트리거 토큰](#create-a-pipeline-trigger-token)으로 트리거된 파이프라인에서. |
| `pipeline`                  | `pipelines`              | [다중 프로젝트 파이프라인](../pipelines/downstream_pipelines.md#trigger-a-multi-project-pipeline-by-using-the-api)에서 [파이프라인 트리거 API](../../api/pipeline_triggers.md)를 사용하여 [`$CI_JOB_TOKEN`](../jobs/ci_job_token.md)로 트리거되거나 CI/CD 구성 파일에서 [`trigger`](../yaml/_index.md#trigger) 키워드를 사용하여 트리거됩니다. |

또한 `$CI_PIPELINE_TRIGGERED` 사전 정의된 CI/CD 변수는 파이프라인 트리거 토큰으로 트리거된 파이프라인에서 `true`로 설정됩니다.

## 사용된 파이프라인 트리거 토큰 확인 {#see-which-pipeline-trigger-token-was-used}

단일 작업 페이지를 방문하여 작업을 실행한 파이프라인 트리거 토큰을 확인할 수 있습니다. 트리거 토큰의 일부는 **Job details** 아래 오른쪽 사이드바에 표시됩니다.

파이프라인 트리거 토큰으로 트리거된 파이프라인에서 작업은 **빌드** > **작업**에서 `triggered`으로 레이블이 지정됩니다.

## 문제 해결 {#troubleshooting}

### `403 Forbidden` 웹후크로 파이프라인을 트리거할 때 {#403-forbidden-when-you-trigger-a-pipeline-with-a-webhook}

웹후크로 파이프라인을 트리거하면 API가 `{"message":"403 Forbidden"}` 응답을 반환할 수 있습니다. 트리거 루프를 방지하려면 [파이프라인 이벤트](../../user/project/integrations/webhook_events.md#pipeline-events)를 사용하여 파이프라인을 트리거하지 마세요.

### `404 Not Found` 파이프라인 트리거 시 {#404-not-found-when-triggering-a-pipeline}

파이프라인 트리거 시 `{"message":"404 Not Found"}` 응답은 파이프라인 트리거 토큰 대신 [개인 액세스 토큰](../../user/profile/personal_access_tokens.md)을 사용하기 때문일 수 있습니다. [새 트리거 토큰 생성](#create-a-pipeline-trigger-token)을 수행하고 개인 액세스 토큰 대신 이를 사용합니다.

파이프라인 트리거 시 `{"message":"404 Not Found"}` 응답은 `GET` 요청을 사용하기 때문일 수도 있습니다. 파이프라인은 `POST` 요청을 사용하여만 트리거할 수 있습니다.

### `The requested URL returned error: 400` 파이프라인 트리거 시 {#the-requested-url-returned-error-400-when-triggering-a-pipeline}

존재하지 않는 브랜치 이름인 `ref`을 사용하여 파이프라인을 트리거하려고 시도하면 GitLab이 `The requested URL returned error: 400`을 반환합니다.

예를 들어 기본 브랜치에 다른 브랜치 이름을 사용하는 프로젝트에서 `main`을 브랜치 이름으로 실수로 사용했을 수 있습니다.

이 오류의 또 다른 가능한 원인은 `CI_PIPELINE_SOURCE` 값이 `trigger`일 때 파이프라인 생성을 방지하는 규칙입니다. 예를 들면:

```yaml
rules:
  - if: $CI_PIPELINE_SOURCE == "trigger"
    when: never
```

`CI_PIPELINE_SOURCE` 값이 `trigger`일 때 파이프라인을 생성할 수 있는지 확인하려면 [`workflow:rules`](../yaml/_index.md#workflowrules)을 검토합니다.
