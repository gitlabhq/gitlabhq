---
stage: Fulfillment
group: Seat Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Duo 구독 추가 기능을 알아보고 사용자를 할당합니다.
title: GitLab Duo 추가 기능
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.0에서 GitLab Duo Core 추가 기능을 포함하도록 변경되었습니다.
- GitLab 18.3 버전부터 UI 내 GitLab Duo Non-Agentic Chat 기능이 [Core 티어에 추가](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201721)되었습니다.
- GitLab 18.4 버전부터 [셀프 매니지드 환경에서 사용자 할당 알림 이메일을 비활성화하는 기능이 추가되었습니다.](https://gitlab.com/gitlab-org/gitlab/-/issues/557290)

{{< /history >}}

GitLab Duo 추가 기능은 프리미엄 또는 얼티밋 구독에 AI 네이티브 기능을 제공합니다. GitLab Duo를 사용하여 개발 워크플로우를 가속화하고, 반복되는 코딩 작업을 줄이며, 프로젝트 전반에 걸쳐 더 깊은 인사이트를 얻을 수 있습니다.

세 가지 추가 기능을 사용할 수 있습니다:  GitLab Duo Core, Pro, Enterprise.

각 추가 기능은 [GitLab Duo 기능 모음](../user/gitlab_duo/feature_summary.md)에 대한 액세스를 제공합니다.

## GitLab Duo Core {#gitlab-duo-core}

{{< history >}}

- GitLab Duo Core 고객을 위해 GitLab 19.0의 일부로 2026년 5월 21일에 GitLab Duo Non-Agentic Chat에 대한 액세스가 제거되었습니다. `no_duo_classic_for_duo_core_users` 기능 플래그를 사용하여 제거되었습니다. 기본적으로 활성화됨.

{{< /history >}}

다음 조건을 충족하면 GitLab Duo Core가 자동으로 포함됩니다:

- GitLab 18.0 이상.
- 프리미엄 또는 얼티밋 구독.

GitLab 17.11 이전의 기존 고객인 경우 [GitLab Duo Core 기능을 켜야 합니다](../user/gitlab_duo/turn_on_off.md#turn-gitlab-duo-core-on-or-off).

GitLab 18.0 이상의 신규 고객인 경우 GitLab Duo Core 기능이 자동으로 활성화되므로 추가 조치가 필요하지 않습니다.

GitLab Duo Core에 액세스할 수 있는 역할을 보려면 [GitLab Duo 그룹 권한](../user/permissions.md#group-gitlab-duo)을 참조하세요.

### GitLab Duo Self-Hosted {#gitlab-duo-self-hosted}

오프라인 라이선스가 있는 경우 GitLab Duo Core가 GitLab AI Gateway에 연결을 요구하므로 GitLab Duo Self-Hosted에서 사용할 수 없습니다.

온라인 라이선스가 있는 경우 GitLab Duo Core를 GitLab Duo Self-Hosted와 함께 사용할 수 있습니다. GitLab Duo Core를 사용하려면 인스턴스에 대해 Code Suggestions의 GitLab 관리형 모델을 선택해야 합니다.

### GitLab Duo Core 제한 {#gitlab-duo-core-limits}

프리미엄 및 얼티밋 고객의 경우 GitLab Duo Core는 Code Suggestions에 대한 액세스를 포함하며 GitLab 19.0 이상에서는 GitLab Duo Agentic Chat을 포함합니다.

이러한 기능에 대한 액세스는 [GitLab 서비스 약관](https://about.gitlab.com/terms/) 및 [사용량 청구](gitlab_credits.md)를 따릅니다.

GitLab은 이러한 제한 사항을 적용하기 전에 30일 미리 알립니다. 그 시점에서 조직 관리자는 소비를 모니터링하고 관리할 수 있는 도구를 갖게 되며 추가 용량을 구매할 수 있습니다.

제한은 GitLab Duo Pro 또는 Enterprise에 적용되지 않습니다.

### GitLab Duo Core 기능 액세스 변경 사항 {#changes-to-gitlab-duo-core-feature-access}

2026년 5월 21일부터 모든 GitLab 버전의 GitLab Duo Core 사용자는 GitLab Duo Non-Agentic Chat에 액세스할 수 없습니다.

대신, GitLab Duo Core 사용자는 다음 GitLab Duo Agent Platform 기능을 사용하여 질문에 답하고 논-에이전트 기능이 수행했을 작업을 완료할 수 있습니다:

- GitLab Duo Agentic Chat.
- 기본, 사용자 지정, 외부 에이전트.
- 기본 및 사용자 지정 플로우.
- GitLab Duo Code Suggestions.

이러한 기능을 사용하려면 [GitLab Credits](gitlab_credits.md)가 필요합니다.

Agent Platform을 사용하는 방법에 대한 자세한 내용은 다음을 참조하세요:

- [GitLab Duo Chat 프롬프트 예시](../user/gitlab_duo_chat/example_prompts.md)
- [에이전트](../user/duo_agent_platform/agents/_index.md)
- [플로우](../user/duo_agent_platform/flows/_index.md)

## GitLab Duo Pro and Enterprise {#gitlab-duo-pro-and-enterprise}

GitLab Duo Pro 및 Enterprise를 사용하려면 사용자를 구매하고 팀원에게 할당해야 합니다. 사용자 기반 모델을 사용하면 기능 액세스 및 비용 관리를 특정 팀 요구 사항에 따라 제어할 수 있습니다.

## GitLab Duo Agent Platform Self-Hosted {#gitlab-duo-agent-platform-self-hosted}

{{< details >}}

- 제공:  GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 18.8에서 도입되었습니다

{{< /history >}}

오프라인 라이선스를 보유한 고객은 Agent Platform에서 자체 호스팅 모델을 사용하기 위해 GitLab Duo Agent Platform Self-Hosted 추가 기능을 구매해야 합니다.

이 추가 기능을 보유한 고객은 [사용량](gitlab_credits.md) 대신 사용자 기준으로 청구됩니다.

온라인 라이선스를 보유한 고객은 추가 기능 없이 Agent Platform에서 자체 호스팅 모델을 사용할 수 있으며 사용량 기준으로 청구됩니다.

GitLab Duo Agent Platform Self-Hosted를 구매하려면 [GitLab 영업팀](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/)에 문의하세요.

## GitLab Duo 구매 {#purchase-gitlab-duo}

GitLab Duo Enterprise를 구매하려면 [GitLab 영업팀](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/)에 문의하세요.

GitLab Duo Pro의 사용자를 구매하려면 Customers Portal을 사용하거나 [GitLab 영업팀](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/)에 문의하세요.

포털을 사용하려면:

1. [GitLab Customers Portal](https://customers.gitlab.com/)에 로그인하세요.
1. 구독 카드에서 세로 줄임표({{< icon name="ellipsis_v" >}})를 선택합니다.
1. **Buy GitLab Duo Pro**를 선택합니다.
1. GitLab Duo의 사용자 수를 입력합니다.
1. **Purchase summary** 섹션을 검토합니다.
1. **Payment method** 드롭다운 목록에서 결제 방법을 선택합니다.
1. **사용자 구매**를 선택합니다.

## GitLab Duo 사용자 추가 구매 {#purchase-additional-gitlab-duo-seats}

그룹 네임스페이스 또는 GitLab Self-Managed 인스턴스에 대해 추가 GitLab Duo Pro 또는 GitLab Duo Enterprise 사용자를 구매할 수 있습니다. 구매를 완료한 후 사용자가 구독의 총 GitLab Duo 사용자 수에 추가됩니다.

전제 조건:

- GitLab Duo Pro 또는 GitLab Duo Enterprise 추가 기능을 구매해야 합니다.

### GitLab.com {#for-gitlabcom}

전제 조건:

- 소유자 역할이 있어야 합니다.

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **GitLab Duo**를 선택합니다.
1. **사용자 활용도**에서 **사용자 할당**을 선택합니다.
1. **사용자 구매**를 선택합니다.
1. Customers Portal의 **추가 사용자** 필드에 사용자 수를 입력합니다. 금액은 그룹 네임스페이스와 연결된 구독의 사용자 수보다 높을 수 없습니다.
1. **Billing information** 섹션에서 드롭다운 목록의 결제 방법을 선택합니다.
1. **Privacy Policy** 및 **Terms of Service** 체크박스를 선택합니다.
1. **사용자 구매**를 선택합니다.
1. **GitLab SaaS** 탭을 선택하고 페이지를 새로 고칩니다.

### GitLab Self-Managed 및 GitLab Dedicated {#for-gitlab-self-managed-and-gitlab-dedicated}

전제 조건:

- 관리자여야 합니다.

1. [GitLab Customers Portal](https://customers.gitlab.com/)에 로그인하세요.
1. 구독 카드의 **GitLab Duo Pro** 섹션에서 **사용자 추가**를 선택합니다.
1. 사용자 수를 입력합니다. 금액은 구독의 사용자 수보다 높을 수 없습니다.
1. **Purchase summary** 섹션을 검토합니다.
1. **Payment method** 드롭다운 목록에서 결제 방법을 선택합니다.
1. **사용자 구매**를 선택합니다.

## GitLab Duo 사용자 할당 {#assign-gitlab-duo-seats}

전제 조건:

- GitLab Duo Pro 또는 Enterprise 추가 기능을 구매하거나 활성 GitLab Duo 체험판을 보유해야 합니다.
- GitLab Self-Managed 및 GitLab Dedicated:
  - GitLab Duo Pro 추가 기능은 GitLab 16.8 이상에서 사용할 수 있습니다.
  - GitLab Duo Enterprise 추가 기능은 GitLab 17.3 이상에서만 사용할 수 있습니다.

GitLab Duo Pro 또는 Enterprise를 구매한 후 사용자를 할당하여 추가 기능에 대한 액세스를 부여할 수 있습니다.

### GitLab.com {#for-gitlabcom-1}

전제 조건:

- 소유자 역할이 있어야 합니다.

모든 프로젝트 또는 그룹에서 GitLab Duo 기능을 사용하려면 사용자를 최소한 하나의 최상위 그룹의 사용자에 할당해야 합니다.

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **GitLab Duo**를 선택합니다.
1. **사용자 활용도**에서 **사용자 할당**을 선택합니다.
1. 사용자의 오른쪽에서 토글을 켜서 GitLab Duo 사용자를 할당합니다.

사용자에게 확인 이메일이 전송됩니다.

### GitLab Self-Managed {#for-gitlab-self-managed}

전제 조건:

- 관리자여야 합니다.

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **GitLab Duo**를 선택합니다.
   - **GitLab Duo** 메뉴 항목을 사용할 수 없으면 구매 후 구독을 동기화합니다:
     1. 왼쪽 사이드바에서 **구독**을 선택합니다.
     1. **구독 세부정보**에서 **마지막 동기화**의 오른쪽에서 구독 동기화({{< icon name="retry" >}})를 선택합니다.
1. **사용자 활용도**에서 **사용자 할당**을 선택합니다.
1. 사용자의 오른쪽에서 토글을 켜서 GitLab Duo 사용자를 할당합니다.

사용자에게 확인 이메일이 전송됩니다.

- 이 이메일을 비활성화하려면 `sm_duo_seat_assignment_email` 기능 플래그를 `false`로 설정합니다. 이 플래그는 기본적으로 활성화되어 있습니다.

사용자를 할당한 후 [GitLab Self-Managed 인스턴스에 대해 GitLab Duo가 설정되어 있는지 확인합니다](../administration/gitlab_duo/configure/gitlab_self_managed.md).

## GitLab Duo 사용자 대량 할당 및 제거 {#assign-and-remove-gitlab-duo-seats-in-bulk}

여러 사용자에 대해 사용자를 대량으로 할당 또는 제거할 수 있습니다.

### SAML Group Sync {#saml-group-sync}

GitLab.com 그룹은 SAML Group Sync를 사용하여 [GitLab Duo 사용자 할당을 관리](../user/group/saml_sso/group_sync.md#manage-gitlab-duo-seat-assignment)할 수 있습니다.

### GitLab.com {#for-gitlabcom-2}

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **GitLab Duo**를 선택합니다.
1. 오른쪽 아래에서 **50** 또는 **100** 항목을 표시하도록 페이지 표시를 조정하여 선택 가능한 사용자 수를 늘릴 수 있습니다.
1. 사용자를 할당 또는 제거할 사용자를 선택합니다:
   - 여러 사용자를 선택하려면 각 사용자의 왼쪽에서 체크박스를 선택합니다.
   - 모두 선택하려면 테이블 맨 위의 체크박스를 선택합니다.
1. 사용자를 할당 또는 제거합니다:
   - 사용자를 할당하려면 **사용자 할당**을 선택한 후 **사용자 할당**을 선택하여 확인합니다.
   - 사용자를 사용자에서 제거하려면 **사용자 삭제**를 선택한 후 **사용자 삭제**를 선택하여 확인합니다.

### GitLab Self-Managed {#for-gitlab-self-managed-1}

전제 조건:

- 관리자여야 합니다.
- GitLab 17.5 이상이 필요합니다.

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **GitLab Duo**를 선택합니다.
1. 오른쪽 아래에서 **50** 또는 **100** 항목을 표시하도록 페이지 표시를 조정하여 선택 가능한 사용자 수를 늘릴 수 있습니다.
1. 사용자를 할당 또는 제거할 사용자를 선택합니다:
   - 여러 사용자를 선택하려면 각 사용자의 왼쪽에서 체크박스를 선택합니다.
   - 모두 선택하려면 테이블 맨 위의 체크박스를 선택합니다.
1. 사용자를 할당 또는 제거합니다:
   - 사용자를 할당하려면 **사용자 할당**을 선택한 후 **사용자 할당**을 선택하여 확인합니다.
   - 사용자를 사용자에서 제거하려면 **사용자 삭제**를 선택한 후 **사용자 삭제**를 선택하여 확인합니다.
1. 사용자의 오른쪽에서 토글을 켜서 GitLab Duo 사용자를 할당합니다.

GitLab Self-Managed 인스턴스의 관리자는 [Rake 작업](../administration/raketasks/user_management.md#bulk-assign-users-to-gitlab-duo)을 사용하여 대량으로 사용자를 할당 또는 제거할 수도 있습니다.

#### LDAP 구성으로 GitLab Duo 사용자 관리 {#managing-gitlab-duo-seats-with-ldap-configuration}

LDAP 그룹 멤버십을 기반으로 LDAP 지원 사용자에 대해 GitLab Duo 사용자를 자동으로 할당 및 제거할 수 있습니다.

이 기능을 활성화하려면 LDAP 설정에서 [`duo_add_on_groups` 속성을 구성](../administration/auth/ldap/ldap_synchronization.md#gitlab-duo-add-on-for-groups)해야 합니다.

`duo_add_on_groups`이 구성되면 LDAP 지원 사용자 간의 GitLab Duo 사용자 관리를 위한 단일 소스 정보 제공 시스템이 됩니다. 자세한 내용은 [사용자 할당 워크플로우](../administration/duo_add_on_seat_management_with_ldap.md#seat-management-workflow)를 참조하세요.

이 자동화된 프로세스는 GitLab Duo 사용자가 조직의 LDAP 그룹 구조를 기반으로 효율적으로 할당되도록 합니다. 자세한 내용은 [LDAP를 사용한 GitLab Duo 추가 기능 사용자 관리](../administration/duo_add_on_seat_management_with_ldap.md)를 참조하세요.

## 할당된 GitLab Duo 사용자 보기 {#view-assigned-gitlab-duo-users}

{{< history >}}

- 마지막 GitLab Duo 활동 필드가 GitLab 18.0에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/455761).

{{< /history >}}

전제 조건:

- GitLab Duo Pro 또는 Enterprise 추가 기능을 구매하거나 활성 GitLab Duo 체험판을 보유해야 합니다.

GitLab Duo Pro 또는 Enterprise를 구매한 후 사용자를 할당하여 추가 기능에 대한 액세스를 부여할 수 있습니다. 그런 다음 할당된 GitLab Duo 사용자의 세부 정보를 볼 수 있습니다.

GitLab Duo 사용자 활용도 페이지는 각 사용자에 대해 다음 정보를 표시합니다:

- 사용자의 전체 이름 및 사용자 이름
- 사용자 할당 상태
- 공개 이메일 주소:  사용자의 공개 프로필에 표시된 이메일입니다.
- 마지막 GitLab 활동:  사용자가 GitLab에서 마지막으로 작업을 수행한 날짜입니다.
- 마지막 GitLab Duo 활동:  사용자가 마지막으로 GitLab Duo 기능을 사용한 날짜입니다. 모든 GitLab Duo 활동에서 새로 고쳐집니다.

이 필드는 `AddOnUser` 유형의 [GraphQL API](../api/graphql/reference/_index.md#addonuser)의 데이터를 사용합니다.

### GitLab.com {#for-gitlabcom-3}

전제 조건:

- 소유자 역할이 있어야 합니다.

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **GitLab Duo**를 선택합니다.
1. **사용자 활용도**에서 **사용자 할당**을 선택합니다.
1. 필터 표시줄에서 **할당된 사용자** 및 **예**를 선택합니다.
1. 사용자 목록이 GitLab Duo 사용자가 할당된 사용자만으로 필터링됩니다.

### GitLab Self-Managed {#for-gitlab-self-managed-2}

전제 조건:

- 관리자여야 합니다.
- GitLab 17.5 이상이 필요합니다.

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **GitLab Duo**를 선택합니다.
   - **GitLab Duo** 메뉴 항목을 사용할 수 없으면 구매 후 구독을 동기화합니다:
     1. 왼쪽 사이드바에서 **구독**을 선택합니다.
     1. **구독 세부정보**에서 **마지막 동기화**의 오른쪽에서 구독 동기화({{< icon name="retry" >}})를 선택합니다.
1. **사용자 활용도**에서 **사용자 할당**을 선택합니다.
1. GitLab Duo 사용자가 할당된 사용자로 필터링하려면 **사용자 필터링** 표시줄에서 **할당된 사용자**를 선택한 후 **예**를 선택합니다.
1. 사용자 목록이 GitLab Duo 사용자가 할당된 사용자만으로 필터링됩니다.

## 자동 사용자 제거 {#automatic-seat-removal}

GitLab Duo 추가 기능 사용자는 적격 사용자만 액세스할 수 있도록 자동으로 제거됩니다. 다음과 같은 경우에 발생합니다:

- 사용자 초과
- 차단됨, 금지됨, 비활성화된 사용자

### 구독 만료 시 {#at-subscription-expiration}

GitLab Duo 추가 기능이 포함된 구독이 만료되면 사용자 할당이 28일 동안 유지됩니다. 이 28일 기간 동안 구독이 갱신되거나 GitLab Duo가 포함된 새 구독이 구매되면 사용자가 자동으로 재할당됩니다. 그렇지 않으면 사용자 할당이 제거되고 사용자를 다시 할당해야 합니다.

### 사용자 초과의 경우 {#for-seat-overages}

구매한 GitLab Duo 추가 기능 사용자 수량이 감소하면 구독에서 사용 가능한 사용자 수량과 일치하도록 사용자 할당이 자동으로 제거됩니다.

예를 들어:

- 모든 사용자가 할당된 50 사용자 GitLab Duo Pro 구독이 있습니다.
- 30 사용자에 대한 구독을 갱신합니다. 구독 초과 20 사용자가 GitLab Duo Pro 사용자 할당에서 자동으로 제거됩니다.
- 갱신 전에 20명의 사용자만 GitLab Duo Pro 사용자에 할당된 경우 사용자 제거가 발생하지 않습니다.

사용자는 다음 기준에 따라 이 순서로 제거되도록 선택됩니다:

1. Code Suggestions를 아직 사용하지 않은 사용자(가장 최근에 할당된 순).
1. Code Suggestions를 사용한 사용자(Code Suggestions의 가장 최근 사용 순서).

### 차단됨, 금지됨, 비활성화된 사용자 {#for-blocked-banned-and-deactivated-users}

하루에 한 두 번, CronJob이 GitLab Duo 사용자 할당을 검토합니다. GitLab Duo 사용자가 할당된 사용자가 차단되거나, 금지되거나, 비활성화되면 GitLab Duo 기능에 대한 액세스가 자동으로 제거됩니다.

사용자가 제거된 후 새 사용자에게 재할당할 수 있습니다.

## 문제 해결 {#troubleshooting}

### 사용자에게 사용자를 할당하기 위해 UI를 사용할 수 없습니다 {#unable-to-use-the-ui-to-assign-seats-to-your-users}

**사용 할당량** 페이지에서 다음 두 가지를 모두 경험하면 사용자에게 사용자를 할당하기 위해 UI를 사용할 수 없습니다:

- **사용자** 탭이 로드되지 않습니다.
- 다음 오류 메시지가 표시됩니다:

  ```plaintext
  An error occurred while loading billable members list.
  ```

해결 방법으로 [이 스니펫](https://gitlab.com/gitlab-org/gitlab/-/snippets/3763094)의 GraphQL 쿼리를 사용하여 사용자에게 사용자를 할당할 수 있습니다.
