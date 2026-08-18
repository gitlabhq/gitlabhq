---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: CI/CD 파이프라인
description: "구성, 자동화, 스테이지, 일정 및 효율성."
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

CI/CD 파이프라인은 GitLab CI/CD의 기본 구성 요소입니다. `.gitlab-ci.yml` 파일에서 [YAML 키워드](../yaml/_index.md)를 사용하여 파이프라인을 구성합니다.

파이프라인은 브랜치에 푸시하거나 머지 리퀘스트를 생성하거나 일정에 따라 특정 이벤트에 대해 자동으로 실행할 수 있습니다. 필요한 경우 파이프라인을 수동으로 실행할 수도 있습니다.

파이프라인은 다음으로 구성됩니다:

- [전역 YAML 키워드](../yaml/_index.md#global-keywords)는 프로젝트의 파이프라인 동작을 제어합니다.
- [작업](../jobs/_index.md)은 작업을 완료하기 위해 명령을 실행합니다. 예를 들어, 작업은 코드를 컴파일, 테스트 또는 배포할 수 있습니다. 작업은 서로 독립적으로 실행되며 [러너](../runners/_index.md)에서 실행됩니다.
- 스테이지는 작업을 함께 그룹화하는 방법을 정의합니다. 스테이지는 순차적으로 실행되며, 스테이지 내의 작업은 병렬로 실행됩니다. 예를 들어, 초기 스테이지는 코드를 린팅하고 컴파일하는 작업을 포함할 수 있으며, 이후 스테이지는 코드를 테스트하고 배포하는 작업을 포함할 수 있습니다. 스테이지의 모든 작업이 성공하면 파이프라인이 다음 스테이지로 이동합니다. 스테이지의 작업이 실패하면 다음 스테이지는 (보통) 실행되지 않고 파이프라인이 조기에 종료됩니다.

작은 파이프라인은 다음 순서로 실행되는 3개의 스테이지로 구성될 수 있습니다:

- `build` 스테이지이며, `compile`라는 작업이 있어서 프로젝트의 코드를 컴파일합니다.
- `test` 스테이지이며, `test1`와 `test2`라는 두 작업이 있어서 코드에서 다양한 테스트를 실행합니다. 이러한 테스트는 `compile` 작업이 성공적으로 완료된 경우에만 실행됩니다.
- `deploy` 스테이지이며, `deploy-to-production`라는 작업이 있습니다. 이 작업은 `test` 스테이지의 두 작업이 시작되고 성공적으로 완료된 경우에만 실행됩니다.

첫 파이프라인을 시작하려면 [첫 GitLab CI/CD 파이프라인 생성 및 실행](../quick_start/_index.md)을 참조하세요.

## 파이프라인 유형 {#types-of-pipelines}

파이프라인은 다양한 방식으로 구성할 수 있습니다:

- [기본 파이프라인](pipeline_architectures.md#basic-pipelines)은 각 스테이지에서 모든 것을 동시에 실행한 후 다음 스테이지로 진행합니다.
- [`needs` 키워드를 사용하는 파이프라인](../yaml/needs.md)은 작업 간의 의존성을 기반으로 실행되며 기본 파이프라인보다 더 빠르게 실행할 수 있습니다.
- [머지 리퀘스트 파이프라인](merge_request_pipelines.md)은 모든 커밋이 아닌 머지 리퀘스트에 대해서만 실행됩니다.
- [병합된 결과 파이프라인](merged_results_pipelines.md)은 소스 브랜치의 변경 사항이 대상 브랜치에 이미 병합된 것처럼 작동하는 머지 리퀘스트 파이프라인입니다.
- [머지 트레인](merge_trains.md)은 병합된 결과 파이프라인을 사용하여 병합을 차례대로 큐에 넣습니다.
- [워크로드 파이프라인](pipeline_types.md#workload-pipeline)은 임시 브랜치를 생성하지 않고 온디맨드 파이프라인 실행을 위해 임시 Git 참조에서 실행됩니다.
- [상위-하위 파이프라인](downstream_pipelines.md#parent-child-pipelines)은 복잡한 파이프라인을 하나의 상위 파이프라인으로 분해하여 동일한 프로젝트 및 동일한 SHA에서 실행되는 여러 하위 파이프라인을 트리거할 수 있습니다. 이 파이프라인 아키텍처는 일반적으로 모노레포에 사용됩니다.
- [다중 프로젝트 파이프라인](downstream_pipelines.md#multi-project-pipelines)은 여러 프로젝트의 파이프라인을 함께 결합합니다.

## 파이프라인 구성 {#configure-a-pipeline}

파이프라인 및 구성 요소 작업과 스테이지는 각 프로젝트의 CI/CD 파이프라인 구성 파일에서 [YAML 키워드](../yaml/_index.md)로 정의됩니다. GitLab에서 CI/CD 구성을 편집할 때는 [파이프라인 편집기](../pipeline_editor/_index.md)를 사용해야 합니다.

GitLab UI를 통해 파이프라인의 특정 측면을 구성할 수도 있습니다:

- 각 프로젝트의 [파이프라인 설정](settings.md).
- [파이프라인 일정](schedules.md).
- [사용자 정의 CI/CD 변수](../variables/_index.md#for-a-project).

GitLab CI/CD 구성을 편집하기 위해 VS Code를 사용하는 경우, [GitLab for VS Code 확장 프로그램](../../editor_extensions/visual_studio_code/_index.md)은 [구성 유효성 검사](../../editor_extensions/visual_studio_code/cicd.md#test-gitlab-cicd-configuration)와 [파이프라인 상태 보기](../../editor_extensions/visual_studio_code/cicd.md#monitor-and-manage-pipelines)를 지원합니다.

### 파이프라인을 수동으로 실행 {#run-a-pipeline-manually}

{{< history >}}

- **파이프라인 실행** 이름이 GitLab 17.7에서 **새 파이프라인**으로 [변경](https://gitlab.com/gitlab-org/gitlab/-/issues/482718)되었습니다.
- **입력** 옵션이 GitLab 17.11에서 [플래그](../../administration/feature_flags/_index.md) `ci_inputs_for_pipelines`와 함께 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/525504)되었습니다. 기본적으로 활성화됩니다.
- **입력** 옵션이 GitLab 18.1에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/536548)해졌습니다. 기능 플래그 `ci_inputs_for_pipelines`이 제거되었습니다.

{{< /history >}}

파이프라인은 사전 정의되거나 수동으로 지정된 [변수](../variables/_index.md)로 수동으로 실행할 수 있습니다.

파이프라인의 결과(예: 코드 빌드)가 파이프라인의 표준 작동 외부에서 필요한 경우 이 작업을 수행할 수 있습니다.

파이프라인을 수동으로 실행하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **파이프라인**을 선택합니다.
1. **새 파이프라인**을 선택합니다.
1. **브랜치 이름 또는 태그에 대해 실행** 필드에서 파이프라인을 실행할 브랜치 또는 태그를 선택합니다.
1. 선택 사항. 다음 중 하나를 입력합니다:
   - 파이프라인을 실행하는 데 필요한 [입력](../inputs/_index.md). 입력의 기본값이 미리 채워져 있지만 수정할 수 있습니다. 입력값은 예상되는 유형을 따라야 합니다.
   - [CI/CD 변수](../variables/_index.md). [폼에서 값을 미리 채우도록](#prefill-variables-in-manual-pipelines) 변수를 구성할 수 있습니다. 입력을 사용하여 파이프라인 동작을 제어하면 CI/CD 변수보다 향상된 보안 및 유연성을 제공합니다.
1. **새 파이프라인**을 선택합니다.

파이프라인이 구성에 따라 작업을 실행합니다.

#### 수동 파이프라인 변수 보기 {#view-manual-pipeline-variables}

{{< history >}}

- GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/323097)되었으며, [플래그](../../administration/feature_flags/_index.md) `ci_show_manual_variables_in_pipeline`와 함께 제공되었습니다. 기본적으로 비활성화되어 있습니다.
- GitLab 18.4에서 프로젝트 설정과 함께 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/505440)합니다. 기능 플래그 `ci_show_manual_variables_in_pipeline`이 제거되었습니다.

{{< /history >}}

파이프라인이 수동으로 실행될 때 지정된 모든 변수를 볼 수 있습니다.

전제 조건:

- 프로젝트에 대해 Owner 역할이 필요합니다.

필요한 역할은 수행하려는 작업에 따라 다릅니다:

| 작업 | 최소 역할 |
|--------|-------------|
| 변수 이름 보기 | 게스트 |
| 변수 값 보기 | 개발자 |
| 표시 설정 구성 | 소유자 |

> [!warning]
> 이 설정을 켜면 개발자 역할을 가진 사용자는 수동 파이프라인 실행의 민감한 정보를 포함할 수 있는 변수 값을 볼 수 있습니다. 자격 증명이나 토큰과 같은 민감한 데이터의 경우 수동 파이프라인 변수 대신 [보호된 변수](../variables/_index.md#protect-a-cicd-variable) 또는 [외부 시크릿 관리](../secrets/_index.md)를 사용하세요.

수동 파이프라인 변수를 보려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **파이프라인 변수 표시**를 선택합니다.
1. **빌드** > **파이프라인**으로 이동하고 수동으로 실행된 파이프라인을 선택합니다.
1. **메뉴얼 변수** 탭을 선택합니다.

변수 값은 기본적으로 마스킹됩니다. 개발자, 유지 관리자 또는 소유자 역할이 있는 경우 눈 아이콘을 선택하여 값을 표시할 수 있습니다.

#### 수동 파이프라인에서 변수 미리 채우기 {#prefill-variables-in-manual-pipelines}

{{< history >}}

- **파이프라인 실행** 페이지의 마크다운 렌더링이 GitLab 17.11에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/441474)되었습니다.

{{< /history >}}

[`description` 및 `value`](../yaml/_index.md#variablesdescription) 키워드를 사용하여 [파이프라인 수준(전역) 변수를 정의](../variables/_index.md#define-a-cicd-variable-in-the-gitlab-ciyml-file)할 수 있으며, 이는 파이프라인을 수동으로 실행할 때 미리 채워집니다. 설명을 사용하여 변수를 사용하는 목적 및 허용되는 값과 같은 정보를 설명합니다. 설명에서 마크다운을 사용할 수 있습니다.

작업 수준 변수는 미리 채울 수 없습니다.

수동으로 트리거된 파이프라인에서 **새 파이프라인** 페이지는 `.gitlab-ci.yml` 파일에 `description`가 정의된 모든 파이프라인 수준 변수를 표시합니다. 설명은 변수 아래에 표시됩니다.

미리 채운 값을 변경할 수 있으며, [이는 값을 재정의](../variables/_index.md#use-pipeline-variables)하므로 단일 파이프라인 실행에만 적용됩니다. 이 프로세스를 사용하여 재정의된 모든 변수는 [확장](../variables/_index.md#allow-cicd-variable-expansion)되며 [마스킹](../variables/_index.md#mask-a-cicd-variable)되지 않습니다. 구성 파일에 변수에 대해 `value`를 정의하지 않으면 변수 이름은 여전히 나열되지만 값 필드는 공백입니다.

예를 들어:

```yaml
variables:
  DEPLOY_CREDENTIALS:
    description: "The deployment credentials."
  DEPLOY_ENVIRONMENT:
    description: "Select the deployment target. Valid options are: 'canary', 'staging', 'production', or a stable branch of your choice."
    value: "canary"
```

이 예에서:

- `DEPLOY_CREDENTIALS`은 **새 파이프라인** 페이지에 나열되어 있지만 값이 설정되지 않습니다. 사용자는 파이프라인을 수동으로 실행할 때마다 값을 정의해야 합니다.
- `DEPLOY_ENVIRONMENT`은 **새 파이프라인** 페이지에서 `canary`을(를) 기본값으로 미리 채우고, 메시지는 다른 옵션을 설명합니다.

> [!note]
> [알려진 문제](https://gitlab.com/gitlab-org/gitlab/-/issues/382857) 때문에 [규정 준수 파이프라인](../../user/compliance/compliance_pipelines.md)을 사용하는 프로젝트는 파이프라인을 수동으로 실행할 때 미리 채운 변수가 나타나지 않을 수 있습니다. 이 문제를 해결하려면 [규정 준수 파이프라인 구성을 변경](../../user/compliance/compliance_pipelines.md#prefilled-variables-are-not-shown)하세요.

#### 선택 가능한 미리 채운 변수 값의 목록 구성 {#configure-a-list-of-selectable-prefilled-variable-values}

파이프라인을 수동으로 실행할 때 사용자가 선택할 수 있는 CI/CD 변수 값의 배열을 정의할 수 있습니다. 이러한 값은 **새 파이프라인** 페이지의 드롭다운 목록에 있습니다. 값 옵션 목록을 `options`에 추가하고 `value`로 기본값을 설정합니다. `value`의 문자열도 `options` 목록에 포함되어야 합니다.

예를 들어:

```yaml
variables:
  DEPLOY_ENVIRONMENT:
    value: "staging"
    options:
      - "production"
      - "staging"
      - "canary"
    description: "The deployment target. Set to 'staging' by default."
```

### URL 쿼리 문자열을 사용하여 파이프라인을 실행 {#run-a-pipeline-by-using-a-url-query-string}

쿼리 문자열을 사용하여 **새 파이프라인** 페이지를 미리 채울 수 있습니다. 예를 들어 쿼리 문자열 `.../pipelines/new?ref=my_branch&var[foo]=bar&file_var[file_foo]=file_bar`은(는) **새 파이프라인** 페이지를 다음으로 미리 채웁니다:

- **Run for** 필드: `my_branch`.
- **변수** 섹션:
  - 변수:
    - 키: `foo`
    - 값: `bar`
  - 파일:
    - 키: `file_foo`
    - 값: `file_bar`

`pipelines/new` URL의 형식:

```plaintext
.../pipelines/new?ref=<branch>&var[<variable_key>]=<value>&file_var[<file_key>]=<value>
```

지원되는 매개 변수는 다음과 같습니다:

- `ref`: **Run for** 필드를 채울 브랜치를 지정합니다.
- `var`: `Variable` 변수를 지정합니다.
- `file_var`: `File` 변수를 지정합니다.

각 `var` 또는 `file_var`에 대해 키와 값이 필요합니다.

### 파이프라인에 수동 상호 작용 추가 {#add-manual-interaction-to-your-pipeline}

[수동 작업](../jobs/job_control.md#create-a-job-that-must-be-run-manually)은 파이프라인을 계속 진행하기 전에 수동 상호 작용을 요구할 수 있습니다.

파이프라인 그래프에서 직접 이 작업을 수행할 수 있습니다. 특정 작업을 실행하려면 **실행** ({{< icon name="play" >}})을 선택합니다.

예를 들어, 파이프라인은 자동으로 시작되지만 [프로덕션에 배포](../environments/deployments.md#configure-manual-deployments)하기 위해 수동 작업이 필요할 수 있습니다. 다음 예에서 `production` 스테이지는 수동 작업을 포함하는 작업을 가집니다:

![4개의 스테이지 (빌드, 테스트, 카나리 및 프로덕션)를 보여주는 파이프라인 그래프입니다. 처음 3개 스테이지는 녹색 체크 표시가 있는 완료된 작업을 보여주고, 프로덕션 스테이지는 대기 중인 배포 작업을 보여줍니다.](img/manual_job_v17_9.png)

#### 스테이지에서 모든 수동 작업 시작 {#start-all-manual-jobs-in-a-stage}

스테이지에 수동 작업만 포함되어 있으면 **모두 수동 실행** ({{< icon name="play" >}})을 선택하여 모든 작업을 동시에 시작할 수 있습니다. 스테이지에 수동이 아닌 작업이 포함되어 있으면 옵션이 표시되지 않습니다.

### 파이프라인 스킵 {#skip-a-pipeline}

파이프라인을 트리거하지 않고 커밋을 푸시하려면 `[ci skip]` 또는 `[skip ci]`을(를) 추가합니다. 대소문자는 관계없으며 커밋 메시지에 추가됩니다.

또는 Git 2.10 이상에서는 `ci.skip` [Git 푸시 옵션](../../topics/git/commit.md#push-options-for-gitlab-cicd)을(를) 사용합니다. `ci.skip` 푸시 옵션은 머지 리퀘스트 파이프라인을 스킵하지 않습니다.

파이프라인을 스킵할 때:

- 작업 또는 스테이지가 없는 빈 파이프라인이 여전히 GitLab에서 생성됩니다. 파이프라인은 UI에 표시되며 API 응답에서 반환될 수 있습니다.
- 파이프라인 상태는 UI에서 **생략**이고 API에서 `skipped`입니다.

> [!note]
> 파이프라인 실행 정책 및 스캔 실행 정책은 `[skip ci]` 지시문을 제한하거나 비활성화할 수 있습니다. 자세한 정보는 다음을 참조하세요.
>
> - 파이프라인 실행 정책의 [`skip_ci` 유형](../../user/application_security/policies/pipeline_execution_policies.md#skip_ci-type).
> - 스캔 실행 정책의 [`skip_ci` 유형](../../user/application_security/policies/scan_execution_policies.md#skip_ci-type).

### 파이프라인 삭제 {#delete-a-pipeline}

프로젝트의 소유자 역할을 가진 사용자는 파이프라인을 삭제할 수 있습니다:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **파이프라인**을 선택합니다.
1. 삭제할 파이프라인의 파이프라인 ID (예: `#123456789`) 또는 파이프라인 상태 아이콘 (예: **통과됨**)을 선택합니다.
1. 파이프라인 세부 정보 페이지의 오른쪽 위에서 **삭제**를 선택합니다.

파이프라인 삭제는 [하위 파이프라인](downstream_pipelines.md#parent-child-pipelines)을 자동으로 삭제하지 않습니다. 자세한 내용은 [문제 39503](https://gitlab.com/gitlab-org/gitlab/-/issues/39503)을 참조하세요.

> [!warning]
> 파이프라인 삭제는 모든 파이프라인 캐시를 만료하고 작업, 로그, 아티팩트 및 트리거와 같은 모든 직접 관련된 객체를 삭제합니다. **This action cannot be undone**.

### 보호된 브랜치의 파이프라인 보안 {#pipeline-security-on-protected-branches}

파이프라인이 [보호된 브랜치](../../user/project/repository/branches/protected.md)에서 실행될 때 엄격한 보안 모델이 적용됩니다.

사용자가 특정 브랜치에 [병합 또는 푸시](../../user/project/repository/branches/protected.md)할 수 있는 경우 보호된 브랜치에서 다음 작업이 허용됩니다:

- 수동 파이프라인 실행([Web UI](#run-a-pipeline-manually) 또는 [파이프라인 API](#pipelines-api) 사용).
- 예약된 파이프라인 실행.
- 트리거 토큰을 사용하여 파이프라인 실행.
- 온디맨드 DAST 스캔 실행.
- 기존 파이프라인에서 수동 작업 실행.
- 기존 작업 재시도 또는 취소 (Web UI 또는 파이프라인 API 사용).

**변수**로 표시된 **보호됨** 항목은 보호된 브랜치의 파이프라인에서 실행되는 작업에 액세스할 수 있습니다. 배포 자격 증명 및 토큰과 같은 민감한 정보에 액세스할 수 있는 권한이 있는 경우에만 보호된 브랜치에 병합할 수 있는 권한을 사용자에게 할당하세요.

**러너**로 표시된 **보호됨** 항목은 보호된 브랜치에서만 작업을 실행할 수 있으며, 신뢰할 수 없는 코드가 보호된 러너에서 실행되는 것을 방지하고 배포 키 및 기타 자격 증명이 의도하지 않게 액세스되는 것을 방지합니다. 보호된 러너에서 실행되도록 의도된 작업이 일반 러너를 사용하지 않도록 하려면 [태그](../yaml/_index.md#tags)를 지정해야 합니다.

보호된 변수 및 러너에 대한 액세스가 [머지 리퀘스트 파이프라인의 컨텍스트](merge_request_pipelines.md#control-access-to-protected-variables-and-runners)에서 어떻게 작동하는지 검토하세요.

파이프라인 보안을 위한 추가 보안 권장 사항은 [배포 보안](../environments/deployment_safety.md) 페이지를 검토하세요.

## 업스트림 프로젝트가 재빌드될 때 파이프라인 트리거 {#trigger-a-pipeline-when-an-upstream-project-is-rebuilt}

{{< details >}}

- 계층: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

다른 프로젝트의 태그를 기반으로 파이프라인을 자동으로 트리거하도록 프로젝트를 설정할 수 있습니다. 구독된 프로젝트의 새 태그 파이프라인이 완료되면 태그 파이프라인의 성공, 실패 또는 취소 여부와 관계없이 프로젝트의 기본 브랜치에 파이프라인을 트리거합니다.

대신 [CI/CD 작업과 파이프라인 트리거 토큰](../triggers/_index.md#use-a-cicd-job)을 사용하여 다른 파이프라인이 실행될 때 파이프라인을 트리거할 수 있습니다. 이 방법은 파이프라인 구독보다 더 안정적이고 유연하며 권장되는 방식입니다.

전제 조건:

- 업스트림 프로젝트는 [공개](../../user/public_access.md)여야 합니다.
- 사용자는 업스트림 프로젝트에서 개발자 역할이 있어야 합니다.

업스트림 프로젝트가 재빌드될 때 파이프라인을 트리거하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **파이프라인 구독**을 확장합니다.
1. **프로젝트 추가**를 선택합니다.
1. `<namespace>/<project>` 형식으로 구독하려는 프로젝트를 입력합니다. 예를 들어 프로젝트가 `https://gitlab.com/gitlab-org/gitlab`인 경우 `gitlab-org/gitlab`을(를) 사용합니다.
1. **구독**을 선택합니다.

기본적으로 업스트림 프로젝트 및 다운스트림 프로젝트 모두에 대한 최대 업스트림 프로젝트 파이프라인 구독 수는 2입니다. GitLab Self-Managed에서 관리자는 이 [제한](../../administration/cicd/limits.md#number-of-cicd-subscriptions-to-a-project)을 변경할 수 있습니다.

## 파이프라인 지속 시간을 계산하는 방법 {#how-pipeline-duration-is-calculated}

주어진 파이프라인의 총 실행 시간은 다음을 제외합니다:

- 재시도되거나 수동으로 다시 실행된 작업의 초기 실행 기간.
- 대기 중 (큐) 시간.

이는 작업을 재시도하거나 수동으로 다시 실행하는 경우 최신 실행의 기간만 총 실행 시간에 포함됨을 의미합니다.

각 작업은 `Period`로 표현되며, 다음으로 구성됩니다:

- `Period#first` (작업이 시작된 시간).
- `Period#last` (작업이 완료된 시간).

간단한 예는 다음과 같습니다:

- A (0, 2)
- A' (2, 4)
  - A 재시도
- B (1, 3)
- C (6, 7)

예에서:

- A는 0에서 시작하고 2에서 끝납니다.
- A'는 2에서 시작하고 4에서 끝납니다.
- B는 1에서 시작하고 3에서 끝납니다.
- C는 6에서 시작하고 7에서 끝납니다.

시각적으로 다음과 같이 볼 수 있습니다:

```plaintext
0  1  2  3  4  5  6  7
AAAAAAA
   BBBBBBB
      A'A'A'A
                  CCCC
```

A는 재시도되므로 무시되고 작업 A'만 계산됩니다. B, A' 및 C의 합집합은 (1, 4)와 (6, 7)입니다. 따라서 총 실행 시간은:

```plaintext
(4 - 1) + (7 - 6) => 4
```

## 파이프라인 보기 {#view-pipelines}

프로젝트에 대해 실행된 모든 파이프라인을 보려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **파이프라인**을 선택합니다.

**파이프라인** 페이지를 다음으로 필터링할 수 있습니다:

- 트리거 작성자
- 브랜치 이름
- 상태
- 태그
- 소스

오른쪽 위의 드롭다운 목록에서 **파이프라인 ID**를 선택하여 파이프라인 ID (인스턴스 전체에서 고유한 ID)를 표시합니다. **pipeline IID**를 선택하여 파이프라인 IID (프로젝트 전체에서만 고유한 내부 ID)를 표시합니다.

특정 머지 리퀘스트와 관련된 파이프라인을 보려면 머지 리퀘스트의 **파이프라인** 탭으로 이동합니다.

### 파이프라인 세부 정보 {#pipeline-details}

파이프라인을 선택하여 파이프라인의 모든 작업을 보여주는 파이프라인 세부 정보 페이지를 엽니다. 이 페이지에서 실행 중인 파이프라인을 취소하거나, 실패한 작업을 다시 시도하거나, [파이프라인을 삭제](#delete-a-pipeline)할 수 있습니다.

파이프라인 세부 정보 페이지는 파이프라인의 모든 작업의 그래프를 표시합니다:

![파이프라인 세부 정보 페이지](img/pipeline_details_v17_9.png)

특정 파이프라인의 세부 정보에 액세스하기 위해 표준 URL을 사용할 수 있습니다:

- `gitlab.example.com/my-group/my-project/-/pipelines/latest`: 프로젝트의 기본 브랜치의 가장 최근 커밋에 대한 최신 파이프라인의 세부 정보 페이지입니다.
- `gitlab.example.com/my-group/my-project/-/pipelines/<branch>/latest`: 프로젝트의 브랜치 `<branch>`의 가장 최근 커밋에 대한 최신 파이프라인의 세부 정보 페이지입니다.

#### 작업을 스테이지 또는 `needs` 구성으로 묶음 {#group-jobs-by-stage-or-needs-configuration}

[`needs`](../yaml/_index.md#needs) 키워드로 작업을 구성할 때 파이프라인 세부 정보 페이지에서 작업을 그룹화하는 방법에 대한 두 가지 옵션이 있습니다. 작업을 스테이지 구성으로 그룹화하려면 **작업을 다음으로 묶음** 섹션에서 **stage**를 선택합니다:

![각 스테이지 아래에 그룹화된 작업을 보여주는 파이프라인 그래프](img/pipeline_stage_view_v17_9.png)

작업을 [`needs`](../yaml/_index.md#needs) 구성으로 그룹화하려면 **작업 의존성**을 선택합니다. 선택적으로 **의존성 표시**를 선택하여 종속 작업 사이에 선을 렌더링합니다.

![작업 의존성으로 그룹화된 작업](img/pipeline_dependency_view_v17_9.png)

맨 왼쪽 열의 작업이 먼저 실행되고, 이에 따라 작업은 다음 열에 그룹화됩니다. 이 예에서:

- `lint-job`은 `needs: []`로 구성되고 작업에 의존하지 않으므로 `test` 스테이지에 있음에도 불구하고 첫 번째 열에 표시됩니다.
- `test-job1`은 `build-job1`에 의존하고, `test-job2`은 `build-job1` 및 `build-job2`에 모두 의존하므로 두 테스트 작업이 두 번째 열에 표시됩니다.
- 두 `deploy` 작업 모두 두 번째 열의 작업에 의존하므로 (이는 다른 초기 작업에 의존함), 배포 작업이 세 번째 열에 표시됩니다.

**작업 의존성** 보기에서 작업을 가리킬 때 선택한 작업을 실행하기 전에 실행해야 하는 모든 작업이 강조 표시됩니다:

![마우스를 가리킬 때 파이프라인 의존성 보기](img/pipeline_dependency_view_on_hover_v17_9.png)

### 파이프라인 미니 그래프 {#pipeline-mini-graphs}

파이프라인 미니 그래프는 공간이 적게 필요하며 모든 작업이 통과했는지 아니면 무언가 실패했는지 한눈에 알 수 있습니다. 단일 커밋에 대한 모든 관련 작업과 파이프라인의 각 스테이지 결과를 표시합니다. 실패한 것을 빠르게 확인하고 수정할 수 있습니다.

파이프라인 미니 그래프는 항상 작업을 스테이지별로 그룹화하며 파이프라인 또는 커밋 세부 정보를 표시할 때 GitLab 전체에 표시됩니다.

![파이프라인 미니 그래프](img/pipeline_mini_graph_v16_11.png)

파이프라인 미니 그래프의 스테이지는 확장 가능합니다. 각 스테이지 위에 마우스를 가져가 이름과 상태를 확인하고 스테이지를 선택하여 작업 목록을 확장합니다.

### 다운스트림 파이프라인 그래프 {#downstream-pipeline-graphs}

파이프라인이 [다운스트림 파이프라인](downstream_pipelines.md)을 트리거하는 작업을 포함하면 파이프라인 세부 정보 보기 및 미니 그래프에서 다운스트림 파이프라인을 볼 수 있습니다.

파이프라인 세부 정보 보기에서 트리거된 각 다운스트림 파이프라인에 대한 카드가 파이프라인 그래프의 오른쪽에 표시됩니다. 카드를 가리켜 어느 작업이 다운스트림 파이프라인을 트리거했는지 확인합니다. 카드를 선택하여 파이프라인 그래프의 오른쪽에 다운스트림 파이프라인을 표시합니다.

파이프라인 미니 그래프에서 트리거된 각 다운스트림 파이프라인의 상태가 미니 그래프의 오른쪽에 추가 상태 아이콘으로 표시됩니다. 다운스트림 파이프라인 상태 아이콘을 선택하여 해당 다운스트림 파이프라인의 세부 정보 페이지로 이동합니다.

## 파이프라인 성공 및 지속 시간 차트 {#pipeline-success-and-duration-charts}

파이프라인 분석은 [**CI/CD 분석** 페이지](../../user/analytics/ci_cd_analytics.md)에서 사용할 수 있습니다.

## 파이프라인 배지 {#pipeline-badges}

파이프라인 상태 및 테스트 적용 범위 보고서 배지는 각 프로젝트에 대해 사용 가능하며 구성할 수 있습니다. 파이프라인 배지를 프로젝트에 추가하는 방법에 대한 자세한 내용은 [파이프라인 배지](settings.md#pipeline-badges)를 참조하세요.

## 파이프라인 API {#pipelines-api}

GitLab은 다음을 수행하기 위한 API 끝점을 제공합니다:

- 기본 기능을 수행합니다. 자세한 내용은 [파이프라인 API](../../api/pipelines.md)를 참조하세요.
- 파이프라인 일정을 유지합니다. 자세한 내용은 [파이프라인 일정 API](../../api/pipeline_schedules.md)를 참조하세요.
- 파이프라인 실행을 트리거합니다. 자세한 정보는 다음을 참조하세요.
  - [API를 통한 파이프라인 트리거](../triggers/_index.md).
  - [파이프라인 트리거 토큰 API](../../api/pipeline_triggers.md).

## 러너의 Ref 사양 {#ref-specs-for-runners}

러너가 파이프라인 작업을 선택하면 GitLab은 해당 작업의 메타데이터를 제공합니다. 여기에는 [Git refspec](https://git-scm.com/book/en/v2/Git-Internals-The-Refspec)이 포함되며, 프로젝트 저장소에서 체크아웃된 ref (브랜치 또는 태그 등) 및 커밋 (SHA1)을 나타냅니다.

이 테이블은 각 파이프라인 유형에 대해 주입된 refspec을 나열합니다:

| 파이프라인 유형                                        | Refspec |
|------------------------------------------------------|----------|
| 브랜치에 대한 파이프라인                                | `+<sha>:refs/pipelines/<id>` 및 `+refs/heads/<name>:refs/remotes/origin/<name>` |
| 태그에 대한 파이프라인                                    | `+<sha>:refs/pipelines/<id>` 및 `+refs/tags/<name>:refs/tags/<name>` |
| [머지 리퀘스트 파이프라인](merge_request_pipelines.md) | `+refs/pipelines/<id>:refs/pipelines/<id>` |
| [워크로드 ref에 대한 파이프라인](pipeline_types.md#workload-pipeline)  | `+refs/pipelines/<id>:refs/pipelines/<id>` |

ref `refs/heads/<name>` 및 `refs/tags/<name>`은 프로젝트 저장소에 존재합니다. GitLab은 실행 중인 파이프라인 작업 중에 특수 ref `refs/pipelines/<id>`을 생성합니다. 이 ref는 연결된 브랜치 또는 태그가 삭제된 후에도 생성될 수 있습니다. 따라서 [환경 자동 중지](../environments/_index.md#stopping-an-environment) 및 브랜치 삭제 후 파이프라인을 실행할 수 있는 [머지 트레인](merge_trains.md)과 같은 일부 기능에서 유용합니다.

## 문제 해결 {#troubleshooting}

### 사용자 삭제 후 파이프라인 구독 계속 {#pipeline-subscriptions-continue-after-user-deletion}

사용자가 [GitLab.com 계정 삭제](../../user/profile/account/delete_account.md#delete-your-own-account)할 때 삭제는 7일 동안 발생하지 않습니다. 이 기간 동안 해당 사용자가 생성한 모든 파이프라인 구독은 사용자의 원래 권한으로 계속 실행됩니다. 승인되지 않은 파이프라인 실행을 방지하려면 삭제된 사용자의 파이프라인 구독 설정을 즉시 업데이트하세요.

### 미리 채운 변수가 **New Pipeline** 페이지에 나타나지 않음 {#pre-filled-variables-do-not-show-up-in-new-pipeline-page}

파이프라인에 대한 미리 정의된 변수가 [별도 파일에 정의](../yaml/includes.md)된 경우 **New Pipeline** 페이지에 표시되지 않을 수 있습니다. 별도 파일에 액세스할 수 있는 권한이 있어야 합니다. 그렇지 않으면 미리 정의된 변수를 표시할 수 없습니다.
