---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 검사 실행 정책
---

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- 스캔 실행 정책 편집기에서 사용자 지정 CI/CD 변수 지원 [GitLab 16.2에서 도입됨](https://gitlab.com/groups/gitlab-org/-/epics/9566).
- 기존 GitLab CI/CD 구성이 있는 프로젝트에 검사 실행 정책 적용 [GitLab 16.2에서 도입됨](https://gitlab.com/groups/gitlab-org/-/epics/6880) [플래그 포함](../../../administration/feature_flags/_index.md) `scan_execution_policy_pipelines`. 기능 플래그 `scan_execution_policy_pipelines`은 GitLab 16.5에서 제거되었습니다.
- 스캔 실행 정책에서 사전 정의된 변수 재정의 [GitLab 16.10에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/440855) [플래그 포함](../../../administration/feature_flags/_index.md) `allow_restricted_variables_at_policy_level`. 기본적으로 활성화됩니다. 기능 플래그 `allow_restricted_variables_at_policy_level`은 GitLab 17.5에서 제거되었습니다.

{{< /history >}}

검사 실행 정책은 기본값 또는 최신 [보안 CI/CD 템플릿](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates/Jobs)을 기반으로 GitLab 보안 스캔을 적용합니다. 파이프라인의 일부로 또는 지정된 일정에 따라 검사 실행 정책을 배포할 수 있습니다.

검사 실행 정책은 보안 정책 프로젝트에 연결된 모든 프로젝트에서 보안 스캔을 적용합니다. `.gitlab-ci.yml` 파일이 없는 프로젝트 또는 AutoDevOps가 비활성화된 프로젝트의 경우 보안 정책이 `.gitlab-ci.yml` 파일을 암시적으로 생성합니다. `.gitlab-ci.yml` 파일은 시크릿 검색, 정적 분석 또는 프로젝트에서 빌드가 필요하지 않은 다른 스캐너를 실행하는 정책이 항상 실행되고 적용될 수 있도록 보장합니다.

검사 실행 정책과 파이프라인 실행 정책 모두 여러 프로젝트에서 GitLab 보안 스캔을 구성하여 보안 및 규정 준수를 관리할 수 있습니다. 검사 실행 정책은 구성이 더 빠르지만 사용자 지정할 수 없습니다. 다음 중 하나가 참이면 [파이프라인 실행 정책](pipeline_execution_policies.md)을 대신 사용하세요:

- 고급 구성 설정이 필요합니다.
- 사용자 지정 CI/CD 작업 또는 스크립트를 적용하려고 합니다.
- 적용된 CI/CD 작업을 통해 타사 보안 스캔을 활성화하려고 합니다.

## 검사 실행 정책 만들기 {#create-a-scan-execution-policy}

검사 실행 정책을 생성하려면 다음 리소스 중 하나를 사용할 수 있습니다:

- <i class="fa-youtube-play" aria-hidden="true"></i> 동영상 안내를 보려면 [GitLab에서 보안 스캔 정책을 설정하는 방법](https://youtu.be/ZBcqGmEwORA?si=aeT4EXtmHjosgjBY)을 참조하세요.
- <i class="fa-youtube-play" aria-hidden="true"></i> [GitLab CI/CD 구성이 없는 프로젝트에 검사 실행 정책 적용](https://www.youtube.com/watch?v=sUfwQQ4-qHs)에 대해 자세히 알아보세요.
- 검사 실행 정책을 만드는 방법은 [자습서: 검사 실행 정책 설정](../../../tutorials/scan_execution_policy/_index.md)을 참조하세요.

## 제한 사항 {#restrictions}

- 각 정책에 최대 5개의 규칙을 할당할 수 있습니다.
- 각 보안 정책 프로젝트에 최대 5개의 검사 실행 정책을 할당할 수 있습니다.
- 로컬 프로젝트 YAML 파일은 검사 실행 정책을 재정의할 수 없습니다. 검사 실행 정책은 파이프라인에 대해 정의된 모든 구성에 우선합니다. 프로젝트의 CI/CD 구성에서 같은 작업 이름을 사용하더라도 마찬가지입니다.
- 예약된 정책(`type: schedule`)은 예약된 `cadence` 에 따라서만 실행됩니다. 정책을 업데이트해도 즉시 스캔이 시작되지 않습니다.
- 정책 편집기 대신 YAML 구성 파일에 직접 만드는 정책 업데이트(커밋 또는 푸시 포함)는 시스템을 통해 전파되는 데 최대 10분이 걸릴 수 있습니다. ([이슈 512615](https://gitlab.com/gitlab-org/gitlab/-/issues/512615)에서 이 제한에 대한 제안된 변경 사항을 참조하세요.)

## 작업 스테이지 {#job-stages}

DAST 스캔은 항상 `dast` 스테이지에서 실행됩니다. `dast` 스테이지가 없으면 GitLab이 파이프라인의 끝에 `dast` 스테이지를 주입합니다.

다른 모든 스캔의 정책 작업은 파이프라인의 `test` 스테이지에서 실행됩니다. 기본 파이프라인에서 `test` 스테이지를 제거하면 작업이 대신 `scan-policies` 스테이지에서 다음 규칙에 따라 실행됩니다:

- `scan-policies` 스테이지가 아직 없으면 GitLab이 평가 시 스테이지를 CI/CD 파이프라인에 주입합니다.
- `build` 스테이지가 있으면 GitLab이 `scan-policies`을 `build` 스테이지 직후에 주입합니다.
- `build` 스테이지가 없으면 GitLab이 `scan-policies`을 파이프라인의 시작에 주입합니다.

작업 이름 충돌을 방지하려면 하이픈과 숫자가 작업 이름에 추가됩니다. 각 숫자는 각 정책 작업에 대한 고유한 값입니다. 예를 들어, `secret-detection`은 `secret-detection-1`이 됩니다.

## 검사 실행 정책 편집기 {#scan-execution-policy-editor}

{{< history >}}

- `Merge Request Security Template`:
  - GitLab 18.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/541689) 되었으며 [플래그](../../../administration/feature_flags/_index.md) `flexible_scan_execution`라는 이름입니다. 기본적으로 비활성화되어 있습니다.
  - GitLab 18.3에서 [GitLab.com, GitLab Self-Managed 및 GitLab Dedicated에서 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/541689).
  - GitLab 18.4에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/541689)합니다. 기능 플래그 `flexible_scan_execution`이 제거되었습니다.

{{< /history >}}

검사 실행 정책 편집기를 사용하여 검사 실행 정책을 만들거나 편집합니다.

전제 조건:

- 기본적으로 그룹, 서브그룹 또는 프로젝트 소유자만 보안 정책 프로젝트를 만들거나 할당하는 데 필요한 [권한](../../permissions.md#project-application-security)을 가집니다. 또는 [보안 정책 링크 관리](../../custom_roles/abilities.md#security-policy-management) 권한이 있는 사용자 지정 역할을 만들 수 있습니다.

첫 번째 검사 실행 정책을 만들 때 일반적인 사용 사례에 대해 이 템플릿 중에서 선택하세요:

- 머지 리퀘스트 보안
  - 사용 사례: 모든 커밋이 아니라 머지 리퀘스트가 생성될 때만 보안 스캔을 실행하려고 합니다.
  - 언제 사용할지: 기본 또는 보호된 브랜치를 대상으로 하는 소스 브랜치에서 보안 스캔을 실행해야 하는 머지 리퀘스트 파이프라인을 사용하는 프로젝트의 경우입니다.
  - 최고의 사용처: 머지 리퀘스트 승인 정책을 사용하여 정렬하고 모든 브랜치에서 스캔을 피함으로써 인프라 비용을 줄입니다.
  - 파이프라인 소스: 주로 머지 리퀘스트 파이프라인입니다.
- 예약된 스캔
  - 사용 사례: 코드 변경과 관계없이 일정(예: 일일 또는 주간)에 따라 보안 스캔을 자동으로 실행하려고 합니다.
  - 언제 사용할지: 개발 활동과 독립적인 정기적인 보안 스캔을 위한 경우입니다.
  - 최고의 사용처: 규정 준수 요구 사항, 기준 보안 모니터링 또는 커밋이 거의 없는 프로젝트입니다.
  - 파이프라인 소스: 예약된 파이프라인입니다.
- 릴리스 보안
  - 사용 사례: `main` 또는 릴리스 브랜치에 대한 모든 변경에 보안 스캔을 실행하려고 합니다.
  - 언제 사용할지: 릴리스 전에 포괄적인 스캔이 필요하거나 보호된 브랜치에서 필요한 프로젝트의 경우입니다.
  - 최고의 사용처: 릴리스 게이트 워크플로우, 프로덕션 배포 또는 높은 보안 환경입니다.
  - 파이프라인 소스: 보호된 브랜치, 릴리스 파이프라인으로 푸시합니다.

사용 가능한 템플릿이 요구 사항을 충족하지 않거나 더 사용자 지정된 검사 실행 정책이 필요한 경우 다음을 수행할 수 있습니다:

- **커스텀** 옵션을 선택하고 사용자 지정 요구 사항으로 자신만의 검사 실행 정책을 만듭니다.
- [파이프라인 실행 정책](pipeline_execution_policies.md)을 사용하여 보안 스캔 및 CI 적용에 더 많은 사용자 지정 옵션에 액세스하세요.

정책이 완료되면 편집기 하단에서 **머지 리퀘스트로 설정**을 선택하여 정책을 저장합니다. 프로젝트의 구성된 보안 정책 프로젝트의 머지 리퀘스트로 리디렉션됩니다. 보안 정책 프로젝트가 프로젝트에 연결되지 않으면 GitLab이 자동으로 하나를 만듭니다. 편집기 인터페이스에서 기존 정책을 제거할 수 있습니다. 편집기 하단에서 **정책 삭제**를 선택하세요. 이 작업은 `policy.yml` 파일에서 정책을 제거하는 머지 리퀘스트를 만듭니다.

대부분의 정책 변경 사항은 머지 리퀘스트가 병합된 후 즉시 적용됩니다. 머지 리퀘스트 대신 기본 브랜치에 직접 커밋된 변경 사항은 정책 변경 사항이 적용되기 전에 최대 10분이 필요합니다.

![검사 실행 정책 편집기 규칙 모드](img/scan_execution_policy_rule_mode_v17_5.png)

> [!note]
> DAST 실행 정책의 경우 규칙 모드 편집기에서 사이트 및 스캐너 프로필을 적용하는 방식은 정책이 정의된 위치에 따라 달라집니다:
>
> - 프로젝트의 정책의 경우 규칙 모드 편집기에서 프로젝트에 이미 정의된 프로필 목록에서 선택합니다.
> - 그룹의 정책의 경우 사용할 프로필의 이름을 입력해야 합니다. 파이프라인 오류를 방지하려면 일치하는 이름을 가진 프로필이 그룹의 모든 프로젝트에 존재해야 합니다.

## 검사 실행 정책 스키마 {#scan-execution-policies-schema}

검사 실행 정책이 있는 YAML 구성은 검사 실행 정책 스키마와 일치하는 개체 배열로 구성됩니다. 개체는 `scan_execution_policy` 키 아래에 중첩됩니다. `scan_execution_policy` 키 아래에서 최대 5개의 정책을 구성할 수 있습니다. 처음 5개 이후에 구성된 다른 정책은 적용되지 않습니다.

새 정책을 저장하면 GitLab이 정책의 콘텐츠를 [이 JSON 스키마](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/validators/json_schemas/security_orchestration_policy.json)에 대해 검증합니다. [JSON 스키마](https://json-schema.org/)에 익숙하지 않으면 다음 섹션과 테이블을 참고하세요.

| 필드 | 형식 | 필수 | 가능한 값 | 설명 |
|-------|------|----------|-----------------|-------------|
| `scan_execution_policy` | 검사 실행 정책의 `array` | 참 |  | 검사 실행 정책 목록(최대 5개) |

## 검사 실행 정책 스키마 {#scan-execution-policy-schema}

{{< history >}}

- 정책당 작업 제한 [GitLab 17.4에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/472213) [플래그 포함](../../../administration/feature_flags/_index.md) `scan_execution_policy_action_limit`(프로젝트의 경우) 및 `scan_execution_policy_action_limit_group`(그룹의 경우). 기본적으로 비활성화되어 있습니다.
- 정책당 작업 제한 [GitLab 18.0에서 일반적으로 제공됨](https://gitlab.com/gitlab-org/gitlab/-/issues/535605). 기능 플래그 `scan_execution_policy_action_limit`(프로젝트의 경우) 및 `scan_execution_policy_action_limit_group`(그룹의 경우)가 제거되었습니다.

{{< /history >}}

| 필드          | 형식                                         | 필수 | 설명 |
|----------------|----------------------------------------------|----------|-------------|
| `name`         | `string`                                     | 참     | 정책의 이름입니다. 최대 255자입니다. |
| `description`  | `string`                                     | 거짓    | 정책에 대한 설명입니다. |
| `enabled`      | `boolean`                                    | 참     | 정책을 활성화(`true`) 또는 비활성화(`false`)하는 플래그입니다. |
| `rules`        | 규칙의 `array`                             | 참     | 정책이 적용되는 규칙 목록입니다. |
| `actions`      | 작업의 `array`                           | 참     | 정책이 적용하는 작업 목록입니다. GitLab 18.0 이상에서 최대 10개로 제한됩니다. |
| `policy_scope` | `object` [`policy_scope`](_index.md#configure-the-policy-scope) | 거짓    | 지정한 프로젝트, 그룹 또는 규정 준수 프레임워크 레이블을 기반으로 정책의 범위를 정의합니다. |
| `skip_ci`      | `object` [`skip_ci`](#skip_ci-type) | 거짓 | 사용자가 `skip-ci` 지시문을 적용할 수 있는지 여부를 정의합니다. |
| `no_pipeline`  | `object` [`no_pipeline`](#no_pipeline-type) | 거짓 | 사용자가 `no_pipeline` 지시문을 적용할 수 있는지 여부를 정의합니다. |

### `skip_ci` 유형 {#skip_ci-type}

{{< history >}}

- [GitLab 17.9에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/482952).

{{< /history >}}

검사 실행 정책은 `[skip ci]` 지시문을 사용할 수 있는 사용자를 제어합니다. `[skip ci]`을 사용할 수 있는 특정 사용자 또는 서비스 계정을 지정할 수 있으며 여전히 중요한 보안 및 규정 준수 검사를 수행하도록 합니다.

`skip_ci` 키워드를 사용하여 사용자가 `skip_ci` 지시문을 적용하여 파이프라인을 건너뛸 수 있는지 여부를 지정합니다. 키워드가 지정되지 않으면 `skip_ci` 지시문이 무시되어 모든 사용자가 파이프라인 실행 정책을 우회하지 못합니다.

| 필드                   | 형식     | 가능한 값          | 설명 |
|-------------------------|----------|--------------------------|-------------|
| `allowed` | `boolean`   | `true`, `false` | `true` 또는 `false`) `skip-ci` 지시문 적용을 적용된 파이프라인 실행 정책으로 파이프라인에 대해 허용하거나 방지하는 플래그입니다. |
| `allowlist`             | `object` | `users` | `skip-ci` 지시문 사용을 항상 허용하는 사용자를 지정합니다. `allowed` 플래그와 관계없습니다. `users:`을 사용하고 사용자 ID를 나타내는 `id` 키가 있는 개체 배열을 따릅니다. |

> [!note]
> `schedule` 규칙 유형이 있는 검사 실행 정책은 항상 `skip_ci` 옵션을 무시합니다. 예약된 스캔은 마지막 커밋 메시지에 `[skip ci]`(또는 이의 변형)이 표시되는지 여부와 관계없이 구성된 시간에 실행됩니다. 이렇게 하면 CI/CD 파이프라인이 그 외의 경우 건너뛸 때에도 보안 스캔이 예측 가능한 일정에 따라 수행됩니다.

### `no_pipeline` 유형 {#no_pipeline-type}

검사 실행 정책은 `[no_pipeline]` 지시문을 사용할 수 있는 사용자를 제어합니다. `[no_pipeline]`을 사용할 수 있는 특정 사용자 또는 서비스 계정을 지정할 수 있으며 여전히 중요한 보안 및 규정 준수 검사를 수행하도록 합니다.

`no_pipeline` 키워드를 사용하여 사용자가 `no_pipeline` 지시문을 적용하여 푸시에서 파이프라인을 만들지 않을 수 있는지 여부를 지정합니다. 키워드가 지정되지 않으면 `no_pipeline` 지시문이 무시되어 모든 사용자가 파이프라인 실행 정책을 우회하지 못합니다.

| 필드                   | 형식     | 가능한 값          | 설명 |
|-------------------------|----------|--------------------------|-------------|
| `allowed` | `boolean`   | `true`, `false` | `true` 또는 `false`) `no_pipeline` 지시문 적용을 적용된 파이프라인 실행 정책으로 파이프라인에 대해 허용하거나 방지하는 플래그입니다. |
| `allowlist`             | `object` | `users` | `no_pipeline` 지시문 사용을 항상 허용하는 사용자를 지정합니다. `allowed` 플래그와 관계없습니다. `users:`을 사용하고 사용자 ID를 나타내는 `id` 키가 있는 개체 배열을 따릅니다. |

> [!note]
> `schedule` 규칙 유형이 있는 검사 실행 정책은 항상 `no_pipeline` 옵션을 무시합니다. 예약된 스캔은 마지막 커밋 메시지에 `[no_pipeline]`(또는 이의 변형)이 표시되는지 여부와 관계없이 구성된 시간에 실행됩니다. 이렇게 하면 CI/CD 파이프라인이 생성되지 않을 때에도 보안 스캔이 예측 가능한 일정에 따라 수행됩니다.

## `pipeline` 규칙 유형 {#pipeline-rule-type}

{{< history >}}

- `branch_type` 필드:
  - GitLab 16.1에서 `security_policies_branch_type` [플래그](../../../administration/feature_flags/_index.md)로 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/404774)되었습니다.
  - GitLab 16.2에서 일반적으로 제공됩니다. 기능 플래그 `security_policies_branch_type`이 제거되었습니다.
- `branch_exceptions` 필드:
  - [GitLab 16.3에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/418741) [플래그 포함](../../../administration/feature_flags/_index.md) `security_policies_branch_exceptions`.
  - GitLab 16.5에서 일반적으로 제공됩니다. 기능 플래그 `security_policies_branch_exceptions`이 제거되었습니다.
- `pipeline_sources` 필드 및 `branch_type` 옵션 `target_default` 및 `target_protected`:
  - GitLab 18.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/541689) 되었으며 [플래그](../../../administration/feature_flags/_index.md) `flexible_scan_execution`라는 이름입니다.
  - GitLab 18.3에서 [GitLab.com, GitLab Self-Managed 및 GitLab Dedicated에서 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/541689).
  - GitLab 18.4에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/541689)합니다. 기능 플래그 `flexible_scan_execution`이 제거되었습니다.

{{< /history >}}

이 규칙은 선택된 브랜치에 대해 파이프라인이 실행될 때마다 정의된 작업을 적용합니다.

| 필드 | 형식 | 필수 | 가능한 값 | 설명 |
|-------|------|----------|-----------------|-------------|
| `type` | `string` | 참 | `pipeline` | 규칙의 유형입니다. |
| `branches` <sup>1</sup> | `array` / `string` | `branch_type` 필드가 존재하지 않는 경우 참 | `*` 또는 브랜치의 이름 | 정책이 적용되는 브랜치(와일드카드 지원)입니다. 머지 리퀘스트 승인 정책과의 호환성을 위해 기능 브랜치 및 기본 브랜치에 스캔을 포함하려면 모든 브랜치를 대상으로 해야 합니다. |
| `branch_type` <sup>1</sup> | `string` | `branches` 필드가 존재하지 않는 경우 참 | `default`, `protected`, `all`, `target_default` <sup>2</sup> 또는 `target_protected` <sup>2</sup> | 정책이 적용되는 브랜치의 유형입니다. |
| `branch_exceptions` | `array` / `string` | 거짓 |  브랜치의 이름 | 이 규칙에서 제외할 브랜치입니다. |
| `pipeline_sources` <sup>2</sup> | `array` / `string` | 거짓 | `api`, `chat`, `external`, `external_pull_request_event`, `merge_request_event` <sup>3</sup>, `pipeline`, `push` <sup>3</sup>, `schedule`, `trigger`, `unknown`, `web` | 검사 실행 작업이 시작될 때를 결정하는 파이프라인 소스입니다. 자세한 내용은 [문서](../../../ci/jobs/job_rules.md#ci_pipeline_source-predefined-variable)를 참조하세요. |

1. `branches` 또는 `branch_type`를 지정해야 합니다. 둘 다 지정할 수는 없습니다.
1. 일부 옵션은 `flexible_scan_execution` 기능 플래그가 활성화된 경우에만 사용 가능합니다. 자세한 내용은 기록을 참조하세요.
1. `branch_type` 옵션 `target_default` 또는 `target_protected`이 지정되면 `pipeline_sources` 필드는 `merge_request_event` 및 `push` 필드만 지원합니다.

## `schedule` 규칙 유형 {#schedule-rule-type}

{{< history >}}

- 새로운 `branch_type` 필드:
  - GitLab 16.1에서 `security_policies_branch_type` [플래그](../../../administration/feature_flags/_index.md)로 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/404774)되었습니다.
  - GitLab 16.2에서 일반적으로 제공됩니다. 기능 플래그가 제거되었습니다.
- 새로운 `branch_exceptions` 필드:
  - [GitLab 16.3에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/418741) [플래그 포함](../../../administration/feature_flags/_index.md) `security_policies_branch_exceptions`.
  - GitLab 16.5에서 일반적으로 제공됩니다. 기능 플래그가 제거되었습니다.
- 예약된 스캔에서 파이프라인을 만드는 새로운 `scan_execution_pipeline_worker` 작업자:
  - [GitLab 16.11에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147691) [플래그 포함](../../../administration/feature_flags/_index.md).
  - GitLab 17.5에서 GitLab.com에서 [활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/451890).
  - GitLab 17.6에서 [일반적으로 제공됨](https://gitlab.com/gitlab-org/gitlab/-/issues/451890). 기능 플래그 `scan_execution_pipeline_worker`이 제거되었습니다.
- 새 애플리케이션 설정 `security_policy_scheduled_scans_max_concurrency`:
  - GitLab 17.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/152855)되었습니다. 동시성 제한은 `scan_execution_pipeline_worker` 및 `scan_execution_pipeline_concurrency_control`이 모두 활성화되어 있을 때 적용됩니다.
  - GitLab 17.11에서 새 애플리케이션 설정 `security_policy_scheduled_scans_max_concurrency`을 [제거했습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178892).
- 검사 실행 예약된 작업의 동시성 제한:
  - GitLab 17.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/158636) 되었으며 [플래그](../../../administration/feature_flags/_index.md) `scan_execution_pipeline_concurrency_control`라는 이름입니다.
  - GitLab 17.9에서 [일반 공급 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/463802). 기능 플래그 `scan_execution_pipeline_concurrency_control`이 제거되었습니다.

{{< /history >}}

> [!warning]
> GitLab 16.1 이전에는 예약된 검사 실행 정책과 함께 [직접 전송](../../../administration/settings/import_and_export_settings.md#enable-migration-of-groups-and-projects-by-direct-transfer)을 사용하면 안 됩니다. 직접 전송을 사용해야 하는 경우 먼저 GitLab 16.2로 업그레이드하고 적용할 프로젝트에서 보안 정책 봇이 활성화되어 있는지 확인하세요.

`schedule` 규칙 유형을 사용하여 일정에 따라 보안 스캐너를 실행합니다.

예약된 파이프라인:

- 프로젝트의 `.gitlab-ci.yml` 파일에 정의된 작업이 아니라 정책에 정의된 스캐너만 실행합니다.
- `cadence` 필드에 정의된 일정에 따라 실행합니다.
- 프로젝트에서 `security_policy_bot` 사용자 계정으로 실행되며 게스트 역할과 파이프라인을 만들고 CI/CD 작업에서 리포지토리의 콘텐츠를 읽을 수 있는 권한이 있습니다. 이 계정은 정책이 그룹 또는 프로젝트에 연결될 때 생성됩니다.
- GitLab.com에서는 검사 실행 정책의 처음 10개 `schedule` 규칙만 적용됩니다. 한도를 초과하는 규칙은 효과가 없습니다.

| 필드      | 형식 | 필수 | 가능한 값 | 설명 |
|------------|------|----------|-----------------|-------------|
| `type`     | `string` | 참 | `schedule` | 규칙의 유형입니다. |
| `branches` <sup>1</sup> | `array` / `string` | `branch_type` 또는 `agents` 필드가 존재하지 않는 경우 참 | `*` 또는 브랜치의 이름 | 정책이 적용되는 브랜치(와일드카드 지원)입니다. |
| `branch_type` <sup>1</sup> | `string` | `branches` 또는 `agents` 필드가 존재하지 않는 경우 참 | `default`, `protected` 또는 `all` | 정책이 적용되는 브랜치의 유형입니다. |
| `branch_exceptions` | `array` / `string` | 거짓 |  브랜치의 이름 | 이 규칙에서 제외할 브랜치입니다. |
| `cadence`  | `string` | 참 | 옵션이 제한된 Cron 표현입니다. 예를 들어 `0 0 * * *`는 매일 자정(오전 12:00)에 실행되도록 예약합니다. | 예약된 시간을 나타내는 5개의 필드가 포함된 공백으로 구분된 문자열입니다. |
| `timezone` | `string` | 거짓 | 시간대 식별자(예: `America/New_York`) | 케이던스에 적용할 시간대입니다. 값은 IANA 시간대 데이터베이스 식별자여야 합니다. |
| `time_window` | `object` | 거짓 |  | 예약된 보안 스캔의 배포 및 기간 설정입니다. |
| `agents` <sup>1</sup>   | `object` | `branch_type` 또는 `branches` 필드가 존재하지 않는 경우 참  |  | [Kubernetes용 GitLab 에이전트](../../clusters/agent/_index.md)의 이름입니다. 여기서 [운영 컨테이너 스캔](../../clusters/agent/vulnerabilities.md)이 실행됩니다. 개체 키는 GitLab에서 프로젝트용으로 구성된 Kubernetes 에이전트의 이름입니다. |

1. `branches`, `branch_type` 또는 `agents` 중 하나만 지정해야 합니다.

### 케이던스 {#cadence}

`cadence` 필드를 사용하여 정책의 작업을 실행할 시기를 예약합니다. `cadence` 필드는 [cron 구문](../../../topics/cron/_index.md)을 사용하지만 일부 제한 사항이 있습니다:

- 다음 유형의 cron 구문만 지원됩니다:
  - 지정된 시간 주변의 시간당 한 번의 일일 케이던스(예: `0 18 * * *`)
  - 지정된 날짜 및 지정된 시간 주변의 주당 한 번의 주간 케이던스(예: `0 13 * * 0`)
- 쉼표(,), 하이픈(-) 또는 단계 연산자(/)는 분 및 시간에 대해 지원되지 않습니다. 이러한 문자를 사용하는 모든 예약된 파이프라인은 건너뜁니다.

`cadence` 필드 값을 선택할 때 다음을 고려하세요:

- 타이밍은 GitLab.com 및 GitLab Dedicated의 UTC를 기반으로 하며, GitLab Self-Managed의 경우 GitLab 호스트의 시스템 시간을 기반으로 합니다. 새 정책을 테스트할 때 파이프라인이 잘못된 시간에 실행되는 것처럼 보일 수 있습니다. 이는 로컬 시간대가 아닌 서버의 시간대에 예약되기 때문입니다.
- 예약된 파이프라인은 필요한 리소스를 만들 수 있을 때까지 시작되지 않습니다. 즉, 파이프라인이 정책에 지정된 타이밍에 정확히 시작되지 않을 수 있습니다.

`schedule` 규칙 유형을 `agents` 필드와 함께 사용할 때:

- Kubernetes용 GitLab 에이전트는 30초마다 적용 가능한 정책이 있는지 확인합니다. 에이전트가 정책을 찾으면 정의된 `cadence`에 따라 스캔을 실행합니다.
- cron 표현은 Kubernetes 에이전트 포드의 시스템 시간을 사용하여 평가됩니다.

`schedule` 규칙 유형을 `branches` 필드와 함께 사용할 때:

- cron 작업자는 15분 간격으로 실행되고 이전 15분 동안 실행되도록 예약된 파이프라인을 시작합니다. 따라서 예약된 파이프라인은 최대 15분의 오프셋으로 실행될 수 있습니다.
- 정책이 많은 프로젝트 또는 브랜치에 적용되면 정책이 배치로 처리되며 모든 파이프라인을 만드는 데 시간이 걸릴 수 있습니다.

![예약된 보안 스캔이 처리되고 실행되는 방식을 보여주는 다이어그램입니다. 잠재적 지연이 있습니다.](img/scheduled_scan_execution_policies_diagram_v18_04.png)

### `agent` 스키마 {#agent-schema}

이 스키마를 사용하여 [`schedule` 규칙 유형](#schedule-rule-type)에서 `agents` 개체를 정의합니다.

| 필드        | 형식                | 필수 | 설명 |
|--------------|---------------------|----------|-------------|
| `namespaces` | `array` / `string` | 참 | 스캔되는 네임스페이스입니다. 비어 있으면 모든 네임스페이스가 스캔됩니다. |

#### `agent` 예제 {#agent-example}

```yaml
- name: Enforce container scanning in cluster connected through my-gitlab-agent for default and kube-system namespaces
  enabled: true
  rules:
  - type: schedule
    cadence: '0 10 * * *'
    agents:
      <agent-name>:
        namespaces:
        - 'default'
        - 'kube-system'
  actions:
  - scan: container_scanning
```

스케줄 규칙의 키는:

- `cadence`(필수): 스캔을 실행할 시간을 나타내는 [Cron 표현](../../../topics/cron/_index.md)입니다.
- `agents:<agent-name>`(필수): 스캔에 사용할 에이전트의 이름입니다.
- `agents:<agent-name>:namespaces`(선택 사항): 스캔할 Kubernetes 네임스페이스입니다. 생략하면 모든 네임스페이스가 스캔됩니다.

### `time_window` 스키마 {#time_window-schema}

[`schedule` 규칙 유형](#schedule-rule-type)에서 `time_window` 개체를 사용하여 예약된 스캔이 시간 경과에 따라 분배되는 방식을 정의합니다. 정책 편집기의 YAML 모드에서만 `time_window`을 구성할 수 있습니다.

| 필드          | 형식      | 필수 | 설명                                                                                                                                                                          |
|----------------|-----------|----------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `distribution` | `string`  | 참     | 스캔 예약의 배포 패턴입니다. `random`만 지원합니다. 여기서 스캔은 `value` 키로 정의된 간격 내에서 `time_window`에 무작위로 분배됩니다. |
| `value`        | `integer` | 참     | 스캔 일정을 실행해야 하는 시간대(초 단위)입니다. 3600(1시간)과 2629746(약 30일) 사이의 값을 입력하세요.                                               |

#### `time_window` 예제 {#time_window-example}

```yaml
- name: Enforce container scanning with a time window of 1 hour
  enabled: true
  rules:
  - type: schedule
    cadence: '0 10 * * *'
    time_window:
      value: 3600
      distribution: random
  actions:
  - scan: container_scanning
```

### 규모가 큰 프로젝트에 대해 예약된 파이프라인 최적화 {#optimize-scheduled-pipelines-for-projects-at-scale}

정책이 여러 프로젝트 및 브랜치에 걸쳐 예약된 파이프라인을 적용할 때 파이프라인은 동시에 실행됩니다. 각 프로젝트에서 예약된 파이프라인의 첫 번째 실행은 해당 프로젝트의 일정을 실행하는 책임이 있는 보안 봇 사용자를 만듭니다.

규모가 큰 프로젝트의 성능을 최적화하려면:

- 프로젝트의 하위 집합부터 시작하여 예약된 검사 실행 정책을 점진적으로 롤아웃합니다. 보안 정책 범위를 활용하여 특정 그룹, 프로젝트 또는 주어진 규정 준수 프레임워크 레이블을 포함하는 프로젝트를 대상으로 할 수 있습니다.
- 지정된 `tag`을 가진 러너에서 실행되도록 정책을 구성할 수 있습니다. 다른 러너에 미치는 영향을 줄이기 위해 정책에서 적용한 일정을 처리하기 위해 각 프로젝트에 전용 러너를 설정하는 것을 고려하세요.
- 프로덕션에 배포하기 전에 스테이징 또는 낮은 환경에서 구현을 테스트합니다. 성능을 모니터링하고 결과를 기반으로 롤아웃 계획을 조정합니다.

### 예약된 검사 실행 정책의 최대 스케줄링 시간 범위 구성 {#configuring-the-maximum-scheduling-timespan-for-scheduled-scan-execution-policies}

예약된 검사 실행 정책은 `cadence` 필드와 함께 cron 표현을 사용하는 월간 스케줄링을 지원합니다. `time_window`을 2629746초(약 30일)까지 구성하여 해당 기간 내에 스캔을 무작위로 분배할 수 있습니다.

예를 들어, 30일 분배 창으로 월간 스캔을 예약하려면:

```yaml
rules:
  - type: schedule
    cadence: '0 0 1 * *'  # Run on the first day of each month
    time_window:
      value: 2592000  # 30 days in seconds
      distribution: random
```

#### 인스턴스 가동 중단 중 예약된 스캔 이해 {#understanding-scheduled-scans-during-instance-downtimes}

예약된 스캔은 다음 실행 시간을 추적합니다. 성공적인 스캔 후 시스템은 다음 스캔이 실행될 시기를 업데이트합니다. GitLab 인스턴스가 예약된 스캔 시간에 사용할 수 없는 경우(유지 관리, 중단 또는 재시작으로 인해) 시스템은 이미 실행되어야 하지만 아직 실행되지 않은 스캔을 식별하고 인스턴스를 사용할 수 있을 때 파이프라인을 만듭니다.

#### 예약된 스캔이 있는 프로젝트 삭제 {#deleting-projects-with-scheduled-scans}

프로젝트를 삭제하면 모든 관련 예약된 스캔도 삭제됩니다. 삭제된 프로젝트에 대해 파이프라인이 실행되지 않습니다.

#### 실행 중인 예약된 스캔 취소 {#canceling-a-running-scheduled-scan}

예약된 스캔을 취소하려면 두 가지 옵션이 있습니다:

- 개별 파이프라인 취소: 프로젝트에서 작업을 취소할 필요한 권한이 있으면 파이프라인 보기에서 직접 실행 중인 파이프라인을 취소할 수 있습니다.
- **Disable the policy**: 정책 편집기에서 `enabled: false`을 설정하여 검사 실행 정책을 비활성화합니다. 이미 실행 중이거나 다음 15분(대략) 내에 실행되도록 예약된 스캔은 여전히 실행될 수 있습니다.

#### 대규모 배포에 대한 권장 사항 {#recommendations-for-large-scale-deployments}

많은 프로젝트에 걸쳐 예약된 검사 실행 정책을 배포할 때 다음 권장 사항을 고려하세요:

- 점진적 롤아웃 사용: 프로젝트의 작은 하위 집합부터 시작하여 점진적으로 프로젝트를 더 추가합니다. [규정 준수 프레임워크 레이블](../../project/working_with_projects.md#add-a-compliance-framework-to-a-project)을 사용하여 정책을 특정 프로젝트 그룹으로 범위를 지정합니다.
- `time_window` 구성: 예약된 정책에서 항상 `time_window` 매개변수를 설정하세요. 이 설정이 없으면 모든 파이프라인이 동일한 시간에 예약되어 성능 이슈 및 리소스 경합을 야기할 수 있습니다.
- 스테이징에서 테스트: 프로덕션에 배포하기 전에 스테이징 또는 낮은 환경에서 정책 구성을 검증합니다. 성능을 모니터링하고 결과에 따라 조정합니다.
- 러너 용량 고려: 러너에 미치는 영향은 정책 구성, 러너 가용성 및 GitLab 인스턴스 배포에 따라 다릅니다. 특정 태그를 가진 러너를 사용하도록 정책을 구성하여 로드를 분배합니다.

예약된 스캔 최적화에 대한 자세한 내용은 [규모가 큰 프로젝트에 대해 예약된 파이프라인 최적화](#optimize-scheduled-pipelines-for-projects-at-scale)를 참조하세요.

### 동시성 제어 {#concurrency-control}

`time_window` 속성을 설정할 때 GitLab이 동시성 제어를 적용합니다.

동시성 제어는 [`time_window` 설정](#time_window-schema)에 따라 예약된 파이프라인을 분배합니다. 정책에 정의됩니다.

## `scan` 작업 유형 {#scan-action-type}

{{< history >}}

- 검사 실행 정책 변수 우선순위:
  - GitLab 16.7에서 [변경됨](https://gitlab.com/gitlab-org/gitlab/-/issues/424028) [플래그 포함](../../../administration/feature_flags/_index.md) `security_policies_variables_precedence`. 기본적으로 활성화됩니다.
  - GitLab 16.8에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/435727)합니다. 기능 플래그 `security_policies_variables_precedence`이 제거되었습니다.
- 주어진 작업에 대한 보안 템플릿 선택:
  - [GitLab 17.1의 프로젝트에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/415427) [기능 플래그 포함](../../../administration/feature_flags/_index.md) `scan_execution_policies_with_latest_templates`. 기본적으로 비활성화되어 있습니다.
  - [GitLab 17.2의 그룹에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/468981) [기능 플래그 포함](../../../administration/feature_flags/_index.md) `scan_execution_policies_with_latest_templates_group`. 기본적으로 비활성화되어 있습니다.
  - GitLab 17.2에서 [GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/461474) 및 [GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/468981)에서 활성화되었습니다.
  - GitLab 17.3에서 일반적으로 제공됩니다. 기능 플래그 `scan_execution_policies_with_latest_templates` 및 `scan_execution_policies_with_latest_templates_group` 제거됨.
- `v2` 템플릿 지원 `dependency_scanning` [GitLab 18.4에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/523986).
- `dependency_scanning`의 기본 템플릿 [GitLab 19.1의 새 정책으로 변경됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/598744) `v2`.

{{< /history >}}

이 작업은 정의된 정책의 하나 이상 규칙에 대한 조건이 충족될 때 추가 매개변수와 함께 선택된 `scan`을 실행합니다.

| 필드 | 형식 | 가능한 값 | 설명 |
|-------|------|-----------------|-------------|
| `scan` | `string` | `sast`, `sast_iac`, `dast`, `secret_detection`, `container_scanning`, `dependency_scanning` | 작업의 유형입니다. |
| `site_profile` | `string` | 선택된 [DAST 사이트 프로필](../dast/profiles.md#site-profile)의 이름입니다. | DAST 스캔을 실행하기 위한 DAST 사이트 프로필입니다. 이 필드는 `scan` 유형이 `dast`인 경우에만 설정해야 합니다. |
| `scanner_profile` | `string` 또는 `null` | 선택된 [DAST 스캐너 프로필](../dast/profiles.md#scanner-profile)의 이름입니다. | DAST 스캔을 실행하기 위한 DAST 스캐너 프로필입니다. 이 필드는 `scan` 유형이 `dast`인 경우에만 설정해야 합니다.|
| `variables` | `object` | | 선택된 스캔에 적용하고 적용할 `key: value` 쌍의 배열로 제공되는 CI/CD 변수 세트입니다. `key`은 변수 이름이며 `value`은 문자열로 제공됩니다. 이 매개변수는 지정된 스캔에 대해 GitLab CI/CD 작업이 지원하는 모든 변수를 지원합니다. |
| `tags` | `array` / `string` | | 정책에 대한 러너 태그 목록입니다. 정책 작업은 지정된 태그를 가진 러너로 실행됩니다. |
| `template` | `string` | `default`, `latest` 또는 스캐너별 버전 | CI/CD 템플릿 버전을 적용합니다. `default`은 안정적인 템플릿을 사용합니다. `latest`는 주요 변경 사항이 포함될 수 있는 실험적 템플릿을 사용합니다. 가장 현재의 권장 버전이 아닙니다. 일부 스캐너는 권장 구성을 나타내는 버전이 지정된 템플릿도 지원합니다. `latest` 템플릿은 머지 리퀘스트와 관련된 `pipeline_sources`만 지원합니다. 사용 가능한 버전별 스캐너는 [스캐너 템플릿 버전](#scanner-template-versions)을 참조하세요. |
| `scan_settings` | `object` | | 선택된 스캔에 적용하고 적용할 `key: value` 쌍의 배열로 제공되는 스캔 설정 세트입니다. `key`은 설정 이름이며 `value`은 부울 또는 문자열로 제공됩니다. 이 매개변수는 [스캔 설정](#scan-settings)에 정의된 설정을 지원합니다. |

> [!note]
> 프로젝트에 머지 리퀘스트 파이프라인이 활성화되어 있으면 각 적용된 스캔에 대해 정책에서 `AST_ENABLE_MR_PIPELINES` CI/CD 변수를 `"true"`로 설정해야 합니다. 머지 리퀘스트 파이프라인에서 보안 스캔 도구를 사용하는 방법에 대한 자세한 내용은 [보안 스캔 문서](../detect/security_configuration.md#use-security-scanning-tools-with-merge-request-pipelines)를 참조하세요.

### 스캐너 템플릿 버전 {#scanner-template-versions}

`template` 필드는 모든 스캐너 유형에 대해 `default` 및 `latest`을 허용합니다. 일부 스캐너는 추가 버전이 지정된 템플릿을 지원합니다. 권장되는 기본값은 스캐너에 따라 다릅니다. 이 필드를 설정하기 전에 스캐너 문서를 확인하세요.

| 스캐너 | 지원되는 템플릿 | 설명서 |
|---------|---------------------|---------------|
| `sast` | `default`, `latest` | [안정 대 최신 SAST 템플릿](../sast/_index.md#stable-vs-latest-sast-templates) |
| `sast_iac` | `default`, `latest` | [템플릿 에디션](../detect/security_configuration.md#template-editions) |
| `secret_detection` | `default`, `latest` | [템플릿 에디션](../detect/security_configuration.md#template-editions) |
| `container_scanning` | `default`, `latest` | [템플릿 에디션](../detect/security_configuration.md#template-editions) |
| `dependency_scanning` | `default`, `latest`, `v2` | [SBOM을 사용한 종속성 검사](../dependency_scanning/dependency_scanning_sbom/_index.md) |

### 스캐너 동작 {#scanner-behavior}

일부 스캐너는 `scan` 작업에서 일반 CI/CD 파이프라인 스캔과 다르게 동작합니다:

- 정적 애플리케이션 보안 테스트(SAST): 리포지토리에 [SAST에서 지원하는 파일](../sast/_index.md#supported-languages-and-frameworks)이 포함된 경우에만 실행됩니다.
- 시크릿 검색:
  - 기본적으로 기본 규칙 집합의 규칙만 지원됩니다.
  - 규칙 집합 구성을 사용자 지정하려면 다음 중 하나를 수행합니다:
    - 기본 규칙 집합을 수정합니다. 검사 실행 정책을 사용하여 `SECRET_DETECTION_RULESET_GIT_REFERENCE` CI/CD 변수를 지정합니다. 기본적으로 기본 규칙 집합에서 규칙을 만 재정의하거나 비활성화하는 [원격 구성 파일](../secret_detection/pipeline/configure.md#with-a-remote-ruleset)을 가리킵니다. 이 변수만 사용하면 기본 규칙 집합을 확장하거나 바꿀 수 없습니다.
    - [확장](../secret_detection/pipeline/configure.md#extend-the-default-ruleset) 또는 [바꾸기](../secret_detection/pipeline/configure.md#replace-the-default-ruleset) 기본 규칙 집합. 검사 실행 정책을 사용하여 `SECRET_DETECTION_RULESET_GIT_REFERENCE` CI/CD 변수 및 기본 규칙 집합을 확장하거나 바꾸기 위해 [Git 통과](../secret_detection/pipeline/custom_rulesets_schema.md#passthrough-types)를 사용하는 원격 구성 파일을 지정합니다. 자세한 안내서는 [집중식으로 관리되는 파이프라인 시크릿 검색 구성을 설정하는 방법](https://support.gitlab.com/hc/en-us/articles/18863735262364-How-to-set-up-a-centrally-managed-pipeline-secret-detection-configuration-applied-via-Scan-Execution-Policy)을 참조하세요.
  - `scheduled` 검사 실행 정책의 경우 시크릿 검색은 기본적으로 먼저 `historic` 모드(`SECRET_DETECTION_HISTORIC_SCAN` = `true`)에서 실행됩니다. 모든 후속 예약된 스캔은 기본 모드에서 `SECRET_DETECTION_LOG_OPTIONS`이 마지막 실행과 현재 SHA 사이의 커밋 범위로 설정됩니다. 검사 실행 정책에서 CI/CD 변수를 지정하여 이 동작을 재정의할 수 있습니다. 자세한 내용은 [전체 기록 파이프라인 시크릿 검색](../secret_detection/pipeline/_index.md#run-a-historic-scan)을 참조하세요.
  - `triggered` 검사 실행 정책의 경우 시크릿 검색은 [`.gitlab-ci.yml`에서 수동으로 구성된](../secret_detection/pipeline/_index.md#edit-the-gitlab-ciyml-file-manually) 일반 스캔처럼 작동합니다.
- 컨테이너 스캔: `pipeline` 규칙 유형에 대해 구성된 스캔은 `agents` 개체에 정의된 에이전트를 무시합니다. `agents` 개체는 `schedule` 규칙 유형에만 고려됩니다. `agents` 개체에 제공된 이름을 가진 에이전트를 만들고 프로젝트에 대해 구성해야 합니다.

### DAST 프로필 {#dast-profiles}

다이나믹 애플리케이션 보안 테스트(DAST)를 적용할 때 다음 요구 사항이 적용됩니다:

- 정책 범위의 모든 프로젝트에 대해 지정된 [사이트 프로필](../dast/profiles.md#site-profile) 및 [스캐너 프로필](../dast/profiles.md#scanner-profile)이 존재해야 합니다. 이들을 사용할 수 없으면 정책이 적용되지 않으며 오류 메시지가 있는 작업이 생성됩니다.
- DAST 사이트 프로필 또는 스캐너 프로필이 활성화된 검사 실행 정책에 명명되어 있으면 프로필을 수정하거나 삭제할 수 없습니다. 프로필을 편집하거나 삭제하려면 먼저 정책 편집기에서 정책을 **비활성화됨**으로 설정하거나 YAML 모드에서 `enabled: false`을 설정해야 합니다.
- 예약된 DAST 스캔으로 정책을 구성할 때 보안 정책 프로젝트의 리포지토리에서 커밋의 작성자는 스캐너 및 사이트 프로필에 액세스할 수 있어야 합니다. 그렇지 않으면 스캔이 성공적으로 예약되지 않습니다.

### 스캔 설정 {#scan-settings}

`scan_settings` 매개변수에서 지원하는 설정은 다음과 같습니다:

| 설정 | 형식 | 필수 | 가능한 값 | 기본값 | 설명 |
|-------|------|----------|-----------------|-------------|-----------|
| `ignore_default_before_after_script` | `boolean` | 거짓 | `true`, `false` | `false` | 파이프라인 구성에서 기본 `before_script` 및 `after_script` 정의를 스캔 작업에서 제외할지 여부를 지정합니다. |

## CI/CD 변수 {#cicd-variables}

> [!warning]
> Git 리포지토리의 일반 텍스트 정책 구성의 일부로 저장되므로 변수에 민감한 정보나 자격 증명을 저장하지 마세요.

검사 실행 정책에 정의된 변수는 표준 [CI/CD 변수 우선순위](../../../ci/variables/_index.md#cicd-variable-precedence)를 따릅니다.

검사 실행 정책이 적용되는 모든 프로젝트의 다음 CI/CD 변수에 대해 미리 구성된 값이 사용됩니다. 정책만 이 값을 재정의할 수 있습니다. 그룹 또는 프로젝트 CI/CD 변수는 이러한 변수를 재정의할 수 없습니다:

```plaintext
DS_EXCLUDED_PATHS: spec, test, tests, tmp
SAST_EXCLUDED_PATHS: spec, test, tests, tmp
SECRET_DETECTION_EXCLUDED_PATHS: ''
SECRET_DETECTION_HISTORIC_SCAN: false
SAST_EXCLUDED_ANALYZERS: ''
DEFAULT_SAST_EXCLUDED_PATHS: spec, test, tests, tmp
DS_EXCLUDED_ANALYZERS: ''
SECURE_ENABLE_LOCAL_CONFIGURATION: true
```

GitLab 16.9 이전 버전에서:

- 접미사 `_EXCLUDED_PATHS`이 있는 CI/CD 변수가 정책에서 선언된 경우 해당 값을 그룹 또는 프로젝트의 CI/CD 변수로 재정의할 수 있습니다.
- 접미사 `_EXCLUDED_ANALYZERS`이 있는 CI/CD 변수가 정책에서 선언된 경우 정책, 그룹 또는 프로젝트가 어디에서 정의되었는지에 관계없이 해당 값이 무시되었습니다.

## 정책 범위 스키마 {#policy-scope-schema}

정책 적용을 사용자 지정하려면 지정한 프로젝트, 그룹 또는 규정 준수 프레임워크 레이블을 포함하거나 제외하도록 정책의 범위를 정의할 수 있습니다. 자세한 내용은 [범위](_index.md#configure-the-policy-scope)를 참조하세요.

> [!note]
> `policy_scope` 필드를 빈 컬렉션(예: `including: []`)으로 설정하면 필드를 생략하는 것과 동일하게 취급되므로 정책이 해당 범위 차원의 모든 프로젝트에 적용됩니다. 정책을 완전히 비활성화하려면 `enabled: false`을 사용합니다. 자세한 내용은 [`policy_scope`의 빈 컬렉션](_index.md#empty-collections-in-policy_scope)을 참조하세요.

## 정책 업데이트 전파 {#policy-update-propagation}

정책을 업데이트할 때 변경 사항은 정책을 업데이트하는 방식에 따라 다르게 전파됩니다:

- [보안 정책 프로젝트](../_index.md)에서 머지 리퀘스트와 함께: 변경 사항은 머지 리퀘스트가 병합된 후 즉시 적용됩니다.
- `.gitlab/security-policies/policy.yml`에 직접 커밋: 변경 사항이 적용되는 데 최대 10분이 걸릴 수 있습니다.

### 트리거 동작 {#triggering-behavior}

파이프라인 기반 정책(`type: pipeline`)으로 업데이트하면 즉시 파이프라인을 트리거하거나 이미 진행 중인 파이프라인에 영향을 주지 않습니다. 정책 변경 사항은 향후 파이프라인 실행에 적용됩니다.

예약된 정책의 규칙을 예약된 케이던스 외부에서 수동으로 트리거할 수 없습니다.

## 예제 보안 정책 프로젝트 {#example-security-policy-project}

[보안 정책 프로젝트](enforcement/security_policy_projects.md)에 저장된 `.gitlab/security-policies/policy.yml` 파일에서 이 예제를 사용할 수 있습니다:

```yaml
---
scan_execution_policy:
- name: Enforce DAST in every release pipeline
  description: This policy enforces pipeline configuration to have a job with DAST scan for release branches
  enabled: true
  rules:
  - type: pipeline
    branches:
    - release/*
  actions:
  - scan: dast
    scanner_profile: Scanner Profile A
    site_profile: Site Profile B
- name: Enforce DAST and secret detection scans every 10 minutes
  description: This policy enforces DAST and secret detection scans to run every 10 minutes
  enabled: true
  rules:
  - type: schedule
    branches:
    - main
    cadence: "*/10 * * * *"
  actions:
  - scan: dast
    scanner_profile: Scanner Profile C
    site_profile: Site Profile D
  - scan: secret_detection
    scan_settings:
      ignore_default_before_after_script: true
- name: Enforce secret detection and container scanning in every default branch pipeline
  description: This policy enforces pipeline configuration to have a job with secret detection and container scanning scans for the default branch
  enabled: true
  rules:
  - type: pipeline
    branches:
    - main
  actions:
  - scan: secret_detection
  - scan: sast
    variables:
      SAST_EXCLUDED_ANALYZERS: brakeman
  - scan: container_scanning
```

이 예에서:

- `release/*` 와일드카드와 일치하는 브랜치에서 실행되는 모든 파이프라인의 경우(예: 브랜치 `release/v1.2.1`)
  - DAST 스캔은 `Scanner Profile A` 및 `Site Profile B`으로 실행됩니다.
- DAST 및 시크릿 검색 스캔은 10분마다 실행됩니다. DAST 스캔은 `Scanner Profile C` 및 `Site Profile D`으로 실행됩니다.
- 시크릿 검색, 컨테이너 스캔 및 SAST 스캔은 `main` 브랜치에서 실행되는 모든 파이프라인에 대해 실행됩니다. SAST 스캔은 `SAST_EXCLUDED_ANALYZER` 변수가 `"brakeman"`으로 설정된 상태에서 실행됩니다.

## 검사 실행 정책 편집기의 예제 {#example-for-scan-execution-policy-editor}

[검사 실행 정책 편집기](#scan-execution-policy-editor)의 YAML 모드에서 이 예제를 사용할 수 있습니다. 이는 이전 예제의 단일 개체에 해당합니다.

```yaml
name: Enforce secret detection and container scanning in every default branch pipeline
description: This policy enforces pipeline configuration to have a job with secret detection and container scanning scans for the default branch
enabled: true
rules:
  - type: pipeline
    branches:
      - main
actions:
  - scan: secret_detection
  - scan: container_scanning
```

## 중복 스캔 방지 {#avoiding-duplicate-scans}

검사 실행 정책으로 인해 프로젝트의 `.gitlab-ci.yml` 파일에 스캔 작업을 포함하면 동일한 유형의 스캐너가 여러 번 실행될 수 있습니다.

중복 스캔은 의도적으로 실행됩니다. 스캐너는 서로 다른 변수와 설정으로 두 번 이상 실행될 수 있기 때문입니다. 예를 들어, 정책에 의해 적용된 것과 다른 변수를 사용하여 SAST 스캔을 실행할 수 있습니다. 이 시나리오에서 두 개의 SAST 작업이 파이프라인에서 실행됩니다:

- 하나는 사용자 지정 변수입니다.
- 하나는 정책에 의해 적용된 변수입니다.

중복 스캔을 방지하려면 프로젝트의 `.gitlab-ci.yml` 파일에서 스캔 중 하나를 제거하거나 변수를 사용하는 로컬 작업을 건너뜁니다. 작업을 건너뛰면 검사 실행 정책으로 정의된 보안 작업이 실행되지 않습니다.

변수를 사용하여 스캔 작업을 건너뛰려면 다음을 사용할 수 있습니다:

- `SAST_DISABLED: "true"` SAST 작업을 건너뜁니다.
- `DAST_DISABLED: "true"` DAST 작업을 건너뜁니다.
- `CONTAINER_SCANNING_DISABLED: "true"` 컨테이너 스캔 작업을 건너뜁니다.
- `SECRET_DETECTION_DISABLED: "true"` 시크릿 검색 작업을 건너뜁니다.
- `DEPENDENCY_SCANNING_DISABLED: "true"` 종속성 검사 작업을 건너뜁니다.

작업을 건너뛸 수 있는 모든 변수의 개요는 [CI/CD 변수 문서](../../../topics/autodevops/cicd_variables.md#job-skipping-variables)를 참조하세요.

## 문제 해결 {#troubleshooting}

검사 실행 정책으로 작업할 때 다음 이슈가 발생할 수 있습니다.

### 검사 실행 정책 파이프라인이 생성되지 않음 {#scan-execution-policy-pipelines-are-not-created}

검사 실행 정책이 `type: pipeline`으로 정의된 파이프라인을 예상대로 생성하지 않으면 프로젝트의 `.gitlab-ci.yml` 파일에 [`workflow:rules`](../../../ci/yaml/workflow.md)이 있을 수 있으며 이는 정책이 파이프라인을 생성하지 못하게 합니다.

`type: pipeline` 규칙이 있는 검사 실행 정책은 병합된 CI/CD 구성을 사용하여 파이프라인을 생성합니다. 프로젝트의 `workflow:rules`이 파이프라인을 완전히 필터링하면 검사 실행 정책이 파이프라인을 생성할 수 없습니다.

예를 들어, 다음 `workflow:rules` 구성은 모든 파이프라인이 생성되지 않도록 방지합니다:

```yaml
# .gitlab-ci.yml
workflow:
  rules:
  - if: $CI_PIPELINE_SOURCE == "push"
    when: never
```

해결:

이 이슈를 해결하려면 다음 옵션을 사용할 수 있습니다:

- 프로젝트의 `.gitlab-ci.yml` 파일에서 `workflow:rules`을 수정하여 검사 실행 정책이 파이프라인을 생성하도록 허용합니다. `$CI_PIPELINE_SOURCE` 변수를 사용하여 정책이 트리거한 파이프라인을 식별할 수 있습니다:

  ```yaml
  workflow:
    rules:
    - if: $CI_PIPELINE_SOURCE == "security_orchestration_policy"
    - if: $CI_PIPELINE_SOURCE == "push"
      when: never
  ```

- `type: schedule` 규칙 대신 `type: pipeline` 규칙을 사용합니다. 예약된 검사 실행 정책은 `workflow:rules`의 영향을 받지 않으며 정의된 일정에 따라 파이프라인을 생성합니다.
- CI/CD 파이프라인에서 보안 스캔이 언제 어떻게 실행되는지 더 많이 제어할 수 있도록 [파이프라인 실행 정책](pipeline_execution_policies.md)을 사용합니다.
