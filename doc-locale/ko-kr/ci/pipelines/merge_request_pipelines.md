---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "GitLab CI/CD에서 머지 리퀘스트 파이프라인을 사용하여 변경 사항을 효율적으로 테스트하고, 대상 작업을 실행하며, 병합 전에 코드 품질을 개선하는 방법을 알아봅니다."
title: 머지 리퀘스트 파이프라인
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

머지 리퀘스트의 소스 브랜치에 변경 사항을 만들 때마다 실행되도록 파이프라인을 구성할 수 있습니다. 이러한 유형의 파이프라인을 머지 리퀘스트 파이프라인이라고 합니다.

다음과 같은 경우 이러한 파이프라인이 실행됩니다:

- 하나 이상의 커밋이 있는 소스 브랜치에서 새 머지 리퀘스트를 생성합니다.
- 머지 리퀘스트의 소스 브랜치에 새 커밋을 푸시합니다.
- 머지 리퀘스트의 **파이프라인** 탭으로 이동하고 **파이프라인 실행**을 선택합니다.

머지 리퀘스트 파이프라인:

- 소스 브랜치의 내용에서만 실행되고 대상 브랜치의 내용은 무시합니다.
- `merge request` 레이블을 파이프라인 목록에 표시합니다.

소스 브랜치와 대상 브랜치를 함께 병합한 결과를 테스트하는 파이프라인을 실행하려면 [병합된 결과 파이프라인](merged_results_pipelines.md)을 사용합니다.

## 전제 조건 {#prerequisites}

머지 리퀘스트 파이프라인을 사용하려면:

- 프로젝트의 `.gitlab-ci.yml` 파일에 `CI_PIPELINE_SOURCE == "merge_request_event"`과 일치하는 작업 규칙 또는 워크플로 규칙이 포함되어야 합니다.
- 머지 리퀘스트 파이프라인을 실행하려면 소스 브랜치 프로젝트에 대해 개발자, 유지보수자 또는 소유자 역할이 있어야 합니다.
- 리포지토리는 GitLab 리포지토리이어야 하며, [외부 리포지토리](../ci_cd_for_external_repos/_index.md)가 아니어야 합니다.

## 머지 리퀘스트 파이프라인 구성 {#configure-merge-request-pipelines}

머지 리퀘스트 파이프라인을 구성하려면 `.gitlab-ci.yml` 파일의 작업을 `CI_PIPELINE_SOURCE`이 `merge_request_event`과 같을 때 실행되도록 구성해야 합니다.

> [!note]
> `include:`에 정의된 규칙(예: `include:component` 포함)은 이 요구 사항을 충족하지 않습니다. `rules:` 또는 `workflow: rules` 일치를 `.gitlab-ci.yml`에 직접 정의해야 합니다.

`rules`을 사용하여 개별 작업을 구성하거나 `workflow: rules`을 사용하여 전체 파이프라인을 제어할 수 있습니다.

### 개별 작업 구성 {#configure-individual-jobs}

[`rules`](../yaml/_index.md#rules) 키워드를 사용하여 개별 작업을 머지 리퀘스트 파이프라인에서 실행되도록 구성합니다. 예를 들어:

```yaml
job1:
  script:
    - echo "This job runs in merge request pipelines"
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

작업이 파일 변경에 따라 실행되는 시기를 제어할 수도 있습니다:

```yaml
test:
  script:
    - echo "This job always runs in merge request pipelines"
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"

lint:
  script:
    - echo "This job runs only when JavaScript files change"
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      changes:
        - "*.js"
```

### 전체 파이프라인 구성 {#configure-the-entire-pipeline}

[`workflow: rules`](../yaml/_index.md#workflowrules) 키워드를 사용하여 파이프라인의 모든 작업을 머지 리퀘스트 파이프라인에서 실행되도록 구성합니다. 예를 들어:

```yaml
workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"

job1:
  script:
    - echo "This job runs in merge request pipelines"
```

자세한 `workflow` 예제를 보려면:

- [브랜치 파이프라인과 머지 리퀘스트 파이프라인 간 전환](../yaml/workflow.md#switch-between-branch-pipelines-and-merge-request-pipelines)
- [머지 리퀘스트 파이프라인을 사용한 Git Flow](../yaml/workflow.md#git-flow-with-merge-request-pipelines)

머지 리퀘스트 파이프라인에서 [보안 스캔 도구를 사용](../../user/application_security/detect/security_configuration.md#use-security-scanning-tools-with-merge-request-pipelines)하려면 CI/CD 변수 `AST_ENABLE_MR_PIPELINES` 또는 `latest` 템플릿 버전을 사용합니다.

## 사용자 정의 입력으로 머지 리퀘스트 파이프라인 실행 {#run-a-merge-request-pipeline-with-custom-inputs}

{{< history >}}

- GitLab 18.11에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/547861).

{{< /history >}}

`.gitlab-ci.yml`이 [파이프라인 입력](../inputs/_index.md)을 정의하면 새 머지 리퀘스트 파이프라인을 수동으로 실행할 때 입력값을 사용자 정의할 수 있습니다. 동일한 양식에서 [CI/CD 변수](../variables/_index.md)도 설정할 수 있습니다.

전제 조건:

- `.gitlab-ci.yml` 파일이 [머지 리퀘스트 파이프라인용으로 구성](#configure-merge-request-pipelines)되어야 합니다.
- `.gitlab-ci.yml` 파일이 `spec: inputs` 섹션도 정의해야 합니다.
- 소스 브랜치 프로젝트에 대해 최소한 개발자 역할이 있어야 합니다.

사용자 정의 입력으로 머지 리퀘스트 파이프라인을 실행하려면:

1. 왼쪽 사이드바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. **코드** > **머지 리퀘스트**를 선택하고 머지 리퀘스트를 엽니다.
1. **파이프라인** 탭을 선택합니다.
1. **파이프라인 실행** 드롭다운 목록({{< icon name="chevron-down" >}})을 선택하고 **수정된 값으로 파이프라인 실행**을 선택합니다.
1. 새 파이프라인 양식이 열리고 머지 리퀘스트의 소스 브랜치로 미리 채워집니다. 입력값을 수정하고 필요에 따라 CI/CD 변수를 설정합니다.
1. **파이프라인 실행**을 선택합니다.

## 포크 프로젝트로 사용 {#use-with-forked-projects}

포크에서 작업하는 외부 기여자는 상위 프로젝트에서 파이프라인을 만들 수 없습니다.

상위 프로젝트에 제출된 포크의 머지 리퀘스트는 다음을 수행하는 파이프라인을 트리거합니다:

- 상위(대상) 프로젝트가 아닌 포크(소스) 프로젝트에서 생성 및 실행됩니다.
- 포크 프로젝트의 CI/CD 구성, 리소스 및 프로젝트 CI/CD 변수를 사용합니다.

포크의 파이프라인은 상위 프로젝트에 **포크** 배지로 표시됩니다.

### 상위 프로젝트에서 파이프라인 실행 {#run-pipelines-in-the-parent-project}

상위 프로젝트의 프로젝트 멤버는 포크 프로젝트에서 제출된 머지 리퀘스트에 대해 머지 리퀘스트 파이프라인을 트리거할 수 있습니다. 이 파이프라인:

- 포크(소스) 프로젝트가 아닌 상위(대상) 프로젝트에서 생성 및 실행됩니다.
- 포크 프로젝트의 브랜치에 있는 CI/CD 구성을 사용합니다.
- 상위 프로젝트의 CI/CD 설정, 리소스 및 프로젝트 CI/CD 변수를 사용합니다.
- 파이프라인을 트리거하는 상위 프로젝트 멤버의 권한을 사용합니다.

포크 프로젝트 MR에서 파이프라인을 실행하여 상위 프로젝트에서 병합 후 파이프라인이 통과하는지 확인합니다. 또한 포크 프로젝트의 러너를 신뢰하지 않는 경우 상위 프로젝트에서 파이프라인을 실행하면 상위 프로젝트의 신뢰할 수 있는 러너를 사용합니다.

> [!warning]
> 포크 머지 리퀘스트에는 병합 전에도 파이프라인이 실행될 때 상위 프로젝트의 보안 정보를 탈취하려는 악의적인 코드가 포함될 수 있습니다. 검토자로서 파이프라인을 트리거하기 전에 머지 리퀘스트의 변경 사항을 신중하게 확인합니다. API 또는 [`/rebase` 빠른 작업](../../user/project/quick_actions.md#rebase)을 통해 파이프라인을 트리거하지 않으면 GitLab은 파이프라인이 실행되기 전에 수락해야 하는 경고를 표시합니다. 그렇지 않으면 **no warning displays**.

전제 조건:

- 상위 프로젝트의 `.gitlab-ci.yml` 파일이 [머지 리퀘스트 파이프라인에서 작업 실행](#prerequisites)하도록 구성되어야 합니다.
- 상위 프로젝트의 멤버이면서 [CI/CD 파이프라인 실행 권한](../../user/permissions.md#project-cicd)이 있어야 합니다. 브랜치가 보호되면 추가 권한이 필요할 수 있습니다.
- 포크 프로젝트는 파이프라인을 실행하는 사용자에게 [표시](../../user/public_access.md)되어야 합니다. 그렇지 않으면 **파이프라인** 탭이 머지 리퀘스트에 표시되지 않습니다.

포크 프로젝트의 머지 리퀘스트에 대해 상위 프로젝트에서 파이프라인을 실행하기 위해 UI를 사용하려면:

1. 머지 리퀘스트에서 **파이프라인** 탭으로 이동합니다.
1. **파이프라인 실행**을 선택합니다. 경고를 읽고 수락하거나 파이프라인이 실행되지 않습니다.

### 포크 프로젝트의 파이프라인 방지 {#prevent-pipelines-from-fork-projects}

사용자가 상위 프로젝트의 포크 프로젝트에 대해 새 파이프라인을 실행하지 못하도록 방지하려면 [프로젝트 API](../../api/projects.md#update-a-project)를 사용하여 `ci_allow_fork_pipelines_to_run_in_parent_project` 설정을 비활성화합니다.

> [!warning]
> 설정이 비활성화되기 전에 생성된 파이프라인은 영향을 받지 않으며 계속 실행됩니다. 이전 파이프라인에서 작업을 다시 실행하면 작업이 파이프라인이 원래 생성되었을 때와 동일한 컨텍스트를 사용합니다.

## 사용 가능한 사전 정의된 변수 {#available-predefined-variables}

머지 리퀘스트 파이프라인을 사용할 때 다음을 사용할 수 있습니다:

- 브랜치 파이프라인에서 사용 가능한 모든 동일한 [사전 정의된 변수](../variables/predefined_variables.md).
- 머지 리퀘스트 파이프라인의 작업에만 사용 가능한 [추가 사전 정의된 변수](../variables/predefined_variables.md#predefined-variables-for-merge-request-pipelines).

## 보호된 변수와 러너에 대한 액세스 제어 {#control-access-to-protected-variables-and-runners}

{{< history >}}

- GitLab 18.1에서 [소개됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/188008)

{{< /history >}}

머지 리퀘스트 파이프라인에서 [보호된 CI/CD 변수](../variables/_index.md#protect-a-cicd-variable) 및 [보호되는 러너](../runners/configure_runners.md#prevent-runners-from-revealing-sensitive-information)에 대한 액세스를 제어할 수 있습니다.

머지 리퀘스트 파이프라인은 다음의 경우에만 이러한 보호된 리소스에 액세스할 수 있습니다:

- 소스 브랜치와 대상 브랜치 모두 [보호](../../user/project/repository/branches/protected.md)되어 있습니다.
- 파이프라인을 트리거하는 사용자는 대상 브랜치에 대한 푸시/병합 액세스 권한이 있습니다.
- 소스 브랜치 및 대상 브랜치 모두 동일한 프로젝트에 속합니다.

포크 리포지토리의 머지 리퀘스트 파이프라인은 이러한 보호된 리소스에 액세스할 수 없습니다.

전제 조건:

- 프로젝트에서 유지보수자 또는 소유자 역할을 가집니다.

보호된 변수와 러너에 대한 액세스를 제어하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **변수**를 확장합니다.
1. **머지 리퀘스트 파이프라인에서 보호된 리소스에 액세스** 아래에서 **머지 리퀘스트 파이프라인이 보호된 변수와 러너에 액세스하도록 허용** 확인란을 선택하거나 선택 해제합니다.
