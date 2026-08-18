---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "GitLab에서 머지 리퀘스트 승인 정책을 사용하여 보안 규칙을 적용하고 검사, 승인 및 규정 준수를 자동화하는 방법을 알아봅니다."
title: 머지 리퀘스트 승인 정책
---

{{< details >}}

- 계층: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- 그룹 수준 검사 결과 정책이 GitLab 15.6에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/7622)되었습니다.
- 검사 결과 정책 기능의 이름이 GitLab 16.9에서 머지 리퀘스트 승인 정책으로 변경되었습니다.

{{< /history >}}

> [!note]
> 검사 결과 정책 기능의 이름이 GitLab 16.9에서 머지 리퀘스트 승인 정책으로 변경되었습니다.

머지 리퀘스트 승인 정책을 다음을 포함한 여러 목적으로 사용할 수 있습니다:

- 승인 규칙을 적용하기 위해 보안 및 라이선스 스캐너의 결과를 검색합니다. 예를 들어, 머지 리퀘스트 정책의 한 가지 유형은 하나 이상의 보안 검사 작업 결과에 따라 승인이 필요하도록 허용하는 보안 승인 정책입니다. 머지 리퀘스트 승인 정책은 CI 검사 작업이 완전히 실행된 후 평가되며, 취약성 및 라이선스 유형 정책 모두 완료된 파이프라인에 발행되는 작업 아티팩트 보고서를 기반으로 평가됩니다.
- 특정 조건을 충족하는 모든 머지 리퀘스트에 승인 규칙을 적용합니다. 예를 들어, 기본 브랜치를 대상으로 하는 모든 머지 리퀘스트에 대해 Developer 및 Maintainer 역할을 가진 여러 사용자가 머지 리퀘스트를 검토하도록 적용합니다.
- 프로젝트에 보안 및 규정 준수 설정을 적용합니다. 예를 들어, 머지 리퀘스트를 작성하거나 커밋한 사용자가 머지 리퀘스트를 승인하지 못하도록 방지합니다. 또는 사용자가 기본 브랜치로 푸시하거나 강제 푸시하지 못하도록 방지하여 모든 변경 사항이 머지 리퀘스트를 통해 진행되도록 합니다.

> [!note]
> 보호된 브랜치가 생성되거나 삭제되면 정책 승인 규칙이 1분 지연과 함께 동기화됩니다.

다음 동영상은 GitLab 머지 리퀘스트 승인 정책(이전의 검사 결과 정책)에 대한 개요를 제공합니다:

<div class="video-fallback">
  비디오 보기:  <a href="https://youtu.be/w5I9gcUgr9U">GitLab 검사 결과 정책 개요</a>
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/w5I9gcUgr9U" frameborder="0" allowfullscreen> </iframe>
</figure>

## 제한 사항 {#restrictions}

- 머지 리퀘스트 승인 정책은 [보호된](../../project/repository/branches/protected.md) 대상 브랜치에만 적용할 수 있습니다.
- 각 정책에 최대 5개의 규칙을 할당할 수 있습니다.
- 각 보안 정책 프로젝트에 최대 5개의 머지 리퀘스트 승인 정책을 할당할 수 있습니다.
- 그룹 또는 하위 그룹에 대해 생성된 정책은 그룹의 모든 머지 리퀘스트에 적용되는 데 시간이 걸릴 수 있습니다. 소요되는 시간은 프로젝트 수와 해당 프로젝트의 머지 리퀘스트 수에 의해 결정됩니다. 일반적으로 소요되는 시간은 몇 초입니다. 이전 관찰에서 수천 개의 프로젝트와 머지 리퀘스트가 있는 그룹의 경우 프로세스가 몇 분이 걸릴 수 있습니다.
- 머지 리퀘스트 승인 정책은 아티팩트 보고서에서 생성된 검사 결과의 무결성 또는 진정성을 확인하지 않습니다.
- 머지 리퀘스트 승인 정책은 규칙에 따라 평가됩니다. 기본적으로 규칙이 유효하지 않거나 평가할 수 없으면 승인이 필요합니다. [`fallback_behavior` 필드](#fallback_behavior)를 사용하여 이 동작을 변경할 수 있습니다.

## 파이프라인 요구 사항 {#pipeline-requirements}

머지 리퀘스트 승인 정책은 파이프라인의 결과에 따라 적용됩니다. 머지 리퀘스트 승인 정책을 구현할 때 다음을 고려합니다:

- 머지 리퀘스트 승인 정책은 수동 작업을 무시하고 완료된 파이프라인 작업을 평가합니다. 수동 작업이 실행되면 정책은 머지 리퀘스트의 작업을 다시 평가합니다.
- 보안 스캐너의 결과를 평가하는 머지 리퀘스트 승인 정책의 경우 모든 지정된 스캐너가 보안 보고서를 출력해야 합니다. 그렇지 않으면 취약성 도입 위험을 최소화하기 위해 승인이 적용됩니다. 이 동작은 다음에 영향을 미칠 수 있습니다:
  - 보안 검사가 아직 설정되지 않은 새 프로젝트
  - 보안 검사가 구성되기 전에 생성된 브랜치
  - 브랜치 간에 스캐너 구성이 일치하지 않는 프로젝트
- 파이프라인은 소스 및 대상 브랜치 모두에 대해 모든 활성화된 스캐너에 대한 아티팩트를 생성해야 합니다. 그렇지 않으면 비교 기준이 없으므로 정책을 안정적으로 평가할 수 없습니다. 자세한 내용은 [보안 검사 누락](#missing-security-scans)을 참조합니다. 검사 실행 정책을 사용하여 이 요구 사항을 적용합니다.
- 정책 평가는 성공적이고 완료된 병합 기본 파이프라인에 달려 있습니다. 병합 기본 파이프라인이 건너뛰면 병합 기본 파이프라인이 있는 머지 리퀘스트는 차단됩니다.
- 정책에 지정된 보안 스캐너는 정책이 적용되는 프로젝트에서 구성되고 활성화되어야 합니다. 그렇지 않으면 머지 리퀘스트 승인 정책을 평가할 수 없으며 해당 승인이 필요합니다.

## 머지 리퀘스트 승인 정책과 함께 보안 스캐너 사용에 대한 모범 사례 {#best-practices-for-using-security-scanners-with-merge-request-approval-policies}

새 프로젝트를 만들 때 머지 리퀘스트 승인 정책과 보안 검사를 모두 해당 프로젝트에 적용할 수 있습니다. 그러나 잘못 구성된 보안 스캐너는 머지 리퀘스트 승인 정책에 영향을 미칠 수 있습니다.

새 프로젝트에서 보안 검사를 구성하는 방법은 여러 가지입니다:

- 초기 `.gitlab-ci.yml` 구성 파일에 스캐너를 추가하여 프로젝트의 CI/CD 구성에서
- 파이프라인이 특정 보안 스캐너를 실행하도록 적용하는 검사 실행 정책에서
- 파이프라인에서 실행되어야 하는 작업을 제어하는 파이프라인 실행 정책에서

간단한 사용 사례의 경우 프로젝트의 CI/CD 구성을 사용할 수 있습니다. 포괄적인 보안 전략의 경우 머지 리퀘스트 승인 정책을 다른 정책 유형과 결합하는 것을 고려합니다.

불필요한 승인 요구 사항을 최소화하고 정확한 보안 평가를 보장하려면:

- **Run security scans on your default branch first**: 기능 브랜치를 만들기 전에 기본 브랜치에서 보안 검사가 성공적으로 실행되었는지 확인합니다.
- **Use consistent scanner configuration**: 선호하는 경우 단일 파이프라인에서 소스 및 대상 브랜치에서 동일한 스캐너를 실행합니다.
- **Verify that scans produce artifacts**: 검사가 성공적으로 완료되고 비교할 아티팩트를 생성하는지 확인합니다.
- **Keep branches synchronized**: 기본 브랜치의 변경 사항을 기능 브랜치에 정기적으로 병합합니다.
- **Consider pipeline configurations**: 새 프로젝트의 경우 초기 `.gitlab-ci.yml` 구성에 보안 스캐너를 포함합니다.

### 머지 리퀘스트 승인 정책을 적용하기 전에 보안 스캐너 확인 {#verify-security-scanners-before-you-apply-merge-request-approval-policies}

새 프로젝트에 머지 리퀘스트 승인 정책을 적용하기 전에 보안 검사를 구현하면 머지 리퀘스트 승인 정책에 의존하기 전에 보안 스캐너가 일관되게 실행되도록 할 수 있으므로 보안 검사 누락으로 인해 머지 리퀘스트가 차단되는 상황을 피할 수 있습니다.

보안 스캐너와 머지 리퀘스트 승인 정책을 함께 생성하고 확인하려면 다음 권장 워크플로를 사용합니다:

1. 프로젝트를 만듭니다.
1. `.gitlab-ci.yml` 구성, 검사 실행 정책 또는 파이프라인 실행 정책을 사용하여 보안 스캐너를 구성합니다.
1. 기본 브랜치에서 초기 파이프라인이 완료될 때까지 기다립니다. 문제를 해결하고 파이프라인을 다시 실행하여 계속하기 전에 성공적으로 완료되도록 합니다.
1. 동일한 보안 스캐너가 구성된 기능 브랜치를 사용하여 머지 리퀘스트를 생성합니다. 보안 스캐너가 성공적으로 완료되는지 다시 확인합니다.
1. 머지 리퀘스트 승인 정책을 적용합니다.

## 여러 파이프라인이 있는 머지 리퀘스트 {#merge-request-with-multiple-pipelines}

{{< history >}}

- GitLab 16.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/379108)되었으며 [플래그](../../../administration/feature_flags/_index.md)는 `multi_pipeline_scan_result_policies`입니다. 기본적으로 비활성화되어 있습니다.
- GitLab 16.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/409482)합니다. 기능 플래그 `multi_pipeline_scan_result_policies`이 제거되었습니다.
- 상위-하위 파이프라인 지원이 GitLab 16.11에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/428591)되었으며 [플래그](../../../administration/feature_flags/_index.md)는 `approval_policy_parent_child_pipeline`입니다. 기본적으로 비활성화되어 있습니다.
- GitLab 17.0에서 [GitLab.com에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/451597)되었습니다.
- GitLab 17.1에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/428591)합니다. 기능 플래그 `approval_policy_parent_child_pipeline`이 제거되었습니다.

{{< /history >}}

프로젝트는 여러 파이프라인 유형을 구성할 수 있습니다. 단일 커밋은 여러 파이프라인을 시작할 수 있으며, 각각에는 보안 검사가 포함될 수 있습니다.

- GitLab 16.3 이상에서 머지 리퀘스트의 소스 및 대상 브랜치에서 최신 커밋에 대해 완료된 모든 파이프라인의 결과가 평가되고 머지 리퀘스트 승인 정책을 적용하는 데 사용됩니다. 요청 시 DAST 파이프라인은 고려되지 않습니다.
- GitLab 16.2 이상에서는 머지 리퀘스트 승인 정책을 적용할 때 완료된 최신 파이프라인의 결과만 평가되었습니다.

프로젝트가 [머지 리퀘스트 파이프라인](../../../ci/pipelines/merge_request_pipelines.md)을 사용하는 경우 CI/CD 변수 `AST_ENABLE_MR_PIPELINES`을 `"true"`으로 설정해야 보안 검사 작업이 파이프라인에 있습니다. 자세한 내용은 [머지 리퀘스트 파이프라인과 함께 보안 검사 도구 사용](../detect/security_configuration.md#use-security-scanning-tools-with-merge-request-pipelines)을 참조하세요.

최신 커밋에서 많은 파이프라인이 실행된 프로젝트(예: 휴면 프로젝트)의 경우 정책 평가는 머지 리퀘스트의 소스 및 대상 브랜치에서 최대 1,000개의 파이프라인을 고려합니다.

상위-하위 파이프라인의 경우 정책 평가는 최대 1,000개의 하위 파이프라인을 고려합니다.

## 머지 리퀘스트 승인 정책 편집기 {#merge-request-approval-policy-editor}

> [!note]
> 프로젝트 소유자만 보안 정책 프로젝트를 선택할 [권한](../../permissions.md#project-permissions)이 있습니다.

정책이 완성되면 편집기 하단에서 **머지 리퀘스트로 설정**을 선택하여 저장합니다. 이렇게 하면 프로젝트의 구성된 보안 정책 프로젝트의 머지 리퀘스트로 리디렉션됩니다. 보안 정책 프로젝트가 프로젝트에 연결되지 않으면 GitLab이 이러한 프로젝트를 생성합니다. 기존 정책은 편집기 하단에서 **정책 삭제**를 선택하여 편집기 인터페이스에서 제거할 수도 있습니다.

대부분의 정책 변경 사항은 머지 리퀘스트가 병합되는 즉시 적용됩니다. 머지 리퀘스트를 거치지 않고 기본 브랜치에 직접 커밋된 모든 변경 사항은 정책 변경 사항이 적용되기까지 최대 10분이 걸릴 수 있습니다.

[정책 편집기](_index.md#policy-editor)는 YAML 모드와 규칙 모드를 지원합니다.

> [!note]
> 많은 수의 프로젝트를 가진 그룹에 대해 생성된 머지 리퀘스트 승인 정책을 전파하는 데 시간이 걸릴 수 있습니다.

## 머지 리퀘스트 승인 정책 스키마 {#merge-request-approval-policies-schema}

머지 리퀘스트 승인 정책이 포함된 YAML 파일은 `approval_policy` 키 아래에 중첩된 머지 리퀘스트 승인 정책 스키마와 일치하는 객체의 배열로 구성됩니다. `approval_policy` 키 아래에 최대 5개의 정책을 구성할 수 있습니다.

> [!note]
> 머지 리퀘스트 승인 정책은 `scan_result_policy` 키 아래에 정의되었습니다. GitLab 17.0까지는 정책을 두 키 아래에 정의할 수 있습니다. GitLab 17.0부터는 `approval_policy` 키만 지원됩니다.

새 정책을 저장하면 GitLab은 해당 내용을 [이 JSON 스키마](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/validators/json_schemas/security_orchestration_policy.json)에 대해 검증합니다. [JSON 스키마](https://json-schema.org/)를 읽는 방법에 익숙하지 않다면 다음 섹션과 표에서 대안을 제공합니다.

| 필드             | 형식                                     | 필수 | 설명                                          |
|-------------------|------------------------------------------|----------|------------------------------------------------------|
| `approval_policy` | 머지 리퀘스트 승인 정책 객체의 `array` | 참     | 머지 리퀘스트 승인 정책 목록(최대 5개)입니다. |

## 머지 리퀘스트 승인 정책 스키마 {#merge-request-approval-policy-schema}

{{< history >}}

- `enforcement_type` 필드:
  - GitLab 18.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/202746)되었으며 [플래그](../../../administration/feature_flags/_index.md)는 `security_policy_approval_warn_mode`입니다.
  - GitLab 18.6에서 [GitLab.com에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/505352)되었습니다. 기능 플래그 `security_policy_approval_warn_mode`이 제거되었습니다.
  - GitLab 18.9에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/221747)합니다. 기능 플래그 `security_policy_approval_warn_mode`이 제거되었습니다.

{{< /history >}}

| 필드               | 형식               | 필수 | 가능한 값 | 설명                                              |
|---------------------|--------------------|----------|-----------------|----------------------------------------------------------|
| `name`              | `string`           | 참     |                 | 정책의 이름입니다. 최대 255자입니다.           |
| `description`       | `string`           | 거짓    |                 | 정책의 설명입니다.                               |
| `enabled`           | `boolean`          | 참     | `true`, `false` | 정책을 활성화(`true`) 또는 비활성화(`false`)하는 플래그입니다. |
| `rules`             | 규칙의 `array`   | 참     |                 | 정책이 적용되는 규칙 목록입니다.                   |
| `actions`           | 작업의 `array` | 거짓    |                 | 정책이 적용되는 작업 목록입니다.                |
| `approval_settings` | `object`           | 거짓    |                 | 정책이 재정의하는 프로젝트 설정입니다.              |
| `fallback_behavior` | `object`           | 거짓    |                 | 유효하지 않거나 적용할 수 없는 규칙에 영향을 미치는 설정입니다.     |
| `policy_scope`      | [`policy_scope`](_index.md#configure-the-policy-scope)의 `object` | 거짓 |  | 지정한 프로젝트, 그룹 또는 규정 준수 프레임워크 레이블을 기반으로 정책의 범위를 정의합니다. |
| `policy_tuning`     | `object`           | 거짓    |                 | (실험) 정책 비교 논리에 영향을 미치는 설정입니다.     |
| `bypass_settings`   | `object`           | 거짓    |                 | 특정 브랜치, 토큰 또는 계정이 정책을 우회할 수 있는 시기에 영향을 미치는 설정입니다.     |
| `enforcement_type`  | `string`           | 거짓    | `enforce`, `warn` | 정책이 적용되는 방식을 정의합니다. 기본값(지정하지 않은 경우)은 `enforce`이며, 위반이 감지되면 머지 리퀘스트를 차단합니다. `warn` 값은 머지 리퀘스트를 진행하지만 경고 및 봇 코멘트를 표시합니다. |

## `scan_finding` 규칙 유형 {#scan_finding-rule-type}

{{< history >}}

- 머지 리퀘스트 승인 정책 필드 `vulnerability_attributes`:
  - GitLab 16.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123052)되었으며 [플래그](../../../administration/feature_flags/_index.md)는 `enforce_vulnerability_attributes_rules`입니다.
  - GitLab 16.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/418784)합니다. 기능 플래그가 제거되었습니다.
- 머지 리퀘스트 승인 정책 필드 `vulnerability_age`이(가) GitLab 16.2에서 [추가](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123956)되었습니다.
- `branch_exceptions` 필드:
  - GitLab 16.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/418741)되었으며 [플래그](../../../administration/feature_flags/_index.md)는 `security_policies_branch_exceptions`입니다.
  - GitLab 16.5에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133753)합니다. 기능 플래그가 제거되었습니다.
- `vulnerability_states` 옵션 `newly_detected`이(가) GitLab 17.0에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/issues/422414)되었으며 `new_needs_triage` 및 `new_dismissed` 옵션이 이를 대체하기 위해 추가되었습니다.

{{< /history >}}

이 규칙은 보안 검사 결과를 기반으로 정의된 작업을 적용합니다.

| 필드                      | 형식                | 필수                                   | 가능한 값                                                                                                    | 설명 |
|----------------------------|---------------------|--------------------------------------------|--------------------------------------------------------------------------------------------------------------------|-------------|
| `type`                     | `string`            | 참                                       | `scan_finding`                                                                                                     | 규칙의 유형입니다. |
| `branches`                 | `string`의 `array` | `branch_type` 필드가 존재하지 않으면 참 | `[]` 또는 브랜치 이름                                                                                          | 보호된 대상 브랜치에만 적용할 수 있습니다. 빈 배열 `[]`은 규칙을 모든 보호된 대상 브랜치에 적용합니다. `branch_type` 필드와 함께 사용할 수 없습니다. |
| `branch_type`              | `string`            | `branches` 필드가 존재하지 않으면 참    | `default` 또는 `protected`                                                                                           | 주어진 정책이 적용되는 보호된 브랜치의 유형입니다. `branches` 필드와 함께 사용할 수 없습니다. 기본 브랜치는 `protected`이어야 합니다. |
| `branch_exceptions`        | `string`의 `array` | 거짓                                      | 브랜치 이름                                                                                                  | 이 규칙에서 제외할 대상 브랜치입니다. |
| `scanners`                 | `string` 또는 [`scanner_with_attributes`](#scanner_with_attributes-object) 객체의 `array` | 참 | `[]` 또는 `sast`, `secret_detection`, `dependency_scanning`, `container_scanning`, `dast`, `coverage_fuzzing`, `api_fuzzing` | 이 규칙에서 고려할 보안 스캐너입니다. `sast`에는 SAST 및 SAST IaC 스캐너의 결과가 모두 포함됩니다. 빈 배열 `[]`은 규칙을 모든 보안 스캐너에 적용합니다. 스캐너를 문자열로 지정(규칙 수준 설정 적용) 또는 객체로 지정(해당 스캐너에 대해 `severity_levels`, `vulnerabilities_allowed` 및 `vulnerability_attributes` 재정의 포함)합니다. |
| `vulnerabilities_allowed`  | `integer`           | 참                                       | 0 이상                                                                                      | 이 규칙을 고려하기 전에 허용되는 취약성 수입니다. |
| `severity_levels`          | `string`의 `array` | 참                                       | `info`, `unknown`, `low`, `medium`, `high`, `critical`                                                             | 이 규칙에서 고려할 심각도 수준입니다. |
| `vulnerability_states`     | `string`의 `array` | 참                                       | `[]` 또는 `detected`, `confirmed`, `resolved`, `dismissed`, `new_needs_triage`, `new_dismissed`                      | 모든 취약성은 두 가지 범주로 나뉩니다:<br><br>**Newly Detected Vulnerabilities** \- 머지 리퀘스트 브랜치에서 식별되었지만 현재 MR의 대상 브랜치에는 존재하지 않는 취약성입니다. 이 정책 옵션에서는 규칙을 평가하기 전에 파이프라인이 완료되어야 하므로 취약성이 새로 감지되었는지 아닌지 알 수 있습니다. 머지 리퀘스트는 파이프라인과 필요한 보안 검사가 완료될 때까지 차단됩니다. `new_needs_triage` 옵션은 다음 상태를 고려합니다<br><br> • 감지됨<br><br> `new_dismissed` 옵션은 다음 상태를 고려합니다<br><br> • 해제됨<br><br>**Pre-Existing Vulnerabilities** \- 이 정책 옵션은 즉시 평가되며 기본 브랜치에서 이전에 감지된 취약성만 고려하므로 파이프라인 완료가 필요하지 않습니다.<br><br> • `Detected` - 정책은 감지됨 상태에서 취약성을 찾습니다.<br> • `Confirmed` - 정책은 확인됨 상태에서 취약성을 찾습니다.<br> • `Dismissed` - 정책은 해제됨 상태에서 취약성을 찾습니다.<br> • `Resolved` - 정책은 해결됨 상태에서 취약성을 찾습니다. <br><br>빈 배열 `[]`은 `['new_needs_triage', 'new_dismissed']`과 동일한 상태를 포함합니다. |
| `vulnerability_attributes` | `object`            | 거짓                                      | [`vulnerability_attributes`](#vulnerability_attributes-object) 객체 | 기본적으로 모든 취약성 결과가 고려됩니다. 특정 기준과 일치하는 취약성 결과만 고려하려면 이러한 필터를 적용합니다. 자세한 내용은 [`vulnerability_attributes` 객체](#vulnerability_attributes-object)를 참조하세요. |
| `vulnerability_age`        | `object`            | 거짓                                      | 해당 없음                                                                                                                | 기존 취약성 결과를 나이로 필터링합니다. 취약성의 나이는 프로젝트에서 감지된 이후의 시간으로 계산됩니다. 기준은 `operator`, `value`, `interval`입니다.<br>- `operator` 기준은 나이 비교가 (`greater_than`) 또는 더 젊은(`less_than`)인지 여부를 지정합니다.<br>- `value` 기준은 취약성의 나이를 나타내는 숫자 값을 지정합니다.<br>- `interval` 기준은 취약성의 나이의 측정 단위를 지정합니다: `day`, `week`, `month` 또는 `year`.<br><br>예: `operator: greater_than`, `value: 30`, `interval: day`. |

### `vulnerability_attributes` 객체 {#vulnerability_attributes-object}

{{< history >}}

- `known_exploited`, `epss_score` 및 `enrichment_data_unavailable` 필드가 GitLab 18.11에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/576860)되었으며 [기능 플래그](../../../administration/feature_flags/_index.md)는 `security_policies_kev_filter`입니다. 기본적으로 비활성화되어 있습니다.
- GitLab 19.1에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/229501)합니다. 기능 플래그 `security_policies_kev_filter`이 제거되었습니다.

{{< /history >}}

| 필드                        | 형식                 | 필수 | 가능한 값                                              | 설명 |
|------------------------------|----------------------|----------|--------------------------------------------------------------|-------------|
| `false_positive`             | `boolean`            | 거짓    | `true`, `false`                                              | 거짓 양성 상태로 필터링합니다. `true`은 거짓 양성만 포함하고 `false`은 이를 제외합니다. |
| `fix_available`              | `boolean`            | 거짓    | `true`, `false`                                              | 픽스 가용성으로 필터링합니다. `true`은 수정 가능한 취약성만 포함하고 `false`은 수정이 불가능한 취약성만 포함합니다. |
| `known_exploited`            | `boolean` | 거짓    | `true`, `false`                               | [CISA 알려진 악용 취약성(KEV)](https://www.cisa.gov/known-exploited-vulnerabilities-catalog) 카탈로그를 기반으로 필터링합니다. true인 경우 실제로 악용되고 있는 취약성만 포함합니다. false인 경우 알려진 악용 상태를 기반으로 취약성을 필터링하지 않습니다. |
| `epss_score`                 | `object` | 거짓    | `{operator, value}` 객체                    | [악용 예측 점수 시스템(EPSS)](https://www.first.org/epss/) 점수를 기반으로 필터링합니다. EPSS는 취약성이 악용될 확률(0~1)을 추정합니다. 객체로: `operator`은 `greater_than` 또는 `less_than`일 수 있습니다. `value`은 `0.0`과 `1.0` 사이의 숫자입니다. 예: `{operator: greater_than, value: 0.8}`.  |
| `enrichment_data_unavailable`| `object`             | 거짓    | `{action: "block"}` 또는 `{action: "ignore"}`                  | 사용 불가능한 강화 데이터(누락된 EPSS 점수 또는 알려진 악용 상태)가 있는 CVE 취약성을 처리하는 방법을 정의합니다. 'block'인 경우 강화 데이터가 없는 취약성이 규칙 수준 기준에 따라 평가됩니다. 'ignore'인 경우 강화 데이터가 없는 취약성은 정책 평가에서 제외됩니다. |

### `scanner_with_attributes` 객체 {#scanner_with_attributes-object}

{{< history >}}

- GitLab 18.10 에서 `atomic_scanner_rule_criteria` [플래그](../../../administration/feature_flags/_index.md)로 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/584704)되었습니다. 기본적으로 활성화됩니다. GitLab 18.11에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/230346)합니다. 기능 플래그가 제거되었습니다.

{{< /history >}}

> [!flag]
> 이 기능의 가용성은 기능 플래그로 제어됩니다. 자세한 내용은 기록을 참조하세요.

스캐너가 문자열 대신 객체로 지정되면 각 스캐너 유형이 자신의 기준으로 독립적으로 평가됩니다. 스캐너 수준에서 지정하지 않은 필드는 규칙 수준 값으로 정의된 설정으로 폴백됩니다.

| 필드                      | 형식                | 필수 | 가능한 값                                                                   | 설명 |
|----------------------------|---------------------|----------|-----------------------------------------------------------------------------------|-------------|
| `type`                     | `string`            | 참     | `sast`, `secret_detection`, `dependency_scanning`, `container_scanning`, `dast`, `coverage_fuzzing`, `api_fuzzing` | 스캐너 유형입니다. |
| `severity_levels`          | `string`의 `array` | 거짓    | `info`, `unknown`, `low`, `medium`, `high`, `critical`                            | 이 스캐너에 대한 규칙 수준 `severity_levels`을 재정의합니다. |
| `vulnerabilities_allowed`  | `integer`           | 거짓    | 0 이상                                                     | 이 스캐너에 대한 규칙 수준 `vulnerabilities_allowed`을 재정의합니다. |
| `vulnerability_attributes` | `object`            | 거짓    | [`vulnerability_attributes`](#vulnerability_attributes-object) 객체              | 이 스캐너에 대한 규칙 수준 `vulnerability_attributes`을 재정의합니다. |

스캐너별 기준을 사용한 예:

```yaml
rules:
  - type: scan_finding
    branches: []
    scanners:
      - type: dependency_scanning
        vulnerability_attributes:
          fix_available: true
        vulnerabilities_allowed: 0
        severity_levels:
          - critical
          - high
      - type: container_scanning
        vulnerability_attributes:
          known_exploited: true
          epss_score:
             value: 0.5
             operator: greater_than
          enrichment_data_unavailable:
             action: block
        vulnerabilities_allowed: 0
        severity_levels:
          - critical
    vulnerabilities_allowed: 5
    severity_levels:
      - critical
      - high
      - medium
    vulnerability_states:
      - new_needs_triage
```

이 예에서:

- **의존성 스캔**는 수정 가능한 심각한 또는 높은 심각도 취약성이 감지된 경우 승인이 필요합니다.
- **컨테이너 스캐닝**은 심각하고 알려진 악용 취약성이 감지된 경우 승인이 필요합니다.
- 각 스캐너는 자신의 임계값에 대해 독립적으로 평가됩니다. 규칙 수준 `vulnerabilities_allowed: 5` 및 `severity_levels`은 명시적 재정의가 없는 스캐너의 기본값으로 사용됩니다.

## `license_finding` 규칙 유형 {#license_finding-rule-type}

{{< history >}}

- GitLab 15.9에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/8092)되었으며 [플래그](../../../administration/feature_flags/_index.md)는 `license_scanning_policies`입니다.
- GitLab 15.11에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/397644)합니다. 기능 플래그 `license_scanning_policies`이 제거되었습니다.
- `branch_exceptions` 필드가 GitLab 16.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/418741)되었으며 [플래그](../../../administration/feature_flags/_index.md)는 `security_policies_branch_exceptions`입니다. 기본적으로 활성화됩니다. GitLab 16.5에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133753)합니다. 기능 플래그가 제거되었습니다.
- `licenses` 필드가 GitLab 17.11에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/10203)되었으며 [플래그](../../../administration/feature_flags/_index.md)는 `exclude_license_packages`입니다. 기능 플래그가 제거되었습니다.

{{< /history >}}

이 규칙은 라이선스 결과를 기반으로 정의된 작업을 적용합니다.

| 필드          | 형식     | 필수                                      | 가능한 값              | 설명                                                                                                                                                                                                         |
|----------------|----------|-----------------------------------------------|------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `type`         | `string` | 참                                          | `license_finding`            | 규칙의 유형입니다.                                                                                                                                                                                                    |
| `branches`     | `string`의 `array` | `branch_type` 필드가 존재하지 않으면 참    | `[]` 또는 브랜치 이름    | 보호된 대상 브랜치에만 적용할 수 있습니다. 빈 배열 `[]`은 규칙을 모든 보호된 대상 브랜치에 적용합니다. `branch_type` 필드와 함께 사용할 수 없습니다.                                                 |
| `branch_type`  | `string` | `branches` 필드가 존재하지 않으면 참       | `default` 또는 `protected`     | 주어진 정책이 적용되는 보호된 브랜치의 유형입니다. `branches` 필드와 함께 사용할 수 없습니다. 기본 브랜치는 `protected`이어야 합니다.                                                                   |
| `branch_exceptions` | `string`의 `array` | 거짓                                         | 브랜치 이름            | 이 규칙에서 제외할 대상 브랜치입니다.                                                                                                                                                                                 |
| `match_on_inclusion_license` | `boolean` | `licenses` 필드가 존재하지 않으면 참      | `true`, `false`              | `license_types`에 나열된 라이선스의 포함 또는 제외를 규칙이 일치하는지 여부입니다.                                                                                                                              |
| `license_types` | `string`의 `array` | `licenses` 필드가 존재하지 않으면 참      | 라이선스 유형                | 매칭할 [SPDX 라이선스 이름](https://spdx.org/licenses)입니다. 예를 들어 `Affero General Public License v1.0` 또는 `MIT License`.                                                                                     |
| `license_states` | `string`의 `array` | 참                                          | `newly_detected`, `detected` | 새로 감지되고/또는 이전에 감지된 라이선스와 일치하는지 여부입니다. `newly_detected` 상태는 새 패키지가 도입되거나 기존 패키지에 대해 새 라이선스가 감지될 때 승인을 트리거합니다. |
| `licenses`     | `object` | `license_types` 필드가 존재하지 않으면 참 | `licenses` 객체            | 패키지 예외를 포함하여 매칭할 [SPDX 라이선스 이름](https://spdx.org/licenses)입니다.                                                                                                                        |

### `licenses` 객체 {#licenses-object}

| 필드     | 형식     | 필수                                | 가능한 값                                      | 설명                                                |
|-----------|----------|-----------------------------------------|------------------------------------------------------|------------------------------------------------------------|
| `denied`  | `object` | `allowed` 필드가 존재하지 않으면 참 | `licenses_with_package_exclusion` 객체의 `array`  | 패키지 예외를 포함한 거부된 라이선스 목록입니다.  |
| `allowed` | `object` | `denied` 필드가 존재하지 않으면 참  | `licenses_with_package_exclusion` 객체의 `array`  | 패키지 예외를 포함한 허용된 라이선스 목록입니다. |

### `licenses_with_package_exclusion` 객체 {#licenses_with_package_exclusion-object}

`licenses_with_package_exclusion` 객체를 사용하여 라이선스 이름과 선택적 패키지 제외를 정의합니다.

| 필드  | 형식     | 필수 | 가능한 값   | 설명                                        |
|--------|----------|----------|-------------------|----------------------------------------------------|
| `name` | `string` | 참     | SPDX 라이선스 이름 | [SPDX 라이선스 이름](https://spdx.org/licenses).    |
| `packages` | `object` | 거짓    | `packages` 객체 | 주어진 라이선스에 대한 패키지 예외 목록입니다. |

> [!note]
> `name` 필드는 유효한 [SPDX 라이선스 이름](https://spdx.org/licenses)이어야 합니다. `unknown` 값은 인식된 SPDX 라이선스 이름이 아니며 `licenses` 필드에서 지원되지 않습니다. `unknown` 라이선스에 대해 구성된 패키지 수준 제외는 머지 리퀘스트 승인 평가 중에 무시됩니다. `unknown` 라이선스가 있는 패키지를 관리하려면 [`license_types`](#license_finding-rule-type) 필드를 사용하거나 `unknown`을 정책의 라이선스로 허용합니다. 자세한 내용은 [`unknown` 라이선스 때문에 머지 리퀘스트를 차단하는 라이선스 승인 정책](../../compliance/license_approval_policies.md#license-approval-policies-block-merge-requests-due-to-unknown-licenses)을 참조합니다.

### `packages` 객체 {#packages-object}

`packages` 객체를 사용하여 라이선스 항목에 대한 패키지 URL 제외를 정의합니다.

| 필드  | 형식     | 필수 | 가능한 값                                       | 설명                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
|--------|----------|----------|-------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `excluding` | `object` | 참     | {purls: `strings` 사용 `uri` 형식의 `array`} | 주어진 라이선스에 대한 패키지 예외 목록입니다. [`purl`](https://github.com/package-url/purl-spec?tab=readme-ov-file#purl) 컴포넌트 `scheme:type/name@version`을 사용하여 패키지 예외 목록을 정의합니다. `scheme:type/name` 컴포넌트는 필수입니다. `@` 및 `version`은 선택 사항입니다. 버전이 지정되면 해당 버전만 예외로 간주됩니다. 버전이 지정되지 않고 `@` 문자가 `purl`의 끝에 추가되면 정확한 이름을 가진 패키지만 일치로 간주됩니다. `@` 문자가 패키지 이름에 추가되지 않으면 주어진 라이선스에 대해 동일한 접두어를 가진 모든 패키지가 일치합니다. 예를 들어, purl `pkg:gem/bundler`은 두 패키지가 모두 동일한 라이선스를 사용하기 때문에 `bundler` 및 `bundler-stats` 패키지와 일치합니다. `purl` `pkg:gem/bundler@`를 정의하면 `bundler` 패키지만 일치합니다. |

## `any_merge_request` 규칙 유형 {#any_merge_request-rule-type}

{{< history >}}

- `branch_exceptions` 필드가 GitLab 16.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/418741)되었으며 [플래그](../../../administration/feature_flags/_index.md)는 `security_policies_branch_exceptions`입니다. 기본적으로 활성화됩니다. GitLab 16.5에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133753)합니다. 기능 플래그가 제거되었습니다.
- `any_merge_request` 규칙 유형이 GitLab 16.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/418752)되었습니다. 기본적으로 활성화됩니다. GitLab 16.6에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136298)합니다. 기능 플래그가 [제거](https://gitlab.com/gitlab-org/gitlab/-/issues/432127)되었습니다.

{{< /history >}}

이 규칙은 커밋 서명을 기반으로 모든 머지 리퀘스트에 대해 정의된 작업을 적용합니다.

| 필드               | 형식                | 필수                                   | 가능한 값           | 설명 |
|---------------------|---------------------|--------------------------------------------|---------------------------|-------------|
| `type`              | `string`            | 참                                       | `any_merge_request`       | 규칙의 유형입니다. |
| `branches`          | `string`의 `array` | `branch_type` 필드가 존재하지 않으면 참 | `[]` 또는 브랜치 이름 | 보호된 대상 브랜치에만 적용할 수 있습니다. 빈 배열 `[]`은 규칙을 모든 보호된 대상 브랜치에 적용합니다. `branch_type` 필드와 함께 사용할 수 없습니다. |
| `branch_type`       | `string`            | `branches` 필드가 존재하지 않으면 참    | `default` 또는 `protected`  | 주어진 정책이 적용되는 보호된 브랜치의 유형입니다. `branches` 필드와 함께 사용할 수 없습니다. 기본 브랜치는 `protected`이어야 합니다. |
| `branch_exceptions` | `string`의 `array` | 거짓                                      | 브랜치 이름         | 이 규칙에서 제외할 대상 브랜치입니다. |
| `commits`           | `string`            | 참                                       | `any`, `unsigned`         | 규칙이 모든 커밋과 일치하는지 또는 머지 리퀘스트에서 서명되지 않은 커밋이 감지되는 경우에만 일치하는지 여부입니다. |

## `require_approval` 작업 유형 {#require_approval-action-type}

{{< history >}}

- 최대 5개의 별도 `require_approval` 작업을 지정할 수 있습니다:
  - GitLab 17.7에서 [추가](https://gitlab.com/groups/gitlab-org/-/epics/12319)되었으며 [플래그](../../../administration/feature_flags/_index.md)는 `multiple_approval_actions`입니다.
  - GitLab 17.8에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/505374)합니다. 기능 플래그 `multiple_approval_actions`이 제거되었습니다.
- `role_approvers`로 사용자 지정 역할을 지정할 수 있도록 지원:
  - GitLab 17.9에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/13550)되었으며 [플래그](../../../administration/feature_flags/_index.md)는 `security_policy_custom_roles`입니다. 기본적으로 활성화됩니다.
  - GitLab 17.10에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/505742)합니다. 기능 플래그 `security_policy_custom_roles`이 제거되었습니다.

{{< /history >}}

이 작업은 정의된 정책에서 하나 이상의 규칙에 대해 조건이 충족될 때 승인 규칙이 필요하게 만듭니다.

동일한 `require_approval` 블록에서 여러 승인자를 지정하는 경우 적격 승인자 중 누구든지 승인 요구 사항을 충족할 수 있습니다. 예를 들어 두 개의 `group_approvers`을 지정하고 `approvals_required`을 `2`로 설정하면 두 승인이 모두 동일한 그룹에서 올 수 있습니다. 고유한 승인자 유형에서 여러 승인을 요구하려면 여러 `require_approval` 작업을 사용합니다.

| 필드 | 형식 | 필수 | 가능한 값 | 설명 |
|-------|------|----------|-----------------|-------------|
| `type` | `string` | 참 | `require_approval` | 작업의 유형입니다. |
| `approvals_required` | `integer` | 참 | 0 이상 | 필요한 머지 리퀘스트 승인 수입니다. |
| `user_approvers` | `string`의 `array` | 조건부 | 하나 이상의 사용자의 사용자 이름 | 승인자로 간주할 사용자입니다. 사용자는 승인에 적격이 되려면 프로젝트에 접근할 수 있어야 합니다. |
| `user_approvers_ids` | `integer`의 `array` | 조건부 <sup>1</sup> | 하나 이상의 사용자의 ID | 승인자로 간주할 사용자의 ID입니다. 사용자는 승인에 적격이 되려면 프로젝트에 접근할 수 있어야 합니다. |
| `group_approvers` | `string`의 `array` | 조건부 <sup>1</sup> | 하나 이상의 그룹의 경로 | 승인자로 간주할 그룹입니다. [그룹에 직접 멤버십이 있는](../../project/merge_requests/approvals/rules.md#group-approvers) 사용자는 승인에 적격입니다. |
| `group_approvers_ids` | `integer`의 `array` | 조건부 <sup>1</sup> | 하나 이상의 그룹의 ID | 승인자로 간주할 그룹의 ID입니다. [그룹에 직접 멤버십이 있는](../../project/merge_requests/approvals/rules.md#group-approvers) 사용자는 승인에 적격입니다. |
| `role_approvers` | `string`의 `array` | 조건부 <sup>1</sup> | 하나 이상의 [역할](../../permissions.md#roles)(예: `owner`, `maintainer`)입니다. 사용자 지정 역할(또는 YAML 모드의 사용자 지정 역할 식별자)을 `role_approvers`로 지정할 수도 있습니다. 사용자 지정 역할에는 머지 리퀘스트를 승인할 수 있는 권한이 있으면 됩니다. 사용자 지정 역할은 사용자 및 그룹 승인자와 함께 선택할 수 있습니다. | 승인에 적격인 역할입니다. 지정한 정확한 역할을 가진 사용자 또는 해당 역할을 기반으로 한 사용자 지정 역할을 가진 사용자만 승인할 수 있습니다. 더 높은 권한을 가진 역할은 승인할 수 없습니다. 예를 들어 `developer`을 선택하면 Developer 역할을 가진 사용자는 승인할 수 있습니다. `developer`을 기반으로 한 사용자 지정 역할이 존재하면 해당 사용자 지정 역할을 가진 사용자도 승인할 수 있습니다. Maintainer 및 Owner는 추가하지 않으면 승인할 수 없습니다. |

**Footnotes:**

1. 승인자 필드 `user_approvers`, `user_approvers_ids`, `group_approvers`, `group_approvers_ids` 또는 `role_approvers` 중 하나 이상을 사용하여 승인자를 지정해야 합니다.

### 유효한 구성 예 {#valid-configuration-examples}

**유효한 `user_approvers`:**

```yaml
actions:
  - type: require_approval
    approvals_required: 2
    user_approvers:
      - alice
      - bob
```

**유효한 `group_approvers`:**

```yaml
actions:
  - type: require_approval
    approvals_required: 1
    group_approvers:
      - security-team
```

**유효한 `role_approvers`:**

```yaml
actions:
  - type: require_approval
    approvals_required: 1
    role_approvers:
      - maintainer
```

**Valid with multiple approver types:**

```yaml
actions:
  - type: require_approval
    approvals_required: 2
    user_approvers:
      - alice
    group_approvers:
      - security-team
    role_approvers:
      - maintainer
```

### 유효하지 않은 구성 예 {#invalid-configuration-example}

**Invalid because no approvers specified:**

```yaml
actions:
  - type: require_approval
    approvals_required: 2
    # ERROR: At least one approver field must be specified
    # This configuration will fail validation
```

## `send_bot_message` 작업 유형 {#send_bot_message-action-type}

{{< history >}}

- 프로젝트의 `send_bot_message` 작업 유형:
  - GitLab 16.11에서 `approval_policy_disable_bot_comment` [플래그](../../../administration/feature_flags/_index.md)로 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/438269)되었습니다. 기본적으로 비활성화되어 있습니다.
  - GitLab 17.0에서 [GitLab Self-Managed 및 GitLab Dedicated에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/454852)되었습니다.
  - GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/454852)합니다. 기능 플래그 `approval_policy_disable_bot_comment`이 제거되었습니다.
- 그룹의 `send_bot_message` 작업 유형:
  - GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/469449)되었으며 [플래그](../../../administration/feature_flags/_index.md)는 `approval_policy_disable_bot_comment_group`입니다. 기본적으로 비활성화되어 있습니다.
  - GitLab 17.2에서 [GitLab Self-Managed 및 GitLab Dedicated에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/469449)되었습니다.
  - GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/469449)합니다. 기능 플래그 `approval_policy_disable_bot_comment_group`이 제거되었습니다.

{{< /history >}}

이 작업은 정책 위반이 감지될 때 머지 리퀘스트의 봇 메시지 구성을 활성화합니다. 작업이 지정되지 않으면 봇 메시지가 기본적으로 활성화됩니다. 여러 정책이 정의되어 있으면 최소 하나의 정책이 `send_bot_message` 작업이 활성화된 경우에만 봇 메시지가 전송됩니다.

| 필드 | 형식 | 필수 | 가능한 값 | 설명 |
|-------|------|----------|-----------------|-------------|
| `type` | `string` | 참 | `send_bot_message` | 작업의 유형입니다. |
| `enabled` | `boolean` | 참 | `true`, `false` | 정책 위반이 감지될 때 봇 메시지를 생성할지 여부입니다. 기본값: `true` |

### 봇 메시지 예 {#example-bot-messages}

![보안 검사에서 감지한 취약성을 표시하는 봇 메시지 예입니다.](img/scan_result_policy_example_bot_message_vulnerabilities_v17_0.png)

![정책 평가에 필요한 누락되거나 불완전한 검사 아티팩트를 표시하는 봇 메시지 예입니다.](img/scan_result_policy_example_bot_message_artifacts_v17_0.png)

## 경고 모드 {#warn-mode}

{{< history >}}

- GitLab 17.8에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/15552)되었으며 [기능 플래그](../../../administration/feature_flags/_index.md)는 `security_policy_approval_warn_mode`입니다. 기본적으로 비활성화됨
- GitLab 18.6에서 [GitLab.com, GitLab Self-Managed 및 GitLab Dedicated에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/505352)되었습니다.
- 라이선스 검사 지원:
  - GitLab 18.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/579664)되었으며 [기능 플래그](../../../administration/feature_flags/_index.md)는 `security_policy_warn_mode_license_scanning`입니다. 기본적으로 활성화됩니다.
  - GitLab 18.9에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/221747)합니다. 기능 플래그 `security_policy_approval_warn_mode`이 제거되었습니다.

{{< /history >}}

> [!flag]
> 이 기능의 가용성은 기능 플래그로 제어됩니다. 자세한 내용은 기록을 참조하세요.

경고 모드를 통해 보안 팀은 완전한 적용 전에 보안 정책의 영향을 테스트하고 검증하여 새로운 보안 정책 적용 시 개발자 마찰을 줄일 수 있습니다. 정책이 `enforcement_type: warn`로 구성되면 머지 리퀘스트는 모든 머지 리퀘스트 승인 정책 위반을 우회하는 옵션을 제공합니다.

경고 모드가 활성화(`enforcement_type: warn`) 되고 머지 리퀘스트가 보안 정책 위반을 트리거할 때 정책 적용은 여러 가지 방식으로 다릅니다:

- 비차단 검증: 정책이 정책 위반을 나열하는 정보성 봇 코멘트를 생성합니다.
- 선택적 승인: 사용자가 정책을 우회하고 해제 이유를 제공하면 승인이 선택 사항입니다.
- 향상된 감사: 머지 리퀘스트가 우회된 보안 정책과 함께 병합된 후 감사 이벤트가 생성됩니다.
- 취약성 보고서 통합: 우회된 정책이 있는 머지 리퀘스트에 의해 취약성이 도입된 경우 우회 세부 정보가 취약성 보고서에 표시됩니다.
- 종속성 목록 통합: 정책을 우회하는 머지 리퀘스트가 라이선스를 도입하면 종속성 목록은 라이선스 옆에 정책 위반 배지를 표시합니다. 정책 위반 배지는 프로젝트의 종속성 목록에서만 사용 가능합니다.
- 비활성화된 승인 설정: 승인 설정 재정의는 적용되지 않습니다.

### 경고 모드 구성 {#configuring-warn-mode}

머지 리퀘스트 승인 정책에 대해 경고 모드를 활성화하려면 `enforcement_type` 필드를 `warn`으로 설정합니다:

```yaml
approval_policy:
  - name: Warn mode policy
    description: ''
    enabled: true
    enforcement_type: warn
    policy_scope:
      projects:
        excluding: []
    rules:
      - type: scan_finding
        scanners:
          - secret_detection
        vulnerabilities_allowed: 0
        severity_levels: []
        vulnerability_states: []
        branch_type: protected
    actions:
      - type: require_approval
        approvals_required: 1
        role_approvers:
          - developer
          - maintainer
      - type: send_bot_message
        enabled: true
```

## `approval_settings` {#approval_settings}

{{< history >}}

- `block_group_branch_modification` 필드:
  - GitLab 16.8에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/420724)되었으며 [플래그](../../../administration/feature_flags/_index.md)는 `scan_result_policy_block_group_branch_modification`입니다.
  - GitLab 17.6에서 [GitLab.com 및 GitLab Self-Managed에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/437306)되었습니다.
  - GitLab 17.7에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/503930)합니다. 기능 플래그 `scan_result_policy_block_group_branch_modification`이 제거되었습니다.
- `block_unprotecting_branches` 필드
  - GitLab 16.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/423101)되었으며 [플래그](../../../administration/feature_flags/_index.md)는 `scan_result_policy_settings`입니다. 기본적으로 비활성화되어 있습니다.
  - `block_unprotecting_branches` 필드가 GitLab 16.7에서 [로 대체](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137153)되었으며 `block_branch_modification` 필드입니다.
- `scan_result_policies_block_unprotecting_branches` 기능 플래그가 16.4에서 `scan_result_policy_settings` 기능 플래그를 대체했습니다.
  - GitLab 16.7에서 [GitLab.com 및 GitLab Self-Managed에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/423901)되었습니다.
  - GitLab 16.11에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/433415)합니다. 기능 플래그 `scan_result_policies_block_unprotecting_branches`이 제거되었습니다.
- `prevent_approval_by_author`, `prevent_approval_by_commit_author`, `remove_approvals_with_new_commit` 및 `require_password_to_approve` 필드:
  - GitLab 16.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/418752)되었으며 [플래그](../../../administration/feature_flags/_index.md)는 `scan_result_any_merge_request`입니다. 기본적으로 비활성화되어 있습니다.
  - GitLab 16.6에서 [GitLab.com에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/423988)되었습니다.
  - GitLab 16.7에서 [GitLab Self-Managed에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/423988)되었습니다.
  - GitLab 16.8에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/432127)합니다. 기능 플래그 `scan_result_any_merge_request`이 제거되었습니다.
- `prevent_pushing_and_force_pushing` 필드
  - GitLab 16.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/420629)되었으며 [플래그](../../../administration/feature_flags/_index.md)는 `scan_result_policies_block_force_push`입니다. 기본적으로 비활성화되어 있습니다.
  - GitLab 16.6에서 [GitLab.com에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/427260)되었습니다.
  - GitLab 16.7에서 [GitLab Self-Managed에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/427260)되었습니다.
  - GitLab 16.9에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/432123)합니다. 기능 플래그 `scan_result_policies_block_force_push`이 제거되었습니다.

{{< /history >}}

정책에 설정된 설정은 프로젝트의 설정을 덮어씁니다.

| 필드                               | 형식                  | 필수 | 가능한 값                                               | 적용 가능한 규칙 유형 | 설명 |
|-------------------------------------|-----------------------|----------|---------------------------------------------------------------|----------------------|-------------|
| `block_branch_modification`         | `boolean`             | 거짓    | `true`, `false`                                               | 모두                  | 활성화되면 사용자가 보호된 브랜치 목록에서 브랜치를 제거하거나, 보호된 브랜치를 삭제하거나, 보안 정책에 포함된 브랜치의 기본 브랜치를 변경하는 것을 방지합니다. 이는 사용자가 브랜치에서 보호 상태를 제거하여 취약한 코드를 병합할 수 없도록 합니다. `branches`, `branch_type` 및 `policy_scope`을 기반으로 적용되며, 감지된 취약성과 상관없이 적용됩니다. |
| `block_group_branch_modification`   | `boolean` 또는 `object` | 거짓    | `true`, `false`, `{ enabled: boolean, exceptions: [{ id: Integer}] }` | 모두                  | 활성화되면 정책이 적용되는 모든 그룹에서 사용자가 그룹 수준의 보호된 브랜치를 제거하는 것을 방지합니다. `block_branch_modification`이 `true`인 경우 암묵적으로 `true`으로 기본 설정됩니다. [그룹 수준의 보호된 브랜치](../../project/repository/branches/protected.md#in-a-group)를 지원하는 최상위 그룹을 `exceptions`(으)로 추가합니다. |
| `prevent_approval_by_author`        | `boolean`             | 거짓    | `true`, `false`                                               | `Any merge request`  | 활성화되면 머지 리퀘스트 작성자가 자신의 MR을 승인할 수 없습니다. 이는 코드 작성자가 취약성을 도입하고 병합할 코드를 승인할 수 없도록 합니다. |
| `prevent_approval_by_commit_author` | `boolean`             | 거짓    | `true`, `false`                                               | `Any merge request`  | 활성화되면 MR에 코드를 기여한 사용자는 승인할 수 없습니다. 이는 코드 커미터가 취약성을 도입하고 병합할 코드를 승인할 수 없도록 합니다. |
| `remove_approvals_with_new_commit`  | `boolean`             | 거짓    | `true`, `false`                                               | `Any merge request`  | 활성화되면 MR이 병합에 필요한 모든 승인을 받았지만 새 커밋이 추가된 경우 새 승인이 필요합니다. 이는 취약성을 포함할 수 있는 새 커밋이 도입되지 않도록 합니다. |
| `require_password_to_approve`       | `boolean`             | 거짓    | `true`, `false`                                               | `Any merge request`  | 활성화되면 승인자가 승인하기 전에 다시 인증해야 합니다. 승인자는 구성된 인증 방법에 따라 암호 또는 SAML을 사용하여 다시 인증할 수 있습니다. 이는 승인자의 신원을 확인하기 위한 추가 보안 계층을 추가합니다. 자세한 정보는 [사용자 재인증 필요](../../project/merge_requests/approvals/settings.md#require-user-re-authentication-to-approve)를 참조하세요. |
| `prevent_pushing_and_force_pushing` | `boolean`             | 거짓    | `true`, `false`                                               | 모두                  | 활성화되면 보안 정책에 포함된 보호된 브랜치로의 푸시 및 강제 푸시를 방지합니다. 이는 사용자가 머지 리퀘스트 프로세스를 우회하여 취약한 코드를 브랜치에 추가할 수 없도록 합니다. 아직 존재하지 않는 브랜치를 생성하는 것은 표준 [보호된 브랜치](../../project/repository/branches/protected.md) 규칙으로 제어됩니다. 이 설정은 브랜치가 존재한 후의 후속 푸시 및 강제 푸시에 적용됩니다. |

### 승인 설정의 적용 범위 {#enforcement-scope-of-approval-settings}

이러한 설정은 정책에 대해 위반 사항이 있는 머지 리퀘스트에만 적용됩니다:

- `prevent_approval_by_author`
- `prevent_approval_by_commit_author`
- `remove_approvals_with_new_commit`
- `require_password_to_approve`

머지 리퀘스트에 정책 위반이 없으면 해당 설정은 그 머지 리퀘스트에 영향을 미치지 않습니다.

이러한 설정은 정책이 활성화되어 있으면 머지 리퀘스트에 정책 위반이 있는지 여부와 관계없이 항상 적용됩니다:

- `block_branch_modification`
- `block_group_branch_modification`
- `prevent_pushing_and_force_pushing` 설정

## `fallback_behavior` {#fallback_behavior}

{{< history >}}

- `fallback_behavior` 필드:
  - [GitLab 17.0에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/451784) [플래그 포함](../../../administration/feature_flags/_index.md) `security_scan_result_policies_unblock_fail_open_approval_rules`. 기본적으로 비활성화되어 있습니다.
  - [GitLab 17.0에서 GitLab.com, GitLab Self-Managed 및 GitLab Dedicated에서 활성화됨](https://gitlab.com/groups/gitlab-org/-/epics/10816).
  - GitLab 17.1에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/451784)합니다. 기능 플래그 `security_scan_result_policies_unblock_fail_open_approval_rules`이 제거되었습니다.

{{< /history >}}

| 필드  | 형식     | 필수 | 가능한 값    | 설명                                                                                                          |
|--------|----------|----------|--------------------|----------------------------------------------------------------------------------------------------------------------|
| `fail` | `string` | 거짓    | `open` 또는 `closed` | `closed` (기본값): 정책의 유효하지 않거나 적용할 수 없는 규칙은 승인이 필요합니다. `open`: 정책의 유효하지 않거나 적용할 수 없는 규칙은 승인이 필요하지 않습니다. |

## `policy_tuning` {#policy_tuning}

### `unblock_rules_using_execution_policies` {#unblock_rules_using_execution_policies}

{{< history >}}

- [GitLab 17.10에서 파이프라인 실행 정책에서 사용하기 위한 지원이 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/498624) [플래그 포함](../../../administration/feature_flags/_index.md) `unblock_rules_using_pipeline_execution_policies`. 기본적으로 활성화됩니다.
- [GitLab 18.3에서 일반 공급](https://gitlab.com/gitlab-org/gitlab/-/issues/525270). 기능 플래그 `unblock_rules_using_pipeline_execution_policies`이 제거되었습니다.

{{< /history >}}

| 필드  | 형식     | 필수 | 가능한 값    | 설명                                                                                                          |
|--------|----------|----------|--------------------|----------------------------------------------------------------------------------------------------------------------|
| `unblock_rules_using_execution_policies` | `boolean` | 거짓    | `true`, `false` | 활성화되면 검사 실행 정책 또는 파이프라인 실행 정책에 의해 검사가 필요하지만 필수 검사 결과물이 소스 브랜치에서 누락된 경우 승인 규칙이 머지 리퀘스트를 차단하지 않습니다. 이 옵션은 프로젝트 또는 그룹에 일치하는 스캐너가 있는 기존 검사 실행 정책 또는 파이프라인 실행 정책이 있을 때만 작동합니다. |

[라이선스 검사 규칙](#license_finding-rule-type)은 새로 감지된 상태만 대상으로 하는 경우에만 제외할 수 있습니다(`license_states`이 `newly_detected`(으)로 설정됨).

#### 예제 {#examples}

##### `policy_tuning` 및 검사 실행 정책의 예 {#example-of-policy_tuning-with-a-scan-execution-policy}

이 예를 `.gitlab/security-policies/policy.yml` 파일에 사용할 수 있습니다. [보안 정책 프로젝트](enforcement/security_policy_projects.md)에 저장되어 있습니다:

```yaml
scan_execution_policy:
- name: Enforce dependency scanning
  description: ''
  enabled: true
  policy_scope:
    projects:
      excluding: []
  rules:
  - type: pipeline
    branch_type: all
  actions:
  - scan: dependency_scanning
approval_policy:
- name: Dependency scanning approvals
  description: ''
  enabled: true
  policy_scope:
    projects:
      excluding: []
  rules:
  - type: scan_finding
    scanners:
    - dependency_scanning
    vulnerabilities_allowed: 0
    severity_levels: []
    vulnerability_states: []
    branch_type: protected
  actions:
  - type: require_approval
    approvals_required: 1
    role_approvers:
    - developer
  - type: send_bot_message
    enabled: true
  fallback_behavior:
    fail: closed
  policy_tuning:
    unblock_rules_using_execution_policies: true
```

##### `policy_tuning` 및 파이프라인 실행 정책의 예 {#example-of-policy_tuning-with-a-pipeline-execution-policy}

> [!warning]
> 이 기능은 GitLab 17.10 이전에 생성된 파이프라인 실행 정책에서 작동하지 않습니다. 이 기능을 이전 파이프라인 실행 정책과 함께 사용하려면 정책을 복사, 삭제 및 다시 생성하세요. 자세한 정보는 [GitLab 17.10 이전에 생성된 파이프라인 실행 정책 다시 생성](#recreate-pipeline-execution-policies-created-before-gitlab-1710)을 참조하세요.

이 예를 `.gitlab/security-policies/policy.yml` 파일에 사용할 수 있습니다. [보안 정책 프로젝트](enforcement/security_policy_projects.md)에 저장되어 있습니다:

```yaml
---
pipeline_execution_policy:
- name: Enforce dependency scanning
  description: ''
  enabled: true
  pipeline_config_strategy: inject_policy
  content:
    include:
    - project: my-group/pipeline-execution-ci-project
      file: policy-ci.yml
      ref: main # optional
```

`policy-ci.yml`의 연결된 파이프라인 실행 정책 CI/CD 구성:

```yaml
include:
  - template: Jobs/Dependency-Scanning.gitlab-ci.yml
```

###### GitLab 17.10 이전에 생성된 파이프라인 실행 정책 다시 생성 {#recreate-pipeline-execution-policies-created-before-gitlab-1710}

GitLab 17.10 이전에 생성된 파이프라인 실행 정책은 `policy_tuning` 기능을 사용하는 데 필요한 데이터를 포함하지 않습니다. 이 기능을 이전 파이프라인 실행 정책과 함께 사용하려면 이전 정책을 복사 및 삭제한 후 다시 생성하세요.

<i class="fa-youtube-play" aria-hidden="true"></i> 비디오 안내를 보려면 [보안 정책: `policy_tuning`(으)로 사용하기 위한 파이프라인 실행 정책 다시 생성](https://youtu.be/XN0jCQWlk1A).
<!-- Video published on 2025-03-07 -->

파이프라인 실행 정책을 다시 생성하려면:

<!-- markdownlint-disable MD044 -->

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **정책**을 선택합니다.
1. 다시 생성하려는 파이프라인 실행 정책을 선택합니다.
1. 오른쪽 사이드바에서 **YAML** 탭을 선택하고 전체 정책 파일의 내용을 복사합니다.
1. 정책 테이블 옆에서 수직 줄임표({{< icon name="ellipsis_v" >}})를 선택하고 **삭제**를 선택합니다.
1. 생성된 머지 리퀘스트를 병합합니다.
1. **보안** > **정책**으로 돌아가서 **새 정책**을 선택합니다.
1. **파이프라인 실행 정책** 섹션에서 **정책 선택**을 선택합니다.
1. **.yaml 모드**에서 이전 정책의 내용을 붙여넣습니다.
1. **머지 리퀘스트를 통해 업데이트**를 선택하고 생성된 머지 리퀘스트를 병합합니다.

<!-- markdownlint-enable MD044 -->

### `security_report_time_window` {#security_report_time_window}

{{< history >}}

- `approval_policy_time_window`라는 이름의 [기능 플래그](../../../administration/feature_flags/_index.md)와 함께 GitLab 18.5에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/525509).
- GitLab 18.5에서 [정식 출시(GA)](https://gitlab.com/gitlab-org/gitlab/-/issues/543027). 기능 플래그 `approval_policy_time_window`이 제거되었습니다.

{{< /history >}}

바쁜 프로젝트에서는 최신 파이프라인이 보안 검사를 즉시 완료할 수 없을 수 있으며, 이로 인해 보안 보고서 비교가 차단됩니다. `security_report_time_window` 설정을 사용하여 최근에 완료된 파이프라인에서 보안 보고서를 선택합니다. 보안 보고서는 대상 브랜치 파이프라인 생성 이전의 시간(분)으로 지정된 시간 윈도우보다 오래될 수 없습니다. 이 설정은 선택한 파이프라인이 이미 완료된 보안 보고서를 가진 경우에는 적용되지 않습니다.

| 필드  | 형식     | 필수 | 가능한 값    | 설명                                                                                                          |
|--------|----------|----------|--------------------|----------------------------------------------------------------------------------------------------------------------|
| `security_report_time_window` | `integer` | 거짓    | 1~10080(7일) | 보안 보고서 비교를 위해 대상 파이프라인을 선택하기 위한 시간 윈도우(분)를 지정합니다. |

## 정책 범위 스키마 {#policy-scope-schema}

정책 적용을 사용자 지정하기 위해 정책의 범위를 정의하여 특정 프로젝트, 그룹 또는 규정 준수 프레임워크 레이블을 포함 또는 제외할 수 있습니다. 자세한 정보는 [범위](_index.md#configure-the-policy-scope)를 참조하세요.

> [!note]
> `policy_scope` 필드를 빈 컬렉션으로 설정하면(예: `including: []`), 필드를 생략하는 것과 동일하게 처리되므로 정책이 해당 범위 차원의 모든 프로젝트에 적용됩니다. 정책을 완전히 비활성화하려면 `enabled: false`을 사용합니다. 자세한 정보는 [`policy_scope`의 빈 컬렉션](_index.md#empty-collections-in-policy_scope)을 참조하세요.

## `bypass_settings` {#bypass_settings}

`bypass_settings` 필드를 사용하면 특정 브랜치, 액세스 토큰 또는 서비스 계정에 대한 정책 예외를 지정할 수 있습니다. 우회 조건이 충족되면 일치하는 머지 리퀘스트 또는 브랜치에 정책이 적용되지 않습니다.

| 필드             | 형식    | 필수 | 설명                                                                     |
|-------------------|---------|----------|---------------------------------------------------------------------------------|
| `branches`        | 배열   | 거짓    | 정책을 우회하는 소스 및 대상 브랜치(이름 또는 패턴별) 목록입니다. |
| `access_tokens`   | 배열   | 거짓    | 정책을 우회하는 액세스 토큰 ID 목록입니다.                                |
| `service_accounts`| 배열   | 거짓    | 정책을 우회하는 서비스 계정 ID 목록입니다.                             |
| `users`           | 배열   | 거짓    | 정책을 우회할 수 있는 사용자 ID 목록입니다.                                        |
| `groups`          | 배열   | 거짓    | 정책을 우회할 수 있는 그룹 ID 목록입니다.                                       |
| `roles`           | 배열   | 거짓    | 정책을 우회할 수 있는 기본 역할 목록입니다.                                   |
| `custom_roles`    | 배열   | 거짓    | 정책을 우회할 수 있는 사용자 지정 역할 ID 목록입니다.                                 |

### 소스 브랜치 예외 {#source-branch-exceptions}

{{< history >}}

- GitLab 18.2에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/18113) 되었으며 [플래그](../../../administration/feature_flags/_index.md) `approval_policy_branch_exceptions`라는 이름입니다. 기본적으로 활성화됨
- [GitLab 18.3에서 일반 공급](https://gitlab.com/gitlab-org/gitlab/-/issues/543778). 기능 플래그 `approval_policy_branch_exceptions`이 제거되었습니다.

{{< /history >}}

브랜치 기반 예외를 사용하면 특정 소스 및 대상 브랜치 조합에 대한 승인 요구 사항을 자동으로 제거하도록 머지 리퀘스트 승인 정책을 구성할 수 있습니다. 이를 통해 기능-메인 같은 특정 병합 유형에 대해 보안 거버넌스를 유지하고 엄격한 승인 규칙을 유지하면서 릴리스-메인 같은 다른 병합 유형에 대해서는 더 많은 유연성을 허용할 수 있습니다. 우회 이벤트는 보안 정책 프로젝트의 감사 이벤트로 기록됩니다.

| 필드   | 형식   | 필수 | 가능한 값 | 설명 |
|---------|--------|----------|-----------------|-------------|
| `source`| 개체 | 거짓    | `name` (문자열) 또는 `pattern` (문자열) | 소스 브랜치 예외입니다. 정확한 이름 또는 패턴을 지정합니다.         |
| `target`| 개체 | 거짓    | `name` (문자열) 또는 `pattern` (문자열) | 대상 브랜치 예외입니다. 정확한 이름 또는 패턴을 지정합니다.         |

### 액세스 토큰 및 서비스 계정 예외 {#access-token-and-service-account-exceptions}

{{< history >}}

- GitLab 18.2에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/18112) 되었으며 [플래그](../../../administration/feature_flags/_index.md) `security_policies_bypass_options_tokens_accounts`라는 이름입니다. 기본적으로 활성화됨
- [GitLab 18.3에서 일반 공급](https://gitlab.com/gitlab-org/gitlab/-/issues/551129). 기능 플래그 `security_policies_bypass_options_tokens_accounts`이 제거되었습니다.

{{< /history >}}

액세스 토큰 및 서비스 계정 예외를 사용하면 필요할 때 머지 리퀘스트 승인 정책에 의해 적용되는 브랜치 보호를 우회할 수 있는 특정 서비스 계정 및 액세스 토큰을 지정할 수 있습니다. 이 접근 방식을 통해 신뢰할 수 있는 자동화가 수동 승인 없이 작동하도록 하면서 인간 사용자에 대한 제한을 유지할 수 있습니다. 예를 들어, 신뢰할 수 있는 자동화에는 CI/CD 파이프라인, 리포지토리 미러링 및 자동 업데이트가 포함될 수 있습니다. 우회 이벤트는 보안 정책 프로젝트의 감사 이벤트로 기록됩니다.

| 필드 | 형식    | 필수 | 설명                                    |
|-------|---------|----------|------------------------------------------------|
| `id`  | 정수 | 참     | 액세스 토큰 또는 서비스 계정의 ID입니다. |

### 사용자가 보안 정책을 우회하도록 허용 {#allowing-users-to-bypass-security-policies}

{{< history >}}

- `security_policies_bypass_options_group_roles`라는 이름의 [기능 플래그](../../../administration/feature_flags/_index.md)와 함께 GitLab 18.5에 [도입됨](https://gitlab.com/groups/gitlab-org/-/epics/18114). 기본적으로 활성화됩니다.
- [GitLab 18.6에서 일반 공급](https://gitlab.com/gitlab-org/gitlab/-/issues/551920). 기능 플래그 `security_policies_bypass_options_group_roles`이 제거되었습니다.

{{< /history >}}

특정 사용자, 그룹, 역할 또는 사용자 지정 역할을 지정하여 머지 리퀘스트 승인 정책을 우회할 수 있도록 긴급 상황에 대비할 수 있습니다. 이 기능은 긴급 대응 및 거버넌스 제어 유지에 대한 유연성을 제공합니다. 사용자, 그룹, 역할 또는 사용자 지정 역할이 보안 정책을 우회할 수 있도록 하려면 예외를 부여합니다. 우회 이벤트는 보안 정책 프로젝트의 감사 이벤트로 기록됩니다.

이러한 예외를 가진 사용자는 두 가지 수준에서 우회할 수 있습니다:

- 머지 리퀘스트 승인 요구 사항: 사용자는 머지 리퀘스트 UI에서 이유를 제공하여 승인 요구 사항을 우회할 수 있습니다.
- 브랜치 보호: 사용자는 [`security_policy.bypass_reason` Git 푸시 옵션](../../../topics/git/commit.md#push-options-for-security-policy)에서 이유를 제공하여 머지 리퀘스트 승인 정책의 푸시 보호가 있는 브랜치에 직접 푸시할 수 있습니다.

> [!note]
> `security_policy.bypass_reason` 푸시 옵션은 [`approval_settings`](merge_request_approval_policies.md#approval_settings)로 구성된 머지 리퀘스트 승인 정책의 푸시 보호가 있는 브랜치에서만 작동합니다. 머지 리퀘스트 승인 정책에 포함되지 않는 보호된 브랜치로의 푸시는 이 옵션으로 우회할 수 없습니다.

#### YAML 예제 {#example-yaml}

```yaml
bypass_settings:
  access_tokens:
    - id: 123
    - id: 456
  service_accounts:
    - id: 789
    - id: 1011
  users:
    - id: 123
    - id: 456
  groups:
    - id: 789
    - id: 1011
  roles:
    - maintainer
    - developer
  custom_roles:
    - id: 789
    - id: 1011
```

## 보안 정책 프로젝트의 `policy.yml` 예제 {#example-policyyml-in-a-security-policy-project}

이 예를 `.gitlab/security-policies/policy.yml` 파일에 사용할 수 있습니다. [보안 정책 프로젝트](enforcement/security_policy_projects.md)에 저장되어 있습니다:

```yaml
---
approval_policy:
- name: critical vulnerability CS approvals
  description: critical severity level only for container scanning
  enabled: true
  rules:
  - type: scan_finding
    branches:
    - main
    scanners:
    - container_scanning
    vulnerabilities_allowed: 0
    severity_levels:
    - critical
    vulnerability_states: []
    vulnerability_attributes:
      false_positive: true
      fix_available: true
  actions:
  - type: require_approval
    approvals_required: 1
    user_approvers:
    - adalberto.dare
- name: secondary CS approvals
  description: secondary only for container scanning
  enabled: true
  rules:
  - type: scan_finding
    branches:
    - main
    scanners:
    - container_scanning
    vulnerabilities_allowed: 1
    severity_levels:
    - low
    - unknown
    vulnerability_states:
    - detected
    vulnerability_age:
      operator: greater_than
      value: 30
      interval: day
  actions:
  - type: require_approval
    approvals_required: 1
    role_approvers:
    - owner
    - 1002816 # Example custom role identifier called "AppSec Engineer"
- name: critical vulnerability CS approvals
  description: high/critical severity level only for SAST scanning
  enabled: true
  enforcement_type: warn
  rules:
  - type: scan_finding
    branch_type: default
    scanners:
    - sast
    vulnerabilities_allowed: 0
    severity_levels:
    - critical
    - high
    vulnerability_states: []
  actions:
  - type: require_approval
    approvals_required: 1
    role_approvers:
    - maintainer
```

이 예에서:

- 컨테이너 검사에서 식별한 새로운 `critical` 취약성을 포함하는 모든 MR은 `alberto.dare`로부터 한 번의 승인이 필요합니다.
- 컨테이너 검사에서 식별한 30일 이상 된 사전 존재하는 `low` 또는 `unknown` 취약성을 하나 이상 포함하는 모든 머지 리퀘스트는 소유자 역할을 가진 프로젝트 멤버 또는 사용자 지정 역할 `AppSec Engineer`(을)를 가진 사용자로부터 한 번의 승인이 필요합니다.
- SAST 검사에서 식별한 새로운 `critical` 또는 `high` 심각도 취약성을 포함하는 모든 머지 리퀘스트는 경고 모드 정책을 트리거합니다. 경고 모드는 봇 댓글을 생성하고 머지 리퀘스트를 차단합니다. 그러면 개발자가 정책 위반을 우회할 수 있습니다. 선택적으로 유지 관리자도 머지 리퀘스트를 승인할 수 있습니다.

## 머지 리퀘스트 승인 정책 편집기의 예 {#example-for-merge-request-approval-policy-editor}

이 예를 [머지 리퀘스트 승인 정책 편집기](#merge-request-approval-policy-editor)의 YAML 모드에서 사용할 수 있습니다. 이전 예제의 단일 개체에 해당합니다:

```yaml
type: approval_policy
name: critical vulnerability CS approvals
description: critical severity level only for container scanning
enabled: true
rules:
- type: scan_finding
  branches:
  - main
  scanners:
  - container_scanning
  vulnerabilities_allowed: 1
  severity_levels:
  - critical
  vulnerability_states: []
actions:
- type: require_approval
  approvals_required: 1
  user_approvers:
  - adalberto.dare
```

## 머지 리퀘스트 승인 정책 승인 이해 {#understanding-merge-request-approval-policy-approvals}

{{< history >}}

- `scan_finding`의 브랜치 비교 로직이 GitLab 16.8에서 [변경됨](https://gitlab.com/gitlab-org/gitlab/-/issues/428518) [플래그 포함](../../../administration/feature_flags/_index.md) `scan_result_policy_merge_base_pipeline`. 기본적으로 비활성화되어 있습니다.
- GitLab 16.9에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/435297)합니다. 기능 플래그 `scan_result_policy_merge_base_pipeline`이 제거되었습니다.

{{< /history >}}

### 머지 리퀘스트 승인 정책 비교의 범위 {#scope-of-merge-request-approval-policy-comparison}

- 머지 리퀘스트에서 승인이 필요한 경우를 결정하기 위해 GitLab은 소스 및 대상 브랜치에 대해 지원되는 각 파이프라인 소스의 완료된 파이프라인을 비교합니다(예: `feature`/`main`). 이는 검사 결과의 가장 포괄적인 평가를 보장합니다.
- 소스 브랜치의 경우, 비교 파이프라인은 소스 브랜치의 최신 커밋에 대해 지원되는 각 파이프라인 소스의 모든 완료된 파이프라인입니다.
- 머지 리퀘스트 승인 정책이 새로 감지된 상태(`new_needs_triage` & `new_dismissed`)만 찾는 경우, 비교는 소스 브랜치와 대상 브랜치 간의 공통 상위 항목에 있는 지원되는 모든 파이프라인 소스에 대해 수행됩니다. 병합 결과 파이프라인을 사용할 때 예외적으로 비교가 MR의 대상 브랜치의 끝에 대해 수행됩니다.
- 머지 리퀘스트 승인 정책이 사전 존재하는 상태(`detected`, `confirmed`, `resolved`, `dismissed`)를 찾는 경우, 비교는 항상 기본 브랜치의 끝에 대해 수행됩니다(예: `main`).
- 머지 리퀘스트 승인 정책이 새 및 사전 존재하는 취약성 상태의 조합을 찾는 경우, 비교는 소스 및 대상 브랜치의 공통 상위 항목에 대해 수행됩니다.
- 머지 리퀘스트 승인 정책은 [`CI_PIPELINE_SOURCE` 변수](../../../ci/variables/predefined_variables.md)를 기반으로 지원되는 모든 파이프라인 소스를 고려하여 머지 리퀘스트에 승인이 필요한지 결정할 때 소스 및 대상 브랜치에서 결과를 비교합니다. 소스가 `webide`인 파이프라인은 지원되지 않습니다.
- GitLab 16.11 이상에서는 선택한 각 파이프라인의 하위 파이프라인도 비교를 위해 고려됩니다.

### 위험을 받아들이고 향후 머지 리퀘스트에서 취약성 무시 {#accepting-risk-and-ignoring-vulnerabilities-in-future-merge-requests}

새로 감지된 검사 결과(`new_needs_triage` 또는 `new_dismissed` 상태)로 범위가 지정된 머지 리퀘스트 승인 정책의 경우, 이 취약성 상태의 의미를 이해하는 것이 중요합니다. 검사 결과가 머지 리퀘스트의 브랜치에는 존재하지만 대상 브랜치에는 없으면 새로 감지된 것으로 간주됩니다. 새로 감지된 검사 결과가 포함된 브랜치가 있는 머지 리퀘스트가 승인되고 병합되면 승인자는 해당 취약성의 "위험을 수용"합니다. 동일한 취약성 중 하나 이상이 이 시간 이후에 감지되면 상태는 `detected`이 되며, `new_needs_triage` 또는 `new_dismissed` 검사 결과를 고려하도록 구성된 정책에 의해 무시됩니다. 예를 들어:

- 중요한 SAST 검사 결과를 차단하기 위한 머지 리퀘스트 승인 정책이 생성됩니다. CVE-1234에 대한 SAST 검사 결과가 승인되면 동일한 위반이 있는 향후 머지 리퀘스트는 프로젝트에서 승인이 필요하지 않습니다.

`new_needs_triage` 및 `new_dismissed` 취약성 상태를 사용할 때, 정책은 새로운 취약성이고 아직 심사되지 않은 경우 정책 규칙과 일치하는 모든 검사 결과에 대해 MR을 차단합니다(거부된 경우에도). 머지 리퀘스트 내에서 새로 감지되고 거부된 취약성을 무시하려면 `new_needs_triage` 상태만 사용할 수 있습니다.

라이선스 승인 정책을 사용할 때는 평가 시 프로젝트, 구성 요소(종속성) 및 라이선스의 조합을 고려합니다. 라이선스가 예외로 승인되면 향후 머지 리퀘스트는 동일한 프로젝트, 구성 요소(종속성) 및 라이선스의 조합에 대해 승인이 필요하지 않습니다. 이 경우 구성 요소의 버전은 고려되지 않습니다. 이전에 승인된 패키지가 새 버전으로 업데이트되면 승인자가 다시 승인할 필요가 없습니다. 예를 들어:

- `AGPL-1.0`과(와) 일치하는 새로 감지된 라이선스가 있는 머지 리퀨스트를 차단하기 위한 라이선스 승인 정책이 생성됩니다. 프로젝트 `demo`에서 구성 요소 `osframework`에 대한 변경이 정책을 위반합니다. 승인되고 병합되면, 향후 프로젝트 `demo`의 `osframework`에 대한 머지 리퀘스트가 라이선스 `AGPL-1.0`(으)로 승인이 필요하지 않습니다.

### 추가 승인 {#additional-approvals}

머지 리퀘스트 승인 정책은 특정 상황에서 추가 승인 단계를 필요로 합니다. 예를 들어:

- 작동 브랜치의 보안 작업 수가 감소되고 더 이상 대상 브랜치의 보안 작업 수와 일치하지 않습니다. 사용자는 CI/CD 구성에서 검사 작업을 제거하여 스캔 결과 정책을 건너뛸 수 없습니다. 머지 리퀘스트 승인 정책 규칙에 구성된 보안 검사만 제거되는지 확인합니다.

  예를 들어, 기본 브랜치 파이프라인에 4개의 보안 검사가 있는 상황을 고려하세요: `sast`, `secret_detection`, `container_scanning` 및 `dependency_scanning`. 머지 리퀘스트 승인 정책은 2개의 스캐너(`container_scanning` 및 `dependency_scanning`)를 적용합니다. MR이 머지 리퀘스트 승인 정책에 구성된 검사를 제거하는 경우(예: `container_scanning`), 추가 승인이 필요합니다.
- 누군가 파이프라인 보안 작업을 중지하고 사용자는 보안 검사를 건너뛸 수 없습니다.
- 머지 리퀘스트의 작업이 실패하고 `allow_failure: false`(으)로 구성됩니다. 결과적으로 파이프라인이 차단된 상태입니다.
- 파이프라인이 전체 파이프라인을 통과하기 위해 성공적으로 실행되어야 하는 수동 작업을 갖습니다.

### 승인 요구 사항을 평가하는 데 사용되는 검사 결과 관리 {#managing-scan-findings-used-to-evaluate-approval-requirements}

머지 리퀘스트 승인 정책은 파이프라인이 완료된 후 파이프라인의 스캐너에 의해 생성된 결과물 보고서를 평가합니다. 머지 리퀘스트 승인 정책은 검사 결과 검사 결과를 기반으로 결과를 평가하고 승인을 결정하여 잠재적 위험을 식별하고 머지 리퀘스트를 차단하며 승인을 요구하는 데 중점을 둡니다.

머지 리퀘스트 승인 정책은 해당 범위를 벗어나 결과물 파일이나 스캐너에 도달하지 않습니다. 대신 GitLab은 결과물 보고서의 결과를 신뢰합니다. 이는 팀이 검사 실행 및 공급망을 관리하고 필요시 검사 결과물 보고서에서 생성된 검사 결과를 사용자 지정(예: 거짓 양성 필터링)할 수 있는 유연성을 제공합니다.

예를 들어, 잠금 파일 변조는 보안 정책 관리 범위를 벗어나지만 [코드 소유자](../../project/codeowners/_index.md#codeowners-file) 또는 [외부 상태 확인](../../project/merge_requests/status_checks.md)의 사용을 통해 완화될 수 있습니다. 자세한 정보는 [이슈 433029](https://gitlab.com/gitlab-org/gitlab/-/issues/433029)를 참조하세요.

![검사 결과 검사 결과 평가](img/scan_results_evaluation_white-bg_v16_8.png)

### **Fix Available** 또는 **False Positive** 속성으로 정책 위반 필터링 {#filter-out-policy-violations-with-the-attributes-fix-available-or-false-positive}

불필요한 승인 요구 사항을 방지하기 위해 이러한 추가 필터는 가장 실행 가능한 검사 결과에서만 MR을 차단하도록 하는 데 도움이 됩니다.

`fix_available`을 YAML에서 `false`(으)로 설정하거나 정책 편집기에서 **은 아님** 및 **Fix Available**을 설정하면 검사 결과에 사용 가능한 해결책 또는 수정이 있을 때 정책 위반으로 간주되지 않습니다. 해결 방법이 **해결 방법** 제목 아래의 취약성 개체 맨 아래에 나타납니다. 수정 사항이 취약성 개체 내에 **Resolve with Merge Request** 버튼으로 나타납니다.

**Resolve with Merge Request** 버튼은 다음 조건 중 하나가 충족될 때만 나타납니다:

1. SAST 취약성이 GitLab Duo Enterprise가 있는 Ultimate 티어의 프로젝트에서 발견됩니다.
1. 컨테이너 검사 취약성이 `GIT_STRATEGY: fetch`이(가) 설정된 작업에서 Ultimate 티어의 프로젝트에서 발견됩니다. 또한 취약성은 컨테이너 이미지에 대해 활성화된 리포지토리에 사용 가능한 수정이 포함된 패키지를 가져야 합니다.
1. 종속성 검사 취약성이 yarn에서 관리되고 수정이 가능한 Node.js 프로젝트에서 발견됩니다. 또한 프로젝트는 Ultimate 티어에 있어야 하고 인스턴스에 대해 FIPS 모드가 비활성화되어야 합니다.

**Fix Available**은 종속성 검사 및 컨테이너 검사에만 적용됩니다.

**False Positive** 속성을 사용하면 마찬가지로 `false_positive`을 `false`(으)로 설정하여 정책에서 감지한 검사 결과를 무시할 수 있습니다(또는 정책 편집기에서 특성을 **아님** 및 **False Positive**으로 설정).

**False Positive** 속성은 취약성 추출 도구에서 감지한 SAST 결과에만 적용됩니다.

### 정책 평가 및 취약성 상태 변경 {#policy-evaluation-and-vulnerability-state-changes}

사용자가 취약성의 상태를 변경하면(예: 취약성 세부 정보 페이지에서 취약성을 거부), GitLab은 성능상의 이유로 머지 리퀘스트 승인 정책을 자동으로 다시 평가하지 않습니다. 취약성 보고서에서 업데이트된 데이터를 검색하려면 머지 리퀘스트를 업데이트하거나 관련 파이프라인을 다시 실행하세요.

이 동작은 최적의 시스템 성능을 보장하고 보안 정책 적용을 유지합니다. 정책 평가는 다음 파이프라인 실행 중에 또는 머지 리퀘스트가 업데이트될 때 수행되지만 취약성 상태가 변경될 때 즉시 수행되지 않습니다.

취약성 상태 변경을 정책에 즉시 반영하려면 파이프라인을 수동으로 실행하거나 머지 리퀘스트에 새 커밋을 푸시합니다.

## 보안 위젯 및 정책 봇 불일치 이해 {#understanding-security-widget-and-policy-bot-discrepancies}

머지 리퀘스트 보안 위젯이 표시하는 내용과 보안 봇 댓글이 취약성과 관련하여 나타내는 내용 간에 불일치를 알 수 있습니다. 이러한 기능은 보안 검사 결과에 대해 다양한 데이터 소스와 비교 방법을 사용하므로 표시되는 내용에 차이가 있을 수 있습니다.

데이터 소스:

- **Merge request security widget**: 최신 소스 브랜치 파이프라인의 결과를 기본 브랜치에 대해 이전에 데이터베이스에 저장된 취약성과 비교합니다.
- **Security Bot (and approval policy logic)**: 실제 파이프라인 결과물 간의 결과를 비교합니다. 특히 최신 성공적인 대상 브랜치 파이프라인과 최신 성공적인 소스 브랜치 파이프라인 간에 비교합니다.

### 불일치가 발생하는 일반적인 시나리오 {#common-scenarios-where-inconsistencies-occur}

데이터 소스의 차이는 여러 시나리오에서 불일치하는 동작을 유발할 수 있습니다.

#### 대상 브랜치에서 보안 검사 누락 또는 실패 {#missing-or-failed-security-scans-in-target-branch}

대상 브랜치의 최신 파이프라인이 보안 검사를 제대로 실행하지 못할 때(예: 구성 오류 또는 작업 실패로 인해), 보안 봇이 새로운 검사 결과를 보고하고 결과를 효과적으로 비교할 수 없기 때문에 예방 조치로 승인이 필요할 수 있습니다. 한편, 보안 위젯은 이전에 저장된 취약성 데이터를 사용하기 때문에 새로운 취약성을 표시하지 않을 수 있습니다.

#### 비교 사이의 대상 브랜치 변경 {#changes-in-target-branch-between-comparisons}

위젯이 비교를 수행하는 시점과 봇이 비교를 수행하는 시점 사이에 대상 브랜치의 보안 프로필을 변경하는 여러 커밋이 있으면 결과가 다를 수 있습니다.

### 일관된 결과를 위한 모범 사례 {#best-practices-for-consistent-results}

이러한 보안 기능을 사용할 때 혼동을 최소화하려면:

- 완전한 파이프라인 실행 보장: 보안 검사가 소스 및 대상 브랜치 모두에서 성공적으로 완료되는지 확인합니다.
- 일관된 CI/CD 구성 유지: 파이프라인에서 보안 검사 구성을 제거하거나 중단하지 마세요.
- 새 프로젝트의 경우: 머지 리퀘스트를 생성하기 전에 기본 브랜치에서 보안 검사를 실행하여 기본 취약성 데이터를 설정합니다.
- 검사 실행 정책 사용 고려: 머지 리퀘스트 승인 정책과 결합하면 보안 검사가 항상 필요한 곳에서 실행되도록 하는 데 도움이 됩니다.

## 문제 해결 {#troubleshooting}

### 머지 리퀘스트 규칙 위젯이 머지 리퀘스트 승인 정책이 유효하지 않거나 중복되었다고 표시 {#merge-request-rules-widget-shows-a-merge-request-approval-policy-is-invalid-or-duplicated}

{{< details >}}

- 계층: Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab Self-Managed 15.0~16.4에서 가장 가능성 높은 원인은 프로젝트가 한 그룹에서 내보내졌고 다른 그룹으로 가져왔으며 머지 리퀘스트 승인 정책 규칙이 있다는 것입니다. 이러한 규칙은 내보낸 프로젝트와는 별개의 프로젝트에 저장됩니다. 결과적으로 프로젝트는 가져온 프로젝트의 그룹에 없는 엔터티를 참조하는 정책 규칙을 포함합니다. 결과는 유효하지 않거나 중복되거나 둘 다인 정책 규칙입니다.

GitLab 인스턴스에서 모든 유효하지 않은 머지 리퀘스트 승인 정책 규칙을 제거하려면 관리자가 [Rails 콘솔](../../../administration/operations/rails_console.md)에서 다음 스크립트를 실행할 수 있습니다.

```ruby
Project.joins(:approval_rules).where(approval_rules: { report_type: %i[scan_finding license_scanning] }).where.not(approval_rules: { security_orchestration_policy_configuration_id: nil }).find_in_batches.flat_map do |batch|
  batch.map do |project|
    # Get projects and their configuration_ids for applicable project rules
    [project, project.approval_rules.where(report_type: %i[scan_finding license_scanning]).pluck(:security_orchestration_policy_configuration_id).uniq]
  end.uniq.map do |project, configuration_ids| # Take only unique combinations of project + configuration_ids
    # If you find more configurations than what is available for the project, take records with the extra configurations
    [project, configuration_ids - project.all_security_orchestration_policy_configurations.pluck(:id)]
  end.select { |_project, configuration_ids| configuration_ids.any? }
end.each do |project, configuration_ids|
  # For each found pair project + ghost configuration, remove these rules for a given project
  Security::OrchestrationPolicyConfiguration.where(id: configuration_ids).each do |configuration|
    configuration.delete_scan_finding_rules_for_project(project.id)
  end
  # Ensure you sync any potential rules from new group's policy
  Security::ScanResultPolicies::SyncProjectWorker.perform_async(project.id)
end
```

### 새로 감지된 CVE {#newly-detected-cves}

`new_needs_triage` 및 `new_dismissed`을(를) 사용할 때, 일부 검사 결과는 머지 리퀘스트에 의해 도입되지 않은 경우 승인이 필요할 수 있습니다(예: 관련 종속성의 새로운 CVE). 이러한 검사 결과는 MR 위젯 내에는 없지만 정책 봇 댓글 및 파이프라인 보고서에서 강조 표시됩니다.

### `policy.yml`이(가) 수동으로 무효화된 후 정책이 여전히 적용됨 {#policies-still-have-effect-after-policyyml-was-manually-invalidated}

GitLab 17.2 이전에서는 `policy.yml` 파일에 정의된 정책이 실행될 수 있습니다. 파일이 수동으로 편집되었고 더 이상 [정책 스키마](#merge-request-approval-policies-schema)에 대해 유효하지 않은 경우에도 적용됩니다. 이 문제는 정책 동기화 로직의 버그로 인해 발생합니다.

가능한 증상:

- `approval_settings`은 브랜치 보호 제거, 강제 푸시 차단 또는 기타 방식으로 열린 머지 리퀘스트에 영향을 미칩니다.
- `any_merge_request` 정책은 열린 머지 리퀘스트에 계속 적용됩니다.

이를 해결하려면 다음을 수행할 수 있습니다:

- `policy.yml` 파일을 수동으로 편집하여 정책이 유효해지도록 합니다.
- `policy.yml` 파일이 저장된 보안 정책 프로젝트를 할당 해제한 후 다시 할당합니다.

### 보안 검사 누락 {#missing-security-scans}

머지 리퀘스트 승인 정책을 사용할 때 새 프로젝트나 특정 보안 검사가 실행되지 않는 경우를 포함하여 머지 리퀘스트가 차단되는 상황이 발생할 수 있습니다. 이 동작은 취약성이 시스템에 도입될 위험을 줄이기 위해 의도된 것입니다.

예제 시나리오:

- 소스 브랜치에서 검사 누락

  소스 브랜치에서 보안 검사가 누락된 경우 GitLab은 머지 리퀘스트가 새로운 취약성을 도입하는지 여부를 효과적으로 평가할 수 없습니다. 이러한 경우 승인이 예방 조치로 필요합니다.

- 대상 브랜치에서 검사 누락

  대상 브랜치에서 보안 검사가 누락된 경우 GitLab은 소스 브랜치에서 감지된 취약성을 효과적으로 비교할 수 없습니다. 이러한 경우 감지된 모든 취약성은 새로운 것으로 보고됩니다.

- 검사할 파일이 없는 프로젝트

  선택한 보안 검사와 관련된 파일이 없는 프로젝트에서도 승인 요구 사항이 여전히 적용됩니다. 이는 모든 프로젝트에서 일관된 보안 관행을 유지합니다.

- 첫 번째 머지 리퀘스트

  새 프로젝트의 첫 번째 머지 리퀘스트는 소스 브랜치에 취약성이 없더라도 기본 브랜치에 보안 검사가 없으면 차단될 수 있습니다.

이러한 문제를 해결하려면:

- 필수 보안 검사가 소스 및 대상 브랜치 모두에서 구성되고 성공적으로 실행되는지 확인합니다.
- 새 프로젝트의 경우 머지 리퀘스트를 생성하기 전에 기본 브랜치에 필수 보안 검사를 설정하고 실행합니다.
- 검사 실행 정책 또는 파이프라인 실행 정책을 사용하여 모든 브랜치에서 보안 검사의 일관된 실행을 보장하는 것을 고려하세요.
- [`fallback_behavior`](#fallback_behavior)을(를) `open`과(과) 함께 사용하여 정책의 유효하지 않거나 적용할 수 없는 규칙이 승인이 필요하지 않도록 하는 것을 고려하세요.
- [`policy tuning`](#policy_tuning) 설정 `unblock_rules_using_execution_policies`을(를) 사용하여 보안 검사 결과물이 누락되고 검사 실행 정책이 적용되는 시나리오를 처리하는 것을 고려하세요. 활성화되면 이 설정은 소스 브랜치에서 검사 결과물이 누락되고 검사 실행 정책에 의해 검사가 필요한 경우 승인 규칙을 선택 사항으로 만듭니다. 이 기능은 일치하는 스캐너가 있는 기존 검사 실행 정책에서만 작동합니다. 누락된 결과물로 인해 특정 보안 검사를 수행할 수 없는 경우 머지 리퀨스트 프로세스에서 유연성을 제공합니다.

### `Target: none` 보안 봇 댓글 {#target-none-in-security-bot-comments}

보안 봇 댓글에서 `Target: none`을(를) 보면 GitLab이 대상 브랜치에 대한 보안 보고서를 찾을 수 없다는 의미입니다. 이 문제를 해결하려면:

1. 필수 보안 스캐너를 포함하는 대상 브랜치에서 파이프라인을 실행합니다.
1. 파이프라인이 성공적으로 완료되고 보안 보고서를 생성하는지 확인합니다.
1. 소스 브랜치에서 파이프라인을 다시 실행합니다. 새 커밋을 생성하면 파이프라인이 다시 실행됩니다.

#### 보안 봇 메시지 {#security-bot-messages}

대상 브랜치에 보안 검사가 없는 경우:

- 보안 봇이 소스 브랜치에서 발견된 모든 취약성을 나열할 수 있습니다.
- 일부 취약성은 대상 브랜치에 이미 존재할 수 있지만, 대상 브랜치 검사 없이 GitLab은 어떤 것이 새로운지 결정할 수 없습니다.

가능한 해결 방법:

1. **Manual approvals**: 보안 검사가 설정될 때까지 새 프로젝트에 대해 머지 리퀘스트를 수동으로 일시적으로 승인합니다.
1. **Targeted policies**: 새 프로젝트에 대해 다른 승인 요구 사항이 있는 별도의 정책을 생성합니다.
1. **대체(Fallback) 동작**: 새 프로젝트의 정책에 `fail: open`을(를) 사용하는 것을 고려하되, 이로 인해 검사가 실패해도 사용자가 취약성을 병합할 수 있다는 점에 주의하세요.

### 머지 리퀘스트 승인 정책 디버깅 지원 요청 {#support-request-for-debugging-of-merge-request-approval-policy}

GitLab.com 사용자는 "머지 리퀘스트 승인 정책 디버깅" 제목으로 [지원 티켓](https://support.gitlab.com/)을 제출할 수 있습니다. 다음 세부 정보를 제공하세요:

- 그룹 경로, 프로젝트 경로 및 선택적으로 머지 리퀘스트 ID
- 심각도
- 현재 동작
- 예상 동작

#### GitLab.com {#gitlabcom}

지원 팀은 [로그](https://log.gprd.gitlab.net/)(`pubsub-sidekiq-inf-gprd*`)를 조사하여 실패 `reason`을(를) 식별합니다. 다음은 로그의 예제 응답 스니펫입니다. 이 쿼리를 사용하여 승인과 관련된 로그를 찾을 수 있습니다: `json.event.keyword: "update_approvals"` 및 `json.project_path: "group-path/project-path"`. 선택적으로 `json.merge_request_iid`을(를) 사용하여 머지 리퀨스트 식별자로 추가로 필터링할 수 있습니다:

```json
"json": {
  "project_path": "group-path/project-path",
  "merge_request_iid": 2,
  "missing_scans": [
    "api_fuzzing"
  ],
  "reason": "Scanner removed by MR",
  "event": "update_approvals",
}
```

#### GitLab Self-Managed {#gitlab-self-managed}

`project-path`, `api_fuzzing` 및 `merge_request`과(같은 키워드를 검색합니다. 예: `grep group-path/project-path` 및 `grep merge_request`. 상관 ID를 알고 있으면 상관 ID로 검색할 수 있습니다. 예를 들어 `correlation_id`의 값이 01HWN2NFABCEDFG인 경우 `01HWN2NFABCEDFG`을(를) 검색합니다. 다음 파일에서 검색하세요:

- `/gitlab/gitlab-rails/production_json.log`
- `/gitlab/sidekiq/current`

일반적인 실패 이유:

- MR에 의해 제거된 스캐너: 머지 리퀨스트 승인 정책은 정책에 정의된 스캐너가 존재하고 비교를 위해 결과물을 성공적으로 생성하기를 기대합니다.

### 머지 리퀘스트 승인 정책에서 불일치하는 승인 {#inconsistent-approvals-from-merge-request-approval-policies}

머지 리퀨스트 승인 규칙에 불일치가 발견되면 정책을 다시 동기화하기 위해 다음 단계 중 하나를 수행할 수 있습니다:

- [`resyncSecurityPolicies` GraphQL 뮤테이션](_index.md#resynchronize-policies-with-the-graphql-api)을(를) 사용하여 정책을 다시 동기화합니다.
- 보안 정책 프로젝트를 영향을 받는 그룹 또는 프로젝트에 할당 해제한 후 다시 할당합니다.
- 또는 정책을 업데이트하여 영향을 받는 그룹 또는 프로젝트에 대한 정책을 다시 동기화하도록 트리거할 수 있습니다.
- 보안 정책 프로젝트의 YAML 파일 구문이 유효한지 확인합니다.

이러한 작업은 머지 리퀨스트 승인 정책이 올바르게 적용되고 모든 머지 리퀻스트에 일관성 있게 유지되도록 하는 데 도움이 됩니다.

이러한 단계를 수행한 후 머지 리퀨스트 승인 정책에 문제가 계속 발생하면 GitLab 지원에 문의하여 도움을 받으세요.

### 감지된 취약성을 수정하는 머지 리퀨스트는 승인 필요 {#merge-requests-that-fix-a-detected-vulnerability-require-approval}

정책 구성에 `detected` 상태가 포함된 경우, 이전에 감지된 취약성을 수정하는 머지 리퀨스트는 여전히 승인이 필요합니다. 머지 리퀻스트 승인 정책은 머지 리퀻스트의 변경 사항 이전에 존재했던 취약성을 기반으로 평가하므로 알려진 취약성에 영향을 미치는 모든 변경 사항에 대한 추가 검토 계층을 추가합니다.

취약성을 수정하는 머지 리퀻스트가 감지된 취약성으로 인한 추가 승인 없이 진행되도록 하려면 정책 구성에서 `detected` 상태를 제거하는 것을 고려하세요.

### 병합 결과 파이프라인과 브랜치 파이프라인 간의 불일치하는 정책 평가 {#inconsistent-policy-evaluation-between-merged-results-pipelines-and-branch-pipelines}

프로젝트가 [병합 결과 파이프라인](../../../ci/pipelines/merged_results_pipelines.md)을 활성화하고 보안 검사가 있는 브랜치 파이프라인도 실행하는 경우, 다양한 파이프라인에서 머지 리퀨스트 승인 정책이 평가되는 방식에 불일치를 경험할 수 있습니다. 다음 예를 고려하세요:

1. 병합 결과 파이프라인과 브랜치 파이프라인 모두 동일한 머지 리퀨스트에 대해 보안 검사를 실행합니다.
1. 브랜치 파이프라인이 병합 결과 파이프라인 이후에 완료됩니다.
1. 정책 평가는 병합 결과 파이프라인 대신 비교를 위해 브랜치 파이프라인을 선택합니다.

머지 리퀨스트 승인 정책은 최신 커밋의 완료된 파이프라인을 평가하며, 마지막에 완료되는 파이프라인이 비교를 위해 선택됩니다. 브랜치 파이프라인이 병합 결과 파이프라인 이후에 완료되면 정책은 평가를 위해 브랜치 파이프라인을 사용합니다.

이 문제를 방지하려면:

- 병합 결과 파이프라인에서만 보안 검사 실행: 병합 결과 파이프라인이 활성화된 경우 보안 검사 작업이 머지 리퀨스트 파이프라인에서만 실행되도록 구성합니다. [`rules`](../../../ci/jobs/job_rules.md)을(를) 사용하여 보안 작업이 실행되는 시기를 제어합니다:

  ```yaml
  sast:
    rules:
      - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  ```

- 중복 파이프라인 방지: [중복 파이프라인 방지](../../../ci/jobs/job_rules.md#avoid-duplicate-pipelines) 안내를 따라 커밋 당 보안 검사가 파이프라인 유형 중 하나에서만 실행되도록 합니다.
- 일관된 스캐너 구성 사용: 소스 및 대상 브랜치에 대해 동일한 파이프라인 유형으로 동일한 스캐너를 실행합니다.

중복 파이프라인에 대한 자세한 정보는 [브랜치에 푸시할 때 두 파이프라인](../../../ci/pipelines/mr_pipeline_troubleshooting.md#two-pipelines-when-pushing-to-a-branch)을(를) 참조하세요.
