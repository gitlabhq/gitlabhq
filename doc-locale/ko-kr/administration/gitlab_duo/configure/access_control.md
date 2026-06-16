---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Duo에 대한 액세스를 구성합니다.
title: GitLab Duo에 대한 액세스 구성
---

{{< details >}}

- 계층:  [무료](../../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [GitLab 18.8에서 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/583909).

{{< /history >}}

그룹에 대해 [GitLab Duo를 켜거나 끌](../../../user/duo_agent_platform/turn_on_off.md#turn-gitlab-duo-on-or-off) 수 있거나 하나 이상의 그룹에 대해 GitLab Duo에 대한 액세스를 제한할 수 있습니다.

## GitLab Duo에 대한 액세스 제한 {#restrict-access-to-gitlab-duo}

{{< history >}}

- 기본 **No group** 규칙이 GitLab 18.10에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/225728).
- **Member access** 섹션과 **No group** 규칙이 GitLab 18.11에서 [이름이 바뀌었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/229785).

{{< /history >}}

{{< tabs >}}

{{< tab title="GitLab.com" >}}

전제 조건:

- 최상위 그룹의 소유자(Owner) 역할.

최상위 그룹에 대해 GitLab Duo에 대한 액세스를 제한하려면:

1. 위쪽 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **GitLab Duo**를 선택합니다.
1. **구성 변경**을 선택합니다.
1. **Restrict access based on group membership** 아래에서 **그룹 추가**를 선택합니다.
1. 드롭다운 목록에서 그룹을 선택합니다.

   첫 번째 그룹을 선택하면 기본 **모든 대상 사용자** 규칙도 추가됩니다. 이 규칙을 사용하여 다른 모든 사용자의 액세스를 구성할 수 있습니다. 그룹이 GitLab Duo Non-Agentic 또는 GitLab Duo Agent Platform에 대한 액세스 권한이 없고 모든 기존 그룹이 제거될 때 이 규칙이 자동으로 삭제됩니다.

1. 그룹의 직접 멤버가 GitLab Duo Non-Agentic 및 GitLab Duo Agent Platform에 액세스할 수 있는지 여부를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

이 설정은 다음 사용자에게 적용됩니다:

- **Restrict access based on group membership** 아래에 구성된 그룹 중 하나의 직접 멤버이며 최상위 그룹의 프로젝트 또는 하위 그룹에서 AI 작업을 실행하는 사용자입니다.
- 최상위 그룹을 [기본 GitLab Duo 네임스페이스](../../../user/profile/preferences.md#set-a-default-gitlab-duo-namespace)로 설정했지만 AI 작업이 실행되는 최상위 그룹의 멤버가 아닌 사용자입니다.

액세스 제어를 구성할 때 최상위 그룹의 직접 하위 그룹인 그룹만 선택할 수 있습니다. 액세스 제어 규칙에서 중첩된 하위 그룹을 사용할 수 없습니다.

{{< /tab >}}

{{< tab title="GitLab Self-Managed" >}}

전제 조건:

- 관리자 액세스.

인스턴스에 대해 GitLab Duo에 대한 액세스를 제한하려면:

1. 우측 상단 모서리에서 **운영자**를 선택하세요.
1. 왼쪽 사이드바에서 **GitLab Duo**를 선택합니다.
1. **구성 변경**을 선택합니다.
1. **Restrict access based on group membership** 아래:
   - 기존 그룹을 추가하려면 **그룹 추가**를 선택합니다.
   - 새 그룹을 만들려면 **그룹 생성**을 선택합니다.
1. 드롭다운 목록에서 그룹을 선택합니다.

   첫 번째 그룹을 선택하면 기본 **모든 대상 사용자** 규칙도 추가됩니다. 이 규칙을 사용하여 다른 모든 사용자의 액세스를 구성할 수 있습니다. 그룹이 GitLab Duo Non-Agentic 또는 GitLab Duo Agent Platform에 대한 액세스 권한이 없고 모든 기존 그룹이 제거될 때 이 규칙이 자동으로 삭제됩니다.

1. 그룹의 직접 멤버가 GitLab Duo Non-Agentic 및 GitLab Duo Agent Platform에 액세스할 수 있는지 여부를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

이 설정은 **Restrict access based on group membership** 아래에 구성된 그룹 중 하나의 직접 멤버인 사용자에게 적용됩니다.

액세스 제어를 구성할 때 최상위 그룹만 선택할 수 있습니다. 액세스 제어 규칙에서 하위 그룹을 사용할 수 없습니다.

{{< /tab >}}

{{< /tabs >}}

그룹 멤버십을 수동으로 관리하지 않으려면 [LDAP 또는 SAML을 사용하여 멤버십을 동기화](#synchronize-group-membership)할 수 있습니다.

### 그룹 멤버십 {#group-membership}

사용자가 하나 이상의 그룹에 할당되면 사용자는 할당된 모든 그룹의 기능에 액세스할 수 있습니다. 예를 들어 사용자가 그룹 A의 GitLab Duo Non-Agentic 및 그룹 B의 GitLab Duo Agent Platform에 액세스할 수 있으면 사용자는 두 기능 세트에 모두 액세스할 수 있습니다.

**모든 대상 사용자** 규칙이 구성되면 다음 사용자가 GitLab Duo Non-Agentic 및 GitLab Duo Agent Platform에 모두 액세스할 수 있습니다:

- GitLab.com에서:  최상위 그룹의 모든 멤버.
- GitLab Self-Managed에서:  모든 사용자.

추가 제어(예: 최상위 그룹 또는 인스턴스의 기능 비활성화)가 계속 적용됩니다.

#### 그룹 멤버십 동기화 {#synchronize-group-membership}

인증을 위해 LDAP 또는 SAML을 사용하는 경우 그룹 멤버십을 자동으로 동기화할 수 있습니다:

1. LDAP 또는 SAML 공급자를 구성하여 GitLab Duo Agent Platform 사용자를 나타내는 그룹을 포함합니다.
1. GitLab에서 그룹이 LDAP 또는 SAML 공급자에 연결되어 있는지 확인합니다.
1. 공급자 그룹에서 사용자를 추가하거나 제거할 때 그룹 멤버십이 자동으로 업데이트됩니다.

자세한 정보는 다음을 참조하세요:

- [LDAP 그룹 동기화](../../auth/ldap/_index.md)
- [GitLab Self-Managed용 SAML](../../../integration/saml.md)
- [GitLab.com용 SAML](../../../user/group/saml_sso/_index.md)

## 액세스 제어 사용 {#using-access-control}

단계적 롤아웃 또는 테스트 및 유효성 검사를 위해 액세스 제어를 사용할 수 있습니다.

### 단계적 롤아웃 {#phased-rollouts}

GitLab Duo의 단계적 롤아웃을 구현하려면:

1. 파일럿 사용자를 위한 그룹을 만듭니다(예: `pilot-users`).
1. 사용자 하위 집합을 이 그룹에 추가합니다.
1. 기능을 유효성 검사하고 사용자를 교육하면서 그룹에 사용자를 점진적으로 추가합니다.
1. 전체 롤아웃을 준비할 때 모든 사용자를 그룹에 추가합니다.

### 테스트 및 유효성 검사 {#testing-and-validation}

제어된 환경에서 GitLab Duo 기능을 테스트하려면:

1. 테스트를 위한 전용 그룹을 만듭니다(예: `agent-testers`).
1. 테스트 그룹 또는 프로젝트를 만듭니다.
1. `agent-testers` 그룹에 테스트 사용자를 추가합니다.
1. 더 광범위한 롤아웃 전에 기능을 유효성 검사하고 사용자를 교육합니다.

## 문제 해결 {#troubleshooting}

### 사용자가 GitLab Duo 기능에 액세스할 수 없음 {#user-cannot-access-gitlab-duo-features}

사용자는 다음 시나리오에서 GitLab Duo 기능에 액세스할 수 없습니다:

- 그룹에 대해 GitLab Duo Non-Agentic 또는 GitLab Duo Agent Platform에 대한 액세스가 구성되지 않았습니다.
- 그룹에 대해 GitLab Duo Non-Agentic 또는 GitLab Duo Agent Platform에 대한 액세스가 구성되었지만 다음 중 하나가 적용됩니다:
  - 사용자는 그룹의 직접 멤버가 아닙니다.
  - **모든 대상 사용자** 규칙이 구성되지 않았습니다.

이 문제를 해결하려면 다음 중 하나를 수행합니다:

- 사용자를 구성된 그룹 중 하나에 직접 멤버로 추가합니다.
- **모든 대상 사용자**에게 GitLab Duo Non-Agentic 또는 GitLab Duo Agent Platform에 대한 액세스 권한을 부여합니다.
- 모든 그룹 멤버십 액세스 규칙을 제거합니다.

### 특정 그룹에 대해 GitLab Duo 사이드바가 표시되지 않음 {#gitlab-duo-sidebar-does-not-display-for-certain-groups}

GitLab 18.8 이전 버전에서 그룹에 GitLab Duo Agent Platform에 대한 액세스 권한은 주지만 GitLab Duo Non-Agentic에 대한 액세스 권한을 주지 않으면 해당 그룹의 멤버에 대해 GitLab Duo 사이드바가 표시되지 않습니다. 해결 방법으로 그룹이 GitLab Duo Non-Agentic 및 GitLab Duo Agent Platform 모두에 대한 액세스 권한을 갖도록 합니다.

이 문제를 해결하려면 GitLab 18.9 이상으로 업그레이드합니다.
