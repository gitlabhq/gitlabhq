---
stage: Fulfillment
group: Seat Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab 구독과 관련된 사용자 및 사용자를 관리합니다.
title: 사용자 관리
---

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

사용자 관리는 구독에서 어느 사용자가 사용자를 차지하는지 제어하고 모니터링하는 프로세스입니다. 효과적인 사용자 관리는 비용을 제어하고, 예상치 못한 초과 요금을 방지하며, 팀 구성원이 필요한 액세스 권한을 가지도록 보장합니다.

## 청구 가능한 사용자 {#billable-users}

청구 가능한 사용자는 구독에서 사용자를 차지하고 구독에서 구매한 사용자 수에 포함되는 사용자입니다.

다음 사용자가 청구 가능한 사용자로 계산됩니다:

- 구독의 네임스페이스 또는 최상위 그룹에 액세스할 수 있는 사용자(직접 [members](../user/project/members/_index.md#membership-types), 상속된 구성원, 이러한 역할 중 하나로 초대된 사용자 포함):
  - 게스트(Premium에서 청구 가능, Free 및 Ultimate에서 비청구 가능)
  - Planner
  - Reporter
  - Security Manager
  - Developer
  - Maintainer
  - Owner
  - [사용자 지정 역할](../user/custom_roles/_index.md), `read_code` 권한만 있는 사용자 지정 게스트 구성원 역할 제외
- [감사자 사용자](../administration/auditor_users.md)
- 관리자(GitLab Self-Managed의 Premium 및 Ultimate 티어)
- 네임스페이스 액세스가 없는 사용자(GitLab Self-Managed의 Premium 티어)

현재 구독 기간 동안 사용자를 차단하거나, 비활성화하거나, 인스턴스 또는 그룹에 추가하면 청구 가능한 사용자 수가 변경됩니다. 사용자가 같은 최상위 그룹에 속하는 여러 그룹 또는 프로젝트에 있으면 한 번만 계산됩니다.

사용자 사용량은 [분기별 또는 연간](quarterly_reconciliation.md) 검토됩니다.

의도하지 않은 사용자 추가로 인한 초과 요금을 방지하려면 다음을 수행해야 합니다:

- [그룹 계층 구조 외부의 그룹 초대 방지](../user/project/members/sharing_projects_groups.md#prevent-inviting-groups-outside-the-group-hierarchy).
- 제한된 액세스를 활성화합니다.

## 비청구 가능한 사용자에 대한 기준 {#criteria-for-non-billable-users}

다음의 경우 사용자는 청구 가능한 사용자로 계산되지 않습니다:

- 승인 대기 중입니다.
- [비활성화](../administration/moderate_users.md#deactivate-a-user), [차단](../user/group/moderate_users.md#ban-a-user), 또는 [차단](../administration/moderate_users.md#block-a-user)된 상태입니다.
- 프로젝트 또는 그룹의 구성원이 아닙니다(Ultimate 구독만 해당).
- 게스트 역할만 있습니다(Ultimate 구독만 해당).
- [최소 액세스 역할](../user/permissions.md#users-with-minimal-access)만 있습니다.
- 계정이 GitLab에서 만든 서비스 계정입니다:
  - [Ghost User](../user/profile/account/delete_account.md#associated-records).
  - 봇:
    - [Support Bot](../user/project/service_desk/configure.md#support-bot-user).
    - [프로젝트용 봇 사용자](../user/project/settings/project_access_tokens.md#bot-users-for-projects).
    - [그룹용 봇 사용자](../user/group/settings/group_access_tokens.md#bot-users-for-groups).
    - 기타 [내부 사용자](../administration/internal_users.md).

## 구독 한도를 초과한 사용자 {#users-over-subscription-limit}

인스턴스 또는 최상위 그룹의 청구 가능한 사용자 수가 구매한 사용자 수를 초과하면 구독 초과 사용자(또는 청구될 사용자)가 있습니다.

이는 예를 들어 인스턴스 또는 그룹에 새 사용자가 추가되거나 기존 사용자가 청구 가능한 역할로 승격될 때 발생할 수 있습니다.

구독 초과 사용자 수는 다음과 같이 계산됩니다: 청구 기간 동안의 최대 사용자 - 구독에서 구매한 사용자.

예를 들어 10개 사용자에 대한 구독을 구매하고 청구 기간 동안 사용자 수가 다음과 같이 변합니다:

| 이벤트                                             | 청구 가능한 사용자 | 최대 사용자 수 |
|:--------------------------------------------------|:----------------|:--------------|
| 10명의 사용자가 모든 10개 사용자를 차지합니다.                    | 10              | 10            |
| 2명의 새 사용자가 참여합니다.                               | 12              | 12            |
| 3명의 사용자가 떠나고 계정이 차단됩니다. | 9               | 12            |
| 4명의 새 사용자가 참여합니다.                              | 13              | 13            |

이 경우 3명의 구독 초과 사용자가 있습니다(13명의 최대 사용자 - 10개 구매한 사용자).

구독 한도를 초과하면 갱신 전 또는 갱신 시점에 추가 사용자에 대한 비용을 지불해야 합니다. 비용은 현재 사용자 수가 아니라 청구 기간 동안의 최대 사용자 수를 기준으로 합니다.

GitLab Self-Managed에서 평가판 라이선스의 경우 구독 초과 사용자 값은 항상 0입니다.

예상치 못한 초과 요금을 방지하려면 다음을 수행할 수 있습니다:

- 제한된 액세스를 활성화하여 사용자가 남지 않을 때 사용자 추가를 방지합니다.
- [새 사용자 계정에 대한 관리자 승인 필수](../administration/settings/sign_up_restrictions.md#require-administrator-approval-for-new-user-accounts).
- 한도에 접근할 때 사전에 더 많은 사용자를 구매합니다.

## Free 게스트 사용자 {#free-guest-users}

{{< details >}}

- 티어: Ultimate

{{< /details >}}

**Ultimate 요금제** 티어에서는 게스트 역할이 할당된 사용자가 사용자를 차지하지 않습니다. 사용자는 GitLab Self-Managed의 인스턴스 어디서나 또는 GitLab.com의 네임스페이스에 다른 역할이 할당되지 않아야 합니다.

GitLab Self-Managed의 **Premium** 티어에서 게스트 사용자가 프로젝트 또는 그룹(개인 네임스페이스 포함)에서 더 높은 역할을 가지고 있으면 **Ultimate 요금제** 티어로 업그레이드할 때 더 높은 역할이 우선하며 사용자를 차지합니다. GitLab Self-Managed Ultimate의 게스트 사용자가 사용자를 차지하지 않도록 하려면 업그레이드하기 전에 인스턴스 또는 네임스페이스에서 다른 역할 할당이 없는지 확인합니다.

- 프로젝트가 다음인 경우:
  - 비공개 또는 내부인 경우 게스트 역할이 있는 사용자는 [권한 집합](../user/permissions.md#project-permissions)을 가집니다.
  - 공개인 경우 게스트 역할을 포함한 모든 사용자가 프로젝트에 액세스할 수 있습니다.
- GitLab.com의 경우 게스트 역할을 가진 사용자가 개인 네임스페이스에서 프로젝트를 생성하면 사용자가 사용자를 차지하지 않습니다. 프로젝트는 사용자의 개인 네임스페이스 아래에 있으며 Ultimate 구독이 있는 그룹과 관련이 없습니다.
- GitLab Self-Managed에서 사용자의 최상위 할당된 역할은 비동기식으로 업데이트되며 업데이트하는 데 시간이 걸릴 수 있습니다.

> [!note]
> GitLab Self-Managed에서 사용자가 프로젝트를 생성하면 유지관리자 또는 소유자 역할이 할당됩니다. 사용자가 프로젝트를 생성하는 것을 방지하려면 관리자는 사용자를 [external](../administration/external_users.md)로 표시할 수 있습니다.

## 사용자 제어 {#seat-controls}

사용자 제어는 사용자를 구독에 추가하는 방식을 관리하고 예상치 못한 초과 요금을 방지하는 데 도움이 됩니다. 사용자 제어는 GitLab Self-Managed의 인스턴스와 GitLab.com의 최상위 그룹에 적용됩니다.

### 사용자 한도 {#user-cap}

{{< history >}}

- GitLab 16.3에서 [GitLab.com에서 활성화](https://gitlab.com/groups/gitlab-org/-/epics/9263)되었습니다.
- GitLab 17.1에서 [일반 공급](https://gitlab.com/gitlab-org/gitlab/-/issues/421693)되었습니다. `saas_user_caps` 기능 플래그가 제거되었습니다.

{{< /history >}}

사용자 한도는 GitLab.com의 최상위 그룹에 추가하거나 GitLab Self-Managed에서 계정을 생성할 수 있는 최대 청구 가능한 사용자 수입니다. 사용자 한도에 도달하면 그룹 소유자 또는 관리자가 최상위 그룹에 추가하거나 계정을 생성할 사용자를 승인해야 합니다. 사용자가 승인되면 그룹 또는 인스턴스에 액세스할 수 있습니다. 그룹 소유자 또는 관리자가 사용자 한도를 증가하거나 제거하면 승인 대기 중인 사용자가 자동으로 승인됩니다.

[최상위 그룹용](../user/group/manage.md#set-a-user-cap-for-a-group) 및 [인스턴스용](../administration/settings/sign_up_restrictions.md#set-a-user-cap)으로 사용자 한도를 설정할 수 있습니다.

> [!note]
> GitLab.com에서는 최상위 그룹 내의 그룹, 하위 그룹 또는 프로젝트가 해당 네임스페이스 계층 외부에서 공유되면 사용자 한도를 활성화할 수 없습니다. 사용자 한도가 활성화되는 동안 [그룹 계층 구조 외부의 그룹 초대](../user/project/members/sharing_projects_groups.md#prevent-inviting-groups-outside-the-group-hierarchy)가 자동으로 방지되며 끌 수 없습니다. 그룹 내의 그룹 및 하위 그룹에 초대하는 것은 영향을 받지 않습니다.

청구 가능한 사용자 수는 하루에 한 번 업데이트됩니다. 사용자 한도는 이미 초과된 후에만 적용될 수 있습니다. 한도가 현재 청구 가능한 사용자 수보다 낮은 값(예: `1`)으로 설정되면 한도가 즉시 활성화됩니다.

> [!note]
> GitLab Self-Managed에서 LDAP 또는 OmniAuth를 사용하는 인스턴스의 경우 새 사용자 계정에 대한 관리자 승인을 활성화하거나 비활성화하면 Rails 구성 변경으로 인해 가동 중지 시간이 발생할 수 있습니다. 사용자 한도를 설정하여 새 사용자에 대한 승인을 적용할 수 있습니다.

GitLab.com Ultimate에서는 청구 가능한 사용자가 사용자 한도를 초과할 때 그룹에 게스트 사용자를 추가할 수 없습니다. 예를 들어 3명의 개발자와 2명의 게스트가 있을 때 사용자 한도를 5로 설정합니다. 2명의 개발자를 더 추가한 후에는 청구 가능한 사용자를 차지하지 않는 게스트 사용자더라도 더 이상 사용자를 추가할 수 없습니다. 더 많은 정보는 [이슈 441504](https://gitlab.com/gitlab-org/gitlab/-/issues/441504)를 참조하세요.

### 제한된 액세스 {#restricted-access}

{{< history >}}

- GitLab 17.5에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/442718)되었습니다.
- GitLab 18.0에서 [일반 공급](https://gitlab.com/gitlab-org/gitlab/-/issues/523468)되었습니다.
- 그룹 공유 설정이 GitLab 18.7에서 [변경](https://gitlab.com/gitlab-org/gitlab/-/issues/488451)되었습니다.
- GitLab Self-Managed의 자동 제한된 액세스가 GitLab 19.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/240092)되었으며 [기능 플래그](../administration/feature_flags/_index.md) `auto_enable_restricted_access_on_self_managed` 이름으로 지정됩니다. 기본적으로 활성화되었습니다.

{{< /history >}}

제한된 액세스는 구독에 라이선스된 사용자이 남지 않을 때 새 청구 가능한 사용자가 추가되는 것을 차단합니다. 이미 사용자 한도를 초과한 그룹 또는 인스턴스에 제한된 액세스를 활성화하면 기존 구성원의 역할을 변경하거나 차단하거나 제거하지 않습니다. 새 청구 가능한 추가를 방지하면서 현재 구성원을 그대로 두게 됩니다. GitLab OIDC 공급자로 인증하는 사용자와 같이 프로젝트 또는 그룹에 액세스할 필요가 없는 사용자에게는 비청구 가능한 최소 액세스 역할을 할당하여 사용자 한도에 의해 차단되지 않도록 할 수 있습니다.

[최상위 그룹용](../user/group/manage.md#turn-on-restricted-access) 및 [인스턴스용](../administration/settings/sign_up_restrictions.md#turn-on-restricted-access)으로 제한된 액세스를 설정할 수 있습니다.

제한된 액세스는 외부 그룹 공유와 호환되지 않습니다. GitLab.com에서 제한된 액세스를 활성화하면 [그룹 계층 구조 외부의 그룹 초대 방지](../user/project/members/sharing_projects_groups.md#prevent-inviting-groups-outside-the-group-hierarchy) 설정이 자동으로 활성화됩니다. 이 설정은 의도하지 않은 청구 가능한 사용자로 인한 초과 요금을 방지합니다.

필요에 따라 [그룹 및 하위 그룹의 프로젝트 공유](../user/project/members/sharing_projects_groups.md#prevent-a-project-from-being-shared-with-groups)를 독립적으로 구성할 수 있습니다.

제한된 액세스와 사용자 한도는 함께 사용할 수 없습니다. 제한된 액세스를 활성화하면 사용자 한도가 비활성화됩니다.

GitLab Self-Managed에서는 구독이 초과를 허용하지 않을 때 GitLab이 자동으로 제한된 액세스를 활성화합니다. 구독이 초과를 허용하지 않을 때는 제한된 액세스를 끌 수 없습니다.

#### SAML, SCIM 및 LDAP를 통한 프로비저닝 동작 {#provisioning-behavior-with-saml-scim-and-ldap}

{{< history >}}

- GitLab 18.6에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/206932)되었으며 [기능 플래그](../administration/feature_flags/_index.md) `bso_minimal_access_fallback` 이름으로 지정됩니다. 기본적으로 사용 중지되어 있습니다.
- GitLab 18.10에서 [기본적으로 활성화](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/225777)되었습니다.

{{< /history >}}

제한된 액세스가 활성화되고 구독 사용자이 없으면 SAML, SCIM 또는 LDAP를 통해 프로비저닝된 사용자에게 구성된 액세스 수준 대신 최소 액세스 역할이 할당됩니다. 이 동작은 GitLab.com 및 Self-Managed Ultimate에서 청구 가능한 사용자를 소비하지 않고 동기화를 계속할 수 있도록 보장합니다.

최소 액세스 역할이 있는 사용자는 인증하고 그룹에 액세스할 수 있지만 [제한된 권한](../user/permissions.md#users-with-minimal-access)을 가집니다. 사용자를 사용할 수 있게 되면 의도한 액세스 수준으로 승격될 수 있습니다. 청구 가능한 역할을 가진 기존 사용자는 이 동작의 영향을 받지 않습니다.

최소 액세스가 있는 사용자 사용량 및 관리 사용자를 볼 수 있습니다.

#### 알려진 이슈 {#known-issues}

제한된 액세스를 활성화하면 다음 알려진 문제가 발생할 수 있으며 초과 요금이 발생할 수 있습니다:

- 다음의 경우 사용자 수를 초과할 수 있습니다:
  - SAML, SCIM 또는 LDAP를 사용하여 새 구성원을 추가하고 구독의 사용자 수를 초과했습니다. 최소 액세스 폴백 기능이 활성화되면 사용자가 차단되는 대신 최소 액세스가 할당됩니다.
  - 소유자 역할이 있는 여러 사용자 또는 관리자 액세스가 동시에 구성원을 추가합니다.
- 현재 구독보다 적은 사용자의 경우 GitLab 영업팀을 통해 구독을 갱신하면 초과 요금이 발생합니다. 이 요금을 피하려면 갱신이 시작되기 전에 추가 사용자를 제거합니다. 예를 들어 20명의 사용자가 있고 15명의 사용자에 대해 구독을 갱신하면 5명의 추가 사용자에 대해 초과 요금이 청구됩니다.

또한 제한된 액세스는 표준 비초과 흐름을 차단할 수 있습니다:

- 청구 가능한 역할로 업데이트되거나 추가된 서비스 봇이 잘못 차단됩니다.
- 이메일을 통해 기존 청구 가능한 사용자를 초대하거나 업데이트하는 것이 예기치 않게 차단됩니다.

#### 휴면 사용자 재활성화 {#dormant-user-reactivation}

제한된 액세스가 활성화되고 라이선스된 사용자이 없으면 다시 로그인하려고 시도하는 휴면 사용자([엔터프라이즈 사용자](../user/enterprise_user/_index.md) 포함)가 재활성화되지 않고 승인 대기 중으로 설정됩니다. 기존 그룹 및 프로젝트 구성원 자격이 유지됩니다. 비엔터프라이즈 휴면 구성원은 비활성화되지 않고 그룹 구성원 자격이 제거됩니다. SAML, SCIM 또는 LDAP 동기화를 통해 다시 참여할 때 프로비저닝 동작이 적용되고 사용자이 없으면 최소 액세스 역할을 받습니다.

그룹 소유자 또는 관리자가 사용자를 사용할 수 있게 될 때 사용자를 승인할 수 있습니다.

최소 액세스 역할만 있는 사용자는 청구 가능한 사용자를 차지하지 않으므로 직접 재활성화됩니다.

[휴면 구성원을 자동으로 제거](../user/group/moderate_users.md#automatically-remove-dormant-members)할 수 있습니다.

#### 보류 중인 초대 수락 {#pending-invitation-acceptance}

제한된 액세스를 활성화한 후 보류 중인 초대가 진행될 수 있는지 여부를 결정합니다:

- GitLab.com에서 구독 사용자이 남지 않으면 사용자는 청구 가능한 역할을 부여하는 보류 중인 초대를 수락할 수 없습니다. 초대는 그룹 소유자가 사용자를 사용 가능하게 할 때까지(더 많은 사용자를 구매하거나 청구 가능한 구성원을 제거하여) 보류 상태로 유지됩니다.
- GitLab Self-Managed: 
  - Ultimate 티어에서는 동일한 동작이 적용됩니다. 초대는 관리자가 사용자를 사용 가능하게 할 때까지(더 많은 사용자를 구매하거나 청구 가능한 구성원을 제거하여) 보류 상태로 유지됩니다.
  - Premium 티어에서는 제한된 액세스가 초대를 수락할 때가 아니라 계정을 생성할 때 사용자 한도를 적용합니다. GitLab은 등록할 때 사용자에게 계정을 생성할 수 없으며 GitLab 관리자에게 문의해야 함을 알립니다.

### 사용자 한도에서 제한된 액세스로 변경 {#changing-from-user-cap-to-restricted-access}

GitLab.com에서 사용자 한도에서 제한된 액세스로 변경하면 모든 보류 중인 구성원(승인 대기 중인 구성원 및 초대된 구성원 모두)이 자동으로 제거됩니다. 사용자가 구성원으로 승인되도록 하려면 제한된 액세스를 활성화하기 전에 보류 중인 구성원을 승인하거나 제거해야 합니다.

GitLab Self-Managed에서 사용자 한도는 GitLab.com처럼 그룹 또는 프로젝트 구성원을 차단하지 않고 새 사용자 계정을 승인 대기 중으로 유지합니다. 사용자 한도에서 제한된 액세스로 변경할 때 보류 중인 새 사용자 계정이 자동으로 제거되지 않습니다. 사용자는 관리자가 승인할 때까지 차단된 상태로 유지됩니다.

제한된 액세스를 활성화한 후 보류 중인 사용자 승인이 진행될 수 있는지 여부를 결정합니다:

- Premium 티어에서는 그룹 또는 프로젝트 구성원 자격이 없는 사용자가 청구 가능하기 때문에 제한된 액세스가 보류 중인 승인을 차단합니다.
- Ultimate 티어에서는 그룹 또는 프로젝트 구성원 자격이 없는 사용자가 비청구 가능하기 때문에 제한된 액세스가 보류 중인 승인을 차단하지 않습니다. 그러나 관리자가 사용자를 승인한 후 제한된 액세스는 사용자이 없으면 사용자를 청구 가능한 역할이 있는 그룹 또는 프로젝트에 추가하는 것을 방지합니다.

## 더 많은 사용자 구매 {#buy-more-seats}

{{< details >}}

- 제공 서비스: GitLab.com, GitLab Self-Managed

{{< /details >}}

구독 비용은 청구 기간 동안 사용하는 최대 사용자 수를 기준으로 합니다.

제한된 액세스가 다음인 경우:

- 켜진 경우, 구독에 남은 사용자이 없으면 그룹이 새 청구 가능한 사용자를 추가하려면 더 많은 사용자를 구매해야 합니다.
- 꺼진 경우, 구독에 남은 사용자이 없으면 그룹이 계속해서 청구 가능한 사용자를 추가할 수 있습니다. GitLab이 초과 요금을 청구합니다.

다음 중 하나인 경우 구독에 대한 사용자를 구매할 수 없습니다:

- [인증된 재판매자](billing_account.md#subscription-purchased-through-a-reseller)(GCP 및 AWS 마켓플레이스 포함)를 통해 구독을 구매했습니다. 재판매자에게 연락하여 더 많은 사용자를 추가합니다.
- 다년 구독이 있습니다. [영업팀](https://customers.gitlab.com/contact_us)에 문의하여 더 많은 사용자를 추가합니다.

구독을 위해 사용자를 구매하려면:

1. [Customers Portal](https://customers.gitlab.com/)에 로그인합니다.
1. **Subscriptions & purchases** 페이지로 이동합니다.
1. 관련 구독 카드에서 **사용자 추가**를 선택합니다.
1. 추가 사용자 수를 입력합니다.
1. **Purchase summary** 섹션을 검토합니다. 시스템은 시스템의 모든 사용자에 대한 총 가격과 이미 지불한 비용에 대한 크레딧을 나열합니다. 순 변경액에 대해서만 청구됩니다.
1. 결제 정보를 입력합니다.
1. **I accept the Privacy Statement and Terms of Service** 체크박스를 선택합니다.
1. **Purchase seats**를 선택합니다.

이메일로 결제 영수증을 받습니다. 고객 포털의 [**Invoices**](https://customers.gitlab.com/invoices) 아래에서도 영수증에 액세스할 수 있습니다.

## 사용자 감소 {#reduce-seats}

구독 갱신 중에만 사용자를 줄일 수 있습니다. 구독의 사용자 수를 줄이려면 [더 적은 사용자으로 갱신](manage_subscription.md#renew-for-fewer-seats)할 수 있습니다.

## Self-Managed 청구 및 사용 {#self-managed-billing-and-usage}

{{< details >}}

- 제공 서비스: GitLab Self-Managed

{{< /details >}}

GitLab Self-Managed 구독은 하이브리드 모델을 사용합니다. 구독 기간 동안 활성화된 최대 사용자 수에 따라 구독에 대해 비용을 지불합니다.

오프라인이 아니거나 폐쇄된 네트워크의 인스턴스의 경우 GitLab Self-Managed 인스턴스의 최대 동시 사용자 수가 매분기마다 확인됩니다.

인스턴스가 분기별 사용 현황 보고서를 생성할 수 없으면 기존 정산 모델이 사용됩니다. 분기별 사용 현황 보고서가 없으면 청구 비례 배분이 불가능합니다.

구독의 사용자 수는 지불한 내용을 기준으로 현재 라이선스에 포함된 사용자 수를 나타냅니다. 더 많은 사용자를 구매하지 않으면 이 수는 구독 기간 내내 동일하게 유지됩니다.

최대 사용자 수는 현재 라이선스 기간 동안 시스템의 최고 청구 가능한 사용자 수를 반영합니다.

[청구 가능한 사용자](../administration/moderate_users.md#billable-users) 및 [라이선스 사용량](../administration/license_usage.md)을 보고 관리할 수 있습니다.

라이선스가 포함하는 사용자 수를 늘리려면 구독 기간 동안 더 많은 사용자를 구매합니다. 구독 기간 동안 추가된 사용자의 비용은 구매 날짜부터 구독 기간 종료까지 비례 배분됩니다. 라이선스 수의 사용자 수에 도달한 경우에도 계속해서 사용자를 추가할 수 있습니다. GitLab이 초과 요금을 청구합니다.

구독이 활성화 코드로 활성화된 경우 추가 사용자이 인스턴스에 즉시 반영됩니다. 라이선스 파일을 사용하는 경우 업데이트된 파일을 받습니다. 사용자를 추가하려면 라이선스 파일을 인스턴스에 추가합니다.

[LDAP가 GitLab과 통합](../administration/auth/ldap/_index.md)되면 구성된 도메인의 모든 사용자가 GitLab 계정에 가입할 수 있습니다. 이로 인해 갱신 시점에 예상치 못한 청구가 발생할 수 있습니다. 인스턴스에서 새 사용자 계정이 허용되면 인스턴스에 액세스할 수 있는 모든 사용자가 계정에 가입할 수 있습니다.

예상치 못한 초과를 방지하려면 사용자 관리를 위한 모범 사례를 참조하세요.

## GitLab.com 청구 및 사용 {#gitlabcom-billing-and-usage}

{{< details >}}

- 제공 서비스: GitLab.com

{{< /details >}}

GitLab.com 구독은 동시 (사용자) 모델을 사용합니다. 동시에 구독을 사용할 수 있는 사용자의 사용자 수를 선택하고 청구 기간 동안 최상위 그룹, 하위 그룹 및 프로젝트에 할당된 최대 사용자 수에 따라 구독에 대해 비용을 지불합니다.

전체 사용자 수가 구독의 사용자 수를 초과하지 않는 한, 구독 기간 동안 추가 요금 없이 사용자를 추가하고 제거할 수 있습니다. 더 많은 사용자를 추가하고 구매한 사용자 수를 초과하면 초과 요금이 발생하며 이는 다음 송장에 포함됩니다.

### 사용자 사용 경고 {#seat-usage-alerts}

최상위 그룹의 소유자 역할이 있고 분기별 구독 정산에 등록된 구독과 연결된 경우 구독의 사용자 사용량에 대한 경고를 받습니다.

경고는 그룹, 하위 그룹 및 프로젝트 페이지에 표시됩니다. 경고를 닫은 후 다른 사용자를 사용할 때까지 다시 표시되지 않습니다.

경고는 다음 간격으로 표시됩니다:

| 구독 사용자 | 경고               |
|-----------------------|---------------------|
| 0-15                  | 1개 사용자가 남습니다.   |
| 16-25                 | 2개 사용자가 남습니다.   |
| 26-99                 | 사용자의 10%가 남습니다. |
| 100-999               | 사용자의 8%가 남습니다. |
| 1000+                 | 사용자의 5%가 남습니다. |

### 사용자 사용량 보기 {#view-seat-usage}

사용 중인 사용자 목록을 보려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **사용 할당량**을 선택합니다.
1. **사용자** 탭을 선택합니다.

각 사용자에 대해 목록은 사용자가 직접 구성원인 그룹 및 프로젝트를 표시합니다.

- **그룹 초대**는 사용자가 [그룹에 초대된 그룹](../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-group)의 구성원임을 나타냅니다.
- **프로젝트 초대**는 사용자가 [프로젝트에 초대된 그룹](../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-project)의 구성원임을 나타냅니다.

사용자 사용 목록, **사용중인 사용자** 및 **구독 사용자**의 데이터는 실시간으로 업데이트됩니다. **사용된 최대 사용자** 및 **청구될 사용자**의 수는 하루에 한 번 업데이트됩니다.

#### 청구 정보 보기 {#view-billing-information}

구독 정보 및 사용자 수 요약을 보려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **결제**를 선택합니다.

- 사용 통계는 하루에 한 번 업데이트되므로 **사용 할당량** 페이지와 **Billing page** 페이지의 정보에 차이가 있을 수 있습니다.
- **최근 로그인** 필드는 사용자가 로그아웃 후 로그인할 때 업데이트됩니다. 사용자가 재인증할 때 활성 세션이 있으면(예: 24시간 SAML 세션 타임아웃 후) 이 필드는 업데이트되지 않습니다.

### 사용자의 사용자 사용량 검색 {#search-users-seat-usage}

구독에서 사용자를 사용하는 사용자를 볼 수 있습니다. 사용자의 사용자 사용량을 검색하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **사용 할당량**을 선택합니다.
1. **사용자** 탭의 검색 필드에 사용자의 이름 또는 사용자 이름을 입력합니다. 검색 문자열은 최소 3자 이상이어야 합니다.

검색은 이름, 성 또는 사용자 이름이 검색 문자열과 일치하는 사용자 목록을 반환합니다.

예를 들어 이름이 Amir인 사용자의 경우 검색 문자열 `ami`은 일치하지만 `amr`은 그렇지 않습니다.

### 사용자 사용 데이터 내보내기 {#export-seat-usage-data}

사용자 사용 데이터를 CSV 파일로 내보내려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **사용 할당량**을 선택합니다.
1. **사용자** 탭에서 **목록 내보내기**를 선택합니다.

### 사용자 사용 내역 내보내기 {#export-seat-usage-history}

전제 조건:

- 그룹의 Owner 역할이 있어야 합니다.

사용자 사용 내역을 CSV 파일로 내보내려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **사용 할당량**을 선택합니다.
1. **사용자** 탭에서 **사용자 사용 내역 내보내기**를 선택합니다.

생성된 목록은 사용 중인 모든 사용자를 포함하며 현재 검색의 영향을 받지 않습니다.

### 구독에서 사용자 제거 {#remove-users-from-subscription}

GitLab.com 구독에서 청구 가능한 사용자를 제거하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **결제**를 선택합니다.
1. **현재 사용 중인 사용자** 섹션에서 **사용 보기**를 선택합니다.
1. 제거하려는 사용자의 행에서 오른쪽에 **사용자 삭제**를 선택합니다.
1. 사용자 이름을 다시 입력하고 **사용자 삭제**를 선택합니다.

다른 그룹과 공유하여 그룹에 구성원을 추가한 경우 이 방법을 사용하여 구성원을 제거할 수 없습니다. 대신 다음 중 하나를 수행할 수 있습니다:

- [공유된 그룹에서 구성원 제거](../user/group/_index.md#remove-a-member-from-the-group).
- [초대된 그룹 제거](../user/project/members/sharing_projects_groups.md#remove-an-invited-group).

## 엔터프라이즈 Agile 계획 {#enterprise-agile-planning}

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab Enterprise Agile Planning은 비엔지니어링 사용자를 엔지니어가 코드를 빌드, 테스트, 보호 및 배포하는 동일한 DevSecOps 플랫폼으로 가져오는 데 도움이 되는 추가 기능입니다. 이 추가 기능은 비엔지니어링 팀 구성원을 위해 GitLab Ultimate 라이선스를 구매할 필요 없이 개발자와 비개발자 간의 부서 간 협력을 가능하게 합니다.

Enterprise Agile Planning 사용자를 통해 비엔지니어링 팀 구성원은 계획 워크플로에 참여하고, Value Stream Analytics를 통해 소프트웨어 배포 속도 및 영향을 측정하고, 실행 대시보드를 사용하여 조직 가시성을 높일 수 있습니다.

Enterprise Agile Planning 사용자 및 구매 방법에 대한 자세한 정보는 [GitLab 영업 담당자](https://customers.gitlab.com/contact_us)에게 문의하세요.

### Enterprise Agile Planning 사용자 사용 {#using-enterprise-agile-planning-seats}

다음의 경우 사용자가 Enterprise Agile Planning 사용자를 차지합니다:

- 구독에 구매한 Enterprise Agile Planning 사용자이 포함되어 있습니다.
- 최상위 그룹, 하위 그룹 및 프로젝트 전체에서 사용자가 가진 최상의 [역할](../user/permissions.md#default-roles)이 플래너입니다.

다음 중 하나인 경우 사용자는 Enterprise Agile Planning 사용자 대신 Ultimate 사용자를 차지합니다:

- 구독에 구매한 Enterprise Agile Planning 사용자이 포함되어 있지 않습니다.
- 플래너 역할이 있는 사용자에게 조직 계층 구조의 어디서나 더 높은 역할(개발자 또는 유지관리자 등)이 할당됩니다.

구매한 Enterprise Agile Planning 사용자를 사용하려면 먼저 [그룹](../user/group/_index.md#add-users-to-a-group) 또는 [프로젝트](../user/project/members/_index.md#add-users-to-a-project)의 사용자에게 플래너 역할을 할당해야 합니다.

플래너 역할이 있는 사용자가 다른 역할을 할당받아 Ultimate 사용자를 차지하지 않도록 하려면 [전역 SAML 그룹 구성원 잠금](../user/group/saml_sso/group_sync.md)을 사용할 수 있습니다.

[구독 세부 정보](manage_subscription.md#view-subscription)에서 및 [고객 포털](billing_account.md)에서 사용되는 Enterprise Agile Planning 사용자 수를 볼 수 있습니다. GitLab Self-Managed에서는 [사용자 통계](../administration/admin_area.md#users-statistics)에서 역할별 총 사용자 수를 볼 수도 있습니다.

## 모범 사례 {#best-practices}

구독 사용자를 효과적으로 관리하고 비용을 제어하려면 다음 모범 사례를 따릅니다.

초기 설정:

- [새 사용자 계정 생성 비활성화](../administration/settings/sign_up_restrictions.md#disable-new-user-account-creation).
- [LDAP](../administration/auth/ldap/_index.md#basic-configuration-settings) 또는 [OmniAuth](../integration/omniauth.md#configure-common-settings)를 통해 새 사용자를 자동으로 차단합니다.
- [새 계정](../administration/settings/sign_up_restrictions.md#require-administrator-approval-for-new-user-accounts) 및 [역할 승격](../administration/settings/sign_up_restrictions.md#turn-on-administrator-approval-for-role-promotions)에 대한 승인을 요구하여 처음부터 사용자 할당에 대한 제어를 유지합니다.
- 사용자 제어를 사용하여 제한된 액세스를 활성화하거나 그룹 또는 인스턴스의 사용자 한도를 설정하여 의도하지 않은 사용자 사용을 방지합니다.
- 가능한 경우 게스트(Free 및 Ultimate) 또는 최소 액세스와 같은 비청구 가능한 역할을 할당하여 사용자 사용을 최소화합니다.

정기적인 활동:

- 사용자 사용량 및 사용자 통계를 정기적으로 모니터링하여 잠재적 초과를 식별합니다.
- 사용자이 부족해지면 알려주는 사용자 사용 경고에 대응합니다.
- 휴면 구성원을 자동으로 비활성화하거나 제거하여 활성 팀 구성원을 위한 사용자를 확보합니다.

전략적 계획:

- 전체 Ultimate 사용자 대신 비엔지니어링 팀 구성원을 위해 Enterprise Agile Planning 사용자를 사용합니다.
- 한도에 접근할 때 사용자를 구매하여 성장을 미리 계획합니다.
- 사용자 사용 내역을 내보내고 분석하여 향후 요구 사항을 예측합니다.
