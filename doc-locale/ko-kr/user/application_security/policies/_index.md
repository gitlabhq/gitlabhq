---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 정책
description: "보안 정책, 적용, 규정 준수, 승인 및 검사."
---

{{< details >}}

- 계층: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

정책은 보안 및 규정 준수 팀에 조직 전체에서 제어를 적용하는 방법을 제공합니다.

보안 팀은 다음을 보장할 수 있습니다:

- 보안 스캐너가 적절한 구성으로 개발 팀 파이프라인에 적용됩니다.
- 모든 검사 작업이 변경이나 수정 없이 실행됩니다.
- 해당 결과에 따라 머지 리퀘스트에 적절한 승인이 제공됩니다.
- 더 이상 감지되지 않는 취약성이 자동으로 해결되어 취약성 분류 작업량을 줄입니다.

규정 준수 팀은 다음을 적용할 수 있습니다:

- 모든 머지 리퀘스트에 여러 승인자
- 조직 요구 사항에 따른 프로젝트 설정(예: 머지 리퀘스트 설정 또는 리포지토리 설정 활성화 또는 잠금).

다음 정책 유형을 사용할 수 있습니다:

- [검사 실행 정책](scan_execution_policies.md). 보안 검사를 파이프라인의 일부로 또는 지정된 일정에 따라 적용합니다.
- [머지 리퀘스트 승인 정책](merge_request_approval_policies.md). 검사 결과에 따라 프로젝트 수준 설정 및 승인 규칙을 적용합니다.
- [파이프라인 실행 정책](pipeline_execution_policies.md). 프로젝트 파이프라인의 일부로 CI/CD 작업을 적용합니다.
  - [예정된 파이프라인 실행 정책 (실험)](scheduled_pipeline_execution_policies.md). 커밋 활동과 관계없이 프로젝트 전체에서 예정된 속도로 사용자 지정 CI/CD 작업을 적용합니다.
- [취약성 관리 정책](vulnerability_management_policy.md). 기본 브랜치에서 더 이상 감지되지 않는 취약성을 자동으로 해결합니다.

## 정책 범위 구성 {#configure-the-policy-scope}

## `policy_scope` 키워드 {#policy_scope-keyword}

`policy_scope` 키워드를 사용하여 지정하는 그룹, 프로젝트, 규정 준수 프레임워크 또는 조합에만 정책을 적용합니다.

| 필드                   | 형식     | 가능한 값          | 설명 |
|-------------------------|----------|--------------------------|-------------|
| `match_mode` | `string` | `all`, `any` | GitLab 18.10에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/569793)되었습니다. 정책이 여러 범위 조건을 처리하는 방법을 결정합니다. `all` (기본값)를 사용하여 모든 조건이 일치하도록 요구하거나 `any`를 사용하여 최소한 하나의 조건이 일치하도록 요구합니다. |
| `compliance_frameworks` | `array`  | 해당 없음           | `id` 키를 포함하는 개체 배열에서 적용 범위 내의 규정 준수 프레임워크 ID 목록입니다. |
| `projects`              | `object` | `including`, `excluding` | `excluding:` 또는 `including:`를 사용한 후 포함하거나 제외할 프로젝트의 ID를 `id` 키를 포함하는 개체 배열에 나열합니다. `type: personal`를 사용하여 개인 프로젝트를 제외하거나 `type: archived`를 사용하여 보관된 프로젝트를 제외할 수 있습니다. |
| `groups`                | `object` | `including`              | `including:`를 사용한 후 포함할 그룹의 ID를 `id` 키를 포함하는 개체 배열에 나열합니다. 동일한 보안 정책 프로젝트에 연결된 그룹만 정책에 나열할 수 있습니다. |

### `policy_scope`의 빈 컬렉션 {#empty-collections-in-policy_scope}

`policy_scope` 필드가 빈 컬렉션(`[]`)으로 설정되면 필드가 완전히 생략된 것처럼 처리됩니다. 이는 정책이 제한 없이 모든 프로젝트에 적용됨을 의미합니다.

구체적으로:

- `projects: { including: [] }`는 정책을 모든 프로젝트에 적용하고 0개 프로젝트에는 적용하지 않습니다.
- `groups: { including: [] }`는 정책을 모든 그룹에 적용하고 0개 그룹에는 적용하지 않습니다.
- `compliance_frameworks: []`는 정책을 모든 프로젝트에 적용하고 프레임워크가 없는 프로젝트에는 적용하지 않습니다.

이 동작은 빈 컬렉션이 필터가 제공되지 않은 것처럼 처리되는 기존 정책과의 하위 호환성을 유지합니다.

정책이 프로젝트에 적용되지 않도록 하려면 빈 컬렉션을 사용하는 대신 `enabled: false`를 설정합니다:

```yaml
policy_scope:
  projects:
    including:
      - id: 123
enabled: false  # Disables the policy entirely
```

### `match_mode` 이해 {#understanding-match_mode}

여러 범위 조건(예: `projects` 그리고 `groups`)을 지정할 때 `match_mode` 필드는 이러한 조건이 결합되는 방식을 결정합니다:

- **`all` (기본값)**: 정책은 지정된 모든 조건과 일치하는 프로젝트에만 적용됩니다. 이 모드는 더 제한적이며 기존 정책과의 하위 호환성을 유지합니다.
- **`any`**: 정책은 지정된 조건 중 하나와 일치하는 프로젝트에 적용됩니다. 이 모드는 더 관대하며 단일 정책으로 다양한 프로젝트 세트를 대상으로 할 때 유용합니다.

예를 들어, 포함 프로젝트 목록과 포함 그룹 목록을 모두 지정하는 경우:

- `match_mode: all`을(를) 사용하면 프로젝트는 프로젝트 목록에 있어야 **그리고** 지정된 그룹 중 하나에 속해야 합니다.
- `match_mode: any`을(를) 사용하면 프로젝트는 프로젝트 목록에 있거나 **또는** 지정된 그룹 중 하나에 속하는 경우 범위에 있습니다.

`excluding` 그리고 `including` 조건을 `match_mode: any`과(와) 결합할 때 `excluding` 조건이 정책의 범위를 확대함을 주의합니다. OR 논리는 정책이 조건이 일치하면 적용되며, 제외 그룹 조건(제외된 그룹의 프로젝트를 제외한 모든 프로젝트와 일치)은 정책이 `including` 조건에서 지정한 내용과 관계없이 대부분의 프로젝트에 적용됨을 의미합니다.

예를 들어 그룹 목록에서 `group-2`를 제외하고 특정 프로젝트 `group-1/project-1-1` 그리고 `group-2/project-2-1`를 포함하는 정책:

 ```yaml
policy_scope:
  match_mode: any
  groups:
    excluding:
      - id: 200  # group-2
  projects:
    including:
      - id: 101  # group-1/project-1-1
      - id: 201  # group-2/project-2-1
```

이 구성을 사용하면 정책은 명시적으로 포함된 두 프로젝트뿐만 아니라 `group-2` 외부의 다른 모든 프로젝트(포함 프로젝트에 나열되지 않은 `group-1/project-1-2` 등)에도 적용됩니다. 제외 그룹 조건은 `group-2`에 없는 모든 프로젝트와 일치하며, OR 논리를 사용하면 정책이 적용되기 위해 단일 일치로 충분합니다.

### 범위 예제 {#scope-examples}

이 예에서 검사 실행 정책은 모든 릴리스 파이프라인에서 SAST 검사를 적용하고 `2` 또는 `11` ID의 규정 준수 프레임워크가 적용된 모든 프로젝트에 적용합니다.

```yaml
---
scan_execution_policy:
- name: Enforce specified scans in every release pipeline
  description: This policy enforces a SAST scan for release branches
  enabled: true
  rules:
  - type: pipeline
    branches:
    - release/*
  actions:
  - scan: sast
  policy_scope:
    compliance_frameworks:
      - id: 2
      - id: 11
```

이 예에서 검사 실행 정책은 기본 브랜치의 파이프라인에 시크릿 검색 그리고 SAST 검사를 적용하고 ID `203`인 그룹의 모든 프로젝트(모든 하위 그룹 및 해당 프로젝트 포함)에 적용하며 ID `64`인 프로젝트를 제외합니다.

```yaml
- name: Enforce specified scans in every default branch pipeline
  description: This policy enforces secret detection and SAST scans for the default branch
  enabled: true
  rules:
  - type: pipeline
    branches:
    - main
  actions:
  - scan: secret_detection
  - scan: sast
  policy_scope:
    groups:
      including:
        - id: 203
    projects:
      excluding:
        - id: 64
```

이 예에서 검사 실행 정책은 보관된 프로젝트를 제외한 모든 프로젝트에 SAST 검사를 적용합니다. 이는 스캔하면 안 되는 많은 보관된 프로젝트가 있을 때 유용합니다.

```yaml
- name: Enforce SAST scan excluding archived projects
  description: This policy enforces SAST scans but excludes archived projects
  enabled: true
  rules:
  - type: pipeline
    branches:
    - main
  actions:
  - scan: sast
  policy_scope:
    projects:
      excluding:
        - type: archived
```

이 예에서 검사 실행 정책은 `match_mode: any`를 사용하여 특정 우선순위가 높은 프로젝트 또는 특정 그룹 내의 모든 프로젝트에 시크릿 검색 검사를 적용합니다. `match_mode: any` 없이 정책이 적용되려면 프로젝트가 프로젝트 목록에 있어야 하고 지정된 그룹 중 하나에 있어야 합니다.

```yaml
- name: Enforce secret detection on priority projects or security groups
  description: This policy enforces secret detection on specific projects or all projects in security-focused groups
  enabled: true
  rules:
  - type: pipeline
    branches:
    - main
  actions:
  - scan: secret_detection
  policy_scope:
    match_mode: any
    projects:
      including:
        - id: 123  # High-priority project outside of security groups
        - id: 456  # Another critical project
    groups:
      including:
        - id: 78   # Security team's group
        - id: 90   # Compliance team's group
```

## 업무 분담 {#separation-of-duties}

업무 분담은 정책을 성공적으로 구현하는 데 필수적입니다. 필요한 규정 준수 및 보안 요구 사항을 충족하면서 개발 팀이 목표를 달성할 수 있도록 하는 정책을 구현합니다.

보안 및 규정 준수 팀:

- 정책을 정의하고 개발 팀과 함께 정책이 요구 사항을 충족하도록 하는 책임이 있어야 합니다.

개발 팀:

- 어떤 방식으로든 정책을 비활성화, 수정 또는 우회할 수 없어야 합니다.

그룹, 하위 그룹 또는 프로젝트에 보안 정책 프로젝트를 적용하려면 다음 중 하나가 필요합니다:

- 해당 그룹, 하위 그룹 또는 프로젝트의 소유자 역할.
- 해당 그룹, 하위 그룹 또는 프로젝트의 `manage_security_policy_link` 권한이 있는 사용자 지정 역할.

소유자 역할 및 `manage_security_policy_link` 권한이 있는 사용자 지정 역할은 그룹, 하위 그룹 및 프로젝트 전체에서 표준 계층 규칙을 따릅니다:

| 조직 단위 | 그룹 소유자 또는 그룹 `manage_security_policy_link` 권한 | 하위 그룹 소유자 또는 하위 그룹 `manage_security_policy_link` 권한 | 프로젝트 소유자 또는 프로젝트 `manage_security_policy_link` 권한 |
|-------------------|---------------------------------------------------------------|---------------------------------------------------------------------|-------------------------------------------------------------------|
| 그룹             | {{< yes >}} | {{< no >}}  | {{< no >}}  |
| 하위 그룹          | {{< yes >}} | {{< yes >}} | {{< no >}}  |
| 프로젝트           | {{< yes >}} | {{< yes >}} | {{< yes >}} |

### 필수 권한 {#required-permissions}

보안 정책을 생성하고 관리하려면:

- 그룹에 적용된 정책의 경우: 그룹의 Maintainer 또는 Owner 역할이 있어야 합니다.
- 프로젝트에 적용된 정책의 경우:
  - 프로젝트 소유자여야 합니다.
  - 그룹에서 프로젝트를 생성할 권한이 있는 그룹 멤버여야 합니다.

> [!note]
> 그룹 멤버가 아닌 경우 프로젝트의 정책을 추가하거나 편집할 때 제한을 받을 수 있습니다. 정책을 생성하고 관리하는 능력은 그룹에서 프로젝트를 생성할 권한이 필요합니다. 프로젝트 수준 정책으로 작업할 때도 그룹에서 필수 권한이 있는지 확인합니다.

## 정책 권장 사항 {#policy-recommendations}

정책을 구현할 때 다음 권장 사항을 고려합니다.

### 브랜치 이름 {#branch-names}

정책에서 브랜치 이름을 지정할 때 개별 브랜치 이름이 아니라 **기본 브랜치** 또는 **모든 보호된 브랜치**와 같은 보호된 브랜치의 일반 범주를 사용합니다.

정책은 지정된 브랜치가 해당 프로젝트에 존재하는 경우에만 프로젝트에 적용됩니다. 예를 들어 정책이 브랜치 `main`에 규칙을 적용하지만 범위의 일부 프로젝트가 `production`을(를) 기본 브랜치로 사용하고 있는 경우 정책은 후자에 적용되지 않습니다.

### 푸시 규칙 {#push-rules}

GitLab 17.3 이전 버전에서 푸시 규칙을 사용하여 [브랜치 이름 검증](../../project/repository/push_rules.md#validate-branch-names)을(를) 하는 경우 `update-policy-` 접두사를 사용하여 브랜치를 생성할 수 있도록 합니다. 이 브랜치 이름 지정 접두사는 보안 정책이 생성되거나 수정될 때 사용됩니다. 예를 들어 `update-policy-1659094451`은(는) `1659094451`이(가) 타임스탬프입니다. 푸시 규칙이 브랜치 생성을 차단하면 다음 오류가 발생합니다:

```plaintext
Branch name `update-policy-<timestamp>` does not follow the pattern `<branch_name_regex>`.
```

GitLab 17.4 이상에서는 보안 정책 프로젝트가 브랜치 이름 검증을 적용하는 푸시 규칙에서 제외됩니다.

### 보안 정책 프로젝트 {#security-policy-projects}

보안 정책 프로젝트에서 비공개로 유지되도록 하려고 했던 민감한 정보 노출을 방지하려면 보안 정책 프로젝트를 다른 프로젝트에 연결할 때:

- 보안 정책 프로젝트에 민감한 콘텐츠를 포함하지 마세요.
- 비공개 보안 정책 프로젝트를 연결하기 전에 대상 프로젝트의 멤버 목록을 검토하여 모든 멤버가 정책 콘텐츠에 액세스할 수 있는지 확인합니다.
- 대상 프로젝트의 가시성 설정을 평가합니다.
- [보안 정책 관리](../../compliance/audit_event_types.md#security-policy-management) 감사 로그를 사용하여 프로젝트 연결을 모니터링합니다.

이러한 권장 사항은 다음의 이유로 민감한 정보 노출을 방지합니다:

- 공유 가시성: 비공개 보안 프로젝트가 다른 프로젝트에 연결되면 연결된 프로젝트의 **Security Policies** 페이지에 액세스할 수 있는 사용자는 `.gitlab/security-policies/policy.yml` 파일의 콘텐츠를 볼 수 있습니다. 여기에는 비공개 보안 정책 프로젝트를 공개 프로젝트에 연결하는 것이 포함되어 있으며 이는 공개 프로젝트에 액세스할 수 있는 모든 사용자에게 정책 콘텐츠를 노출할 수 있습니다.
- 액세스 제어: 비공개 보안 프로젝트가 연결된 프로젝트의 모든 멤버는 원본 비공개 리포지토리에 액세스할 수 없더라도 **Policy** 페이지에서 정책 파일을 볼 수 있습니다.

### 보안 및 규정 준수 제어 {#security-and-compliance-controls}

프로젝트 maintainer는 그룹의 정책 실행을 방해하는 프로젝트의 정책을 생성할 수 있습니다. 그룹의 정책을 수정할 수 있는 사람을 제한하고 규정 준수 요구 사항이 충족되도록 보장하기 위해 중요한 보안 또는 규정 준수 제어를 구현할 때:

- 사용자 지정 역할을 사용하여 프로젝트 수준에서 파이프라인 실행 정책을(를) 생성하거나 수정할 수 있는 사람을 제한합니다.
- 보안 정책 프로젝트에서 기본 브랜치에 대한 보호된 브랜치를 구성하여 직접 푸시를 방지합니다.
- 보안 정책 프로젝트에서 지정된 승인자의 검토가 필요한 머지 리퀘스트 승인 규칙을(를) 설정합니다.
- 그룹 및 프로젝트 모두에 대한 정책의 모든 정책 변경 사항을 모니터링하고 검토합니다.

## 정책 관리 {#policy-management}

정책 페이지는 사용 가능한 모든 환경에 대해 배포된 정책을 표시합니다. 정책의 정보(예: 설명 또는 적용 상태)를 확인할 수 있으며 배포된 정책을 생성하고 편집할 수 있습니다:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **정책**을(를) 선택합니다.

![정책 목록 페이지](img/policies_list_v17_7.png)

첫 번째 열의 녹색 확인 표시는 정책이 활성화되고 범위 내의 모든 그룹 및 프로젝트에 적용됨을 나타냅니다. 회색 확인 표시는 정책이 현재 활성화되지 않음을 나타냅니다.

## 정책 편집기 {#policy-editor}

정책 편집기에는 두 가지 모드가 있습니다:

- 규칙 모드: 규칙 블록 및 관련 제어를 사용하여 정책 규칙을 생성하고 미리 봅니다.
- YAML 모드: YAML 형식으로 정책 정의를 입력합니다. 규칙 모드가 지원하지 않는 전문가 사용자 및 경우에 적합합니다.

언제든지 규칙 모드와 YAML 모드 간에 전환할 수 있습니다. YAML에 오류가 있거나 지원하지 않는 데이터가 있으면 규칙 모드가 자동으로 꺼집니다. 규칙 모드를 다시 사용하려면 먼저 YAML을 수정합니다.

정책 편집기를 사용하여 정책을 생성, 편집 및 삭제합니다:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **정책**을(를) 선택합니다.
   - 새 정책을 생성하려면 **정책** 페이지 헤더에서 **새 정책**을(를) 선택한 후 정책 유형을 선택합니다.
   - 기존 정책을 편집하려면 선택한 정책 드로어에서 **정책 편집**을(를) 선택합니다.

1. **머지 리퀘스트로 설정**을(를) 선택하여 변경 사항을 저장하고 적용합니다.

   정책의 YAML이 검증되고 결과 오류가 표시됩니다.

1. 결과 머지 리퀘스트를 검토하고 병합합니다.

   프로젝트 소유자이고 이 프로젝트에 보안 정책 프로젝트가 연결되지 않은 경우 머지 리퀘스트를 생성할 때 보안 정책 프로젝트가 생성되고 이 프로젝트에 연결됩니다.

### 표준 및 고급 편집기 레이아웃 {#standard-and-advanced-editor-layouts}

{{< history >}}

- GitLab 17.8에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/450705)되었습니다.

{{< /history >}}

정책 편집기에는 규칙 모드와 YAML 모드가 표시되는 방식을 결정하는 두 가지 레이아웃이 있습니다:

- 표준 편집기: 규칙 모드와 YAML 모드를 별도의 탭으로 표시합니다. 탭을 선택하여 보기를 전환합니다. 규칙 모드에 있을 때 읽기 전용 YAML 미리 보기가 사이드바에 나타납니다.
- 고급 편집기: 규칙 모드와 YAML 모드를 크기를 조정할 수 있는 분할 보기에서 나란히 표시합니다. 한 패널의 변경 사항이 다른 패널에 실시간으로 반영됩니다. 다음을 수행할 수 있습니다.

  - 구분선을 드래그하여 패널 크기를 조정합니다.
  - 한 패널을 축소하여 하나의 보기에 집중합니다.
  - 패널 크기를 재설정하려면 구분선을 두 번 선택합니다.

선호하는 패널 크기는 세션 간에 저장됩니다.

표준 및 고급 편집기 레이아웃 간에 전환하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **정책**을(를) 선택합니다.
   - 새 정책을 생성하려면 **정책** 페이지 헤더에서 **새 정책**을(를) 선택한 후 정책 유형을 선택합니다.
   - 기존 정책을 편집하려면 선택한 정책 드로어에서 **정책 편집**을(를) 선택합니다.

1. 정책 편집기 맨 위에서 **고급 편집기 활성화** 또는 **표준 편집기 활성화**를 선택합니다.

선호 사항이 사용자 계정에 저장되고 세션 간에 유지됩니다.

### `policy.yml`의 ID 주석 {#annotate-ids-in-policyyml}

{{< details >}}

상태: 실험적 기능

{{< /details >}}

{{< history >}}

- GitLab 18.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/497774)되었으며 `annotate_ids` 옵션이 `policy.yml` 파일에 정의된 [실험](../../../policy/development_stages_support.md)입니다.

{{< /history >}}

`policy.yml` 파일을 간소화하기 위해 GitLab은 프로젝트 ID, 그룹 ID, 사용자 ID 또는 규정 준수 프레임워크 ID와 같은 ID 다음에 주석을 자동으로 추가할 수 있습니다. 주석은 각 ID의 의미나 출처를 파악하는 데 도움이 되어 `policy.yml` 파일을 더 쉽게 이해하고 유지할 수 있도록 합니다.

이 실험 기능을 활성화하려면 보안 정책 프로젝트의 `.gitlab/security-policies/policy.yml` 파일에서 `experiments` 섹션에 `annotate_ids` 섹션을 추가합니다:

```yaml
experiments:
  annotate_ids:
    enabled: true
```

옵션을 활성화하면 GitLab [정책 편집기](#policy-editor)를 사용하여 보안 정책을 변경할 때마다 `policy.yml` 파일의 ID 다음에 주석 주석이 생성됩니다.

> [!note]
> 주석을 적용하려면 정책 편집기를 사용해야 합니다. `policy.yml` 파일을 수동으로 편집하는 경우(예: Git 커밋을 사용) 주석이 적용되지 않습니다.

예를 들어:

```yaml
# Example policy.yml with annotated IDs
approval_policy:
- name: Your policy name
  # ... other policy fields ...
  policy_scope:
    projects:
      including:
      - id: 361 # my-group/my-project
  actions:
  - type: require_approval
    approvals_required: 1
    user_approvers_ids:
    - 75 # jane.doe
    group_approvers_ids:
    - 203 # security-approvers
```

> [!note]
> 처음으로 주석을 적용할 때 GitLab은 편집 중이 아닌 정책의 주석을 포함하여 `policy.yml` 파일의 모든 ID에 대한 주석을 생성합니다.

## GitLab 보안 정책 봇 사용자 {#gitlab-security-policy-bot-user}

GitLab 보안 정책 봇은 GitLab 인스턴스 전체에서 보안 정책을 실행하는 내부 사용자입니다. 이 봇은 보안 정책 및 예정된 파이프라인이 제대로 작동하는 데 필수적입니다.

보안 정책 봇은 다음을 담당합니다:

- 예정된 파이프라인 실행: `type: schedule` 규칙이 있는 검사 실행 정책에 정의된 파이프라인을(를) 트리거합니다.
- 컨테이너 검사 자동화: `latest` 태그로 이미지가 푸시될 때 컨테이너 검사 작업을(를) 트리거합니다.
- 정책 적용: 보안 정책에 정의된 대로 보안 검사 및 규정 준수 확인을 실행합니다.
- 파이프라인 생성: 보안 정책이 적용되는 프로젝트에서 정책 기반 파이프라인을(를) 생성하고 관리합니다.

### 계정 특성 {#account-characteristics}

보안 정책 봇의 특성은 다음과 같습니다:

- 보안 정책이 적용되는 모든 프로젝트에서 자동으로 생성됩니다.
- 특정 추가 권한이 있는 프로젝트에서 게스트 역할 권한으로 실행됩니다.
- 내부 사용자로 표시되므로 라이선스 제한에 포함되지 않습니다.
- 각 프로젝트는 정책이 적용될 때 자체 보안 정책 봇 인스턴스를 가집니다.

### 권한 및 액세스 {#permissions-and-access}

보안 정책 봇은 최소하지만 필수적인 권한으로 작동합니다:

- 리포지토리 액세스: 정책 실행에 필요한 리포지토리 콘텐츠에 대한 읽기 전용 액세스.
- 파이프라인 생성: 정책 적용을 위해 파이프라인을(를) 생성하고 트리거하는 기능.
- CI/CD 변수: 변수 우선 순위 규칙에 따라 프로젝트 및 그룹 변수에 액세스합니다.
- 레지스트리 액세스: 적절한 자격 증명으로 구성된 경우 컨테이너 레지스트리에 인증할 수 있습니다.

### 제한 및 제약 {#limitations-and-restrictions}

GitLab 보안 정책 봇의 다음 제한 사항을 주의합니다:

- 수동으로 삭제할 수 없음: UI에서 봇을 삭제할 수 없습니다.
- 수정할 수 없음: 사용자 설정이나 권한을 수동으로 변경할 수 없습니다.
- 프로젝트 바인딩: 각 봇 인스턴스는 특정 프로젝트에 연결되며 프로젝트 간에 인스턴스를 공유할 수 없습니다.
- 정책 종속: 봇의 기능은 프로젝트에 대해 구성된 보안 정책에 완전히 종속됩니다.

### 보안 문제 해결 {#security-troubleshooting}

> [!warning]
> 남용 보고서의 취약성: GitLab 보안 정책 봇 인스턴스는 남용 보고 시스템을 통해 금지되거나 삭제될 수 있으며 예정된 파이프라인이 실행되지 않도록 할 수 있습니다. 관리자는 다음을 인식해야 합니다:
>
> - 보안 정책 봇을 남용으로 보고하면 봇이 금지되거나 삭제될 수 있습니다.
> - 봇을 금지하거나 삭제하면 예정된 파이프라인이 실패합니다.
> - 금지되면 표준 관리 작업을 통해 봇을 복원할 수 없습니다.
> - 봇이 복원될 때까지 보안 정책 적용이 완전히 중단됩니다.
>
> 보안 정책의 우발적인 중단을 방지하기 위해 관리자는 내부 사용자 계정의 남용 보고서를 처리할 때 주의해야 합니다.

보안 정책 봇 기능에 문제가 있는 경우:

#### 예정된 파이프라인이 실행되지 않음 {#scheduled-pipelines-not-running}

예정된 파이프라인이 구성된 대로 실행되지 않는 경우:

- 봇 계정이 존재하고 금지되거나 삭제되지 않았는지 확인합니다.
- 보안 정책 구성이 유효한지 확인합니다.
- 봇이 프로젝트에서 필요한 권한을 가지고 있는지 확인합니다.

#### 정책 작업이 실패하는 경우 {#policy-jobs-failing}

정책 작업이 실패하는 경우:

- 봇이 필요한 CI/CD 변수에 액세스할 수 있는지 확인합니다.
- 참조된 CI/CD 구성 파일이 존재하고 액세스할 수 있는지 확인합니다.
- 파이프라인 로그에서 특정 오류 메시지를 검토합니다.

#### 컨테이너 검사가 트리거되지 않음 {#container-scanning-not-triggering}

컨테이너 검사가 구성된 대로 트리거되지 않는 경우:

- 컨테이너 검사 정책이 제대로 구성되었는지 확인합니다.
- 필요한 경우 봇이 레지스트리 인증 자격 증명을 가지고 있는지 확인합니다.
- `latest` 태그 푸시가 예상된 정책 규칙을 트리거했는지 확인합니다.

#### 봇 계정 누락 {#bot-account-missing}

봇 계정이 더 이상 존재하지 않는 경우:

- 보안 정책을 다시 적용하거나 업데이트하여 봇 계정을 다시 생성합니다.
- 봇이 남용 보고서를 통해 실수로 금지되거나 삭제된 경우 GitLab 관리자에게 문의합니다.

## 문제 해결 {#troubleshooting}

보안 정책으로 작업할 때 다음 문제 해결 팁을 고려합니다:

- 보안 정책 프로젝트를 개발 프로젝트 및 개발 프로젝트가 속한 그룹 또는 하위 그룹 모두에 연결하면 안 됩니다. 이러한 방식으로 연결하면 머지 리퀘스트 승인 정책의 승인 규칙이 개발 프로젝트의 머지 리퀘스트에 적용되지 않습니다.
- 머지 리퀘스트 승인 정책을(를) 생성할 때 `severity_levels` 배열과 `vulnerability_states` 배열 모두 [`scan_finding` 규칙](merge_request_approval_policies.md#scan_finding-rule-type)에서 비워둘 수 없습니다. 작동 규칙의 경우 각 배열에 최소한 하나의 항목이 있어야 합니다.
- 프로젝트의 소유자는 그룹에서 프로젝트를 생성할 권한도 가지고 있으면 해당 프로젝트에 정책을 적용할 수 있습니다. 그룹 멤버가 아닌 프로젝트 소유자는 정책을 추가하거나 편집할 때 제한을 받을 수 있습니다. 프로젝트의 정책을 관리할 수 없으면 그룹 관리자에게 문의하여 그룹에서 필요한 권한이 있는지 확인합니다.
- 정책 충돌의 경우 가장 최근에 적용된 정책이 우선합니다.

여전히 문제가 발생하면 [최근에 보고된 버그를 볼 수](https://gitlab.com/gitlab-org/gitlab/-/issues/?sort=popularity&state=opened&label_name%5B%5D=group%3A%3Asecurity%20policies&label_name%5B%5D=type%3A%3Abug&first_page_size=20) 있고 새로운 미보고 이슈를 제기할 수 있습니다.

### GraphQL API를 사용하여 정책 다시 동기화 {#resynchronize-policies-with-the-graphql-api}

정책의 일관성이 없는 경우(예: 정책이 적용되지 않거나 승인이 잘못된 경우) GraphQL `resyncSecurityPolicies` 뮤테이션을 사용하여 정책의 동기화를 수동으로 강제할 수 있습니다:

```graphql
mutation {
  resyncSecurityPolicies(input: { fullPath: "group-or-project-path" }) {
    errors
  }
}
```

`fullPath`를 보안 정책 프로젝트가 할당된 프로젝트 또는 그룹의 경로로 설정합니다.

#### GraphQL API를 사용하여 프로젝트 다시 동기화 {#resynchronize-projects-with-the-graphql-api}

영향을 받는 프로젝트가 그룹 또는 하위 그룹에서 정책을 상속하는 경우 해당 프로젝트만 다시 동기화할 수 있습니다:

```graphql
mutation {
  resyncSecurityPolicies(
    input: {
      fullPath: "project-path"
      relationship: INHERITED
    }
  ) {
    errors
  }
}
```

`fullPath`를 정책을 상속하는 프로젝트의 경로로 설정합니다. `relationship: INHERITED`를 사용하여 전체 그룹 또는 하위 그룹을 다시 동기화하지 않고 해당 프로젝트가 상속한 정책을 다시 동기화합니다.
