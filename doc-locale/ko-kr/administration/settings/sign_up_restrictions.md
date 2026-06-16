---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: 새 사용자 계정 생성 제한사항
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

새 사용자 계정에 다음과 같은 제한사항을 적용할 수 있습니다:

- 계정 생성을 방지합니다.
- 새 계정에 관리자 승인이 필요합니다.
- 사용자 이메일 확인이 필요합니다.
- 특정 이메일 도메인을 사용하는 새 계정을 허용하거나 거부합니다.

## 전제 조건 {#prerequisites}

관리자 액세스 권한이 있어야 합니다.

## 새 사용자 계정 생성 비활성화 {#disable-new-user-account-creation}

기본적으로 GitLab 도메인을 방문하는 모든 사용자는 계정을 만들 수 있습니다. 공개 GitLab 인스턴스를 운영하는 경우 공개 사용자가 계정을 만들 것으로 예상하지 않는다면 새 계정을 비활성화하는 것을 권장합니다. GitLab Dedicated의 경우 인스턴스가 프로비저닝될 때 기본적으로 새 계정 생성이 방지됩니다.

새 계정 생성을 방지하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **사용자 계정 생성 제한사항**을 확장합니다.
1. **새 사용자 계정 허용** 확인란을 선택 해제한 다음 **변경사항 저장**을 선택합니다.

[Rails 콘솔](../operations/rails_console.md)을 사용하여 다음 명령을 실행하면 새 사용자 계정도 방지할 수 있습니다:

```ruby
::Gitlab::CurrentSettings.update!(signup_enabled: false)
```

## 새 사용자 계정에 관리자 승인 필요 {#require-administrator-approval-for-new-user-accounts}

이 설정은 새로운 GitLab 인스턴스에서 기본적으로 활성화되어 있습니다. 이 설정이 활성화되면 GitLab 도메인을 방문하여 등록 양식을 사용하여 새 계정에 가입하는 모든 사용자는 계정을 사용하기 전에 관리자로부터 명시적인 [승인](../moderate_users.md#approve-or-reject-a-new-user-account)을 받아야 합니다. 사용자 계정이 허용되는 경우에만 적용됩니다.

새 사용자 계정에 관리자 승인이 필요하도록 하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **사용자 계정 생성 제한사항**을 확장합니다.
1. **사용자 계정 생성에 관리자 승인이 필요합니다.** 확인란을 선택한 다음 **변경사항 저장**을 선택합니다.

관리자가 이 설정을 비활성화하면 승인 대기 중인 사용자는 백그라운드 작업에서 자동으로 승인됩니다.

> [!note]
> 이 설정은 LDAP 또는 OmniAuth 사용자에게 적용되지 않습니다. OmniAuth 또는 LDAP를 사용하여 가입하는 새 사용자에게 승인을 적용하려면 `block_auto_created_users`를 `true`로 설정하세요([OmniAuth 구성](../../integration/omniauth.md#configure-common-settings) 또는 [LDAP 구성](../auth/ldap/_index.md#basic-configuration-settings)에서). [사용자 상한](#user-cap)을 사용하여 새 사용자의 승인을 강제할 수도 있습니다.

## 사용자 이메일 확인 {#confirm-user-email}

{{< history >}}

- 소프트 이메일 확인이 GitLab 15.9에서 기능 플래그에서 애플리케이션 설정으로 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/107302/diffs)되었습니다.

{{< /history >}}

계정 생성 시 확인 이메일을 보낼 수 있으며 사용자가 로그인하기 전에 이메일 주소를 확인해야 합니다.

새 계정에 사용되는 이메일 주소의 확인을 적용하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **사용자 계정 생성 제한사항**을 확장합니다.
1. **이메일 확인 설정**에서 **Hard**를 선택합니다.

다음 설정을 사용할 수 있습니다:

- **Hard** \- 계정 생성 중에 확인 이메일을 보냅니다. 새 사용자는 로그인하기 전에 이메일 주소를 확인해야 합니다.
- **소프트** \- 계정 생성 중에 확인 이메일을 보냅니다. 새 사용자는 즉시 로그인할 수 있지만 3일 이내에 이메일을 확인해야 합니다. 3일 후 사용자는 이메일을 확인할 때까지 로그인할 수 없습니다.
- **끄기** \- 새 사용자는 이메일 주소를 확인하지 않고도 로그인할 수 있습니다.

## 제한된 액세스 {#restricted-access}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.8에 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/501717)되었습니다.
- GitLab 18.0에서 [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/issues/523464)되었습니다.
- 그룹 공유 설정이 GitLab 18.7에서 [변경](https://gitlab.com/gitlab-org/gitlab/-/issues/488451)되었습니다.

{{< /history >}}

제한된 액세스를 사용하여 초과 요금을 방지합니다. 초과 요금은 구독의 라이선스 사용자 수를 초과할 때 발생하며 다음 [분기별 조정](../../subscriptions/quarterly_reconciliation.md)에서 지불해야 합니다.

제한된 액세스를 켜면 구독에 라이선스된 좌석이 남지 않은 경우 인스턴스에서 새 청구 대상 사용자를 추가할 수 없습니다.

> [!note]
> 사용자 상한이 대기 중인 멤버가 있는 인스턴스 또는 그룹에 대해 활성화되고 제한된 액세스를 활성화하면 모든 대기 중인 멤버가 자동으로 그룹에서 제거됩니다.

### 제한된 액세스 켜기 {#turn-on-restricted-access}

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.
- 그룹이나 그 하위 그룹 또는 프로젝트 중 하나는 외부와 공유되지 않아야 합니다.

제한된 액세스를 켜려면:

1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **사용자 계정 생성 제한사항**을 확장합니다.
1. **좌석 제어**에서 **제한된 액세스**를 선택합니다.

제한된 액세스를 켜면 [그룹 계층 외부의 그룹 초대 방지](../../user/project/members/sharing_projects_groups.md#prevent-inviting-groups-outside-the-group-hierarchy) 설정이 자동으로 켜집니다. 이 설정은 예기치 않게 새 청구 대상 사용자가 추가되는 것을 방지하여 초과 요금이 발생할 수 있는 위험을 줄입니다.

필요에 따라 [그룹 및 하위 그룹에 대한 프로젝트 공유](../../user/project/members/sharing_projects_groups.md#prevent-a-project-from-being-shared-with-groups)를 계속 독립적으로 구성할 수 있습니다.

### SAML, SCIM 및 LDAP를 사용한 프로비저닝 동작 {#provisioning-behavior-with-saml-scim-and-ldap}

{{< history >}}

- GitLab 18.6에 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/206932) 되었습니다([플래그](../feature_flags/_index.md) 포함) `bso_minimal_access_fallback`. 기본적으로 비활성화됨.
- GitLab 18.10에서 [기본적으로 활성화](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/225777)되었습니다.

{{< /history >}}

제한된 액세스가 활성화되고 구독 좌석이 없을 때 SAML, SCIM 또는 LDAP를 통해 프로비저닝된 사용자는 구성된 액세스 수준 대신 최소 액세스 역할을 할당받습니다. 이 동작은 GitLab.com 및 GitLab Self-Managed Ultimate에서 청구 대상 좌석을 소비하지 않고 동기화를 계속할 수 있도록 합니다.

최소 액세스 역할을 가진 사용자는 인증하고 그룹에 액세스할 수 있지만 [권한이 제한](../../user/permissions.md#users-with-minimal-access)됩니다. 좌석을 사용할 수 있게 되면 사용자는 의도한 액세스 수준으로 승격될 수 있습니다. 청구 대상 역할이 있는 기존 사용자는 이 동작의 영향을 받지 않습니다.

[좌석 사용량을 볼 수](../../subscriptions/manage_seats.md#view-seat-usage) 있으며 최소 액세스 사용자를 관리할 수 있습니다.

### 알려진 이슈 {#known-issues}

제한된 액세스를 켜면 다음과 같은 알려진 이슈가 발생할 수 있으며 초과 요금이 발생할 수 있습니다:

- 청구 대상 사용자의 수는 다음의 경우 계속 초과될 수 있습니다:
  - SAML, SCIM 또는 LDAP를 사용하여 새 멤버를 추가하고 구독의 좌석 수를 초과한 경우 최소 액세스 대체 기능이 활성화되면 사용자는 차단되지 않고 최소 액세스를 할당받습니다.
  - 관리자 액세스 권한이 있는 여러 사용자가 동시에 멤버를 추가하는 경우
  - 새 청구 대상 사용자가 초대를 수락하는 것을 지연하는 경우 사용자를 초대하면 초대를 수락할 때까지 청구 대상 좌석을 소비하지 않습니다. 초대된 사용자가 수락을 지연하면 그 시간에 다른 사용자를 초대하고 추가할 수 있습니다. 지연된 사용자가 결국 수락하면 청구 대상 좌석을 소비하며 이미 좌석 한계에 도달한 경우 초과 요금이 발생할 수 있습니다.
- GitLab 판매 팀을 통해 현재 구독보다 적은 사용자를 위해 구독을 갱신하면 초과 요금이 청구됩니다. 이 요금을 피하려면 갱신이 시작되기 전에 추가 사용자를 제거합니다. 예를 들어 20명의 사용자가 있고 15명의 사용자를 위해 구독을 갱신하는 경우 5명의 추가 사용자에 대한 초과 요금이 청구됩니다.

또한 제한된 액세스는 표준 초과 요금이 아닌 플로우를 차단할 수 있습니다:

- 청구 대상 역할로 업데이트되거나 추가된 서비스 봇이 잘못 차단됩니다.
- 이메일을 통해 기존 청구 대상 사용자를 초대하거나 업데이트하는 것이 예기치 않게 차단됩니다.

### 휴면 사용자 재활성화 {#dormant-user-reactivation}

제한된 액세스가 활성화되고 라이선스된 좌석이 없을 때 다시 로그인을 시도하는 [휴면 사용자](../moderate_users.md#automatically-deactivate-dormant-users) 는 재활성화되지 않고 대신 [승인 대기](../moderate_users.md#users-pending-approval) 상태로 설정됩니다. 기존 그룹 및 프로젝트 멤버십은 유지됩니다. 관리자는 좌석을 사용할 수 있게 되면 사용자를 승인할 수 있습니다.

[최소 액세스](../../user/permissions.md#users-with-minimal-access) 역할만 가진 사용자는 청구 대상 좌석을 소비하지 않으므로 직접 재활성화됩니다.

## 사용자 상한 {#user-cap}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

사용자 상한은 관리자 승인 없이 계정을 만들거나 구독에 추가할 수 있는 최대 청구 대상 사용자 수입니다. 사용자 상한에 도달하면 계정을 만들거나 추가되는 사용자는 관리자로부터 [승인](../moderate_users.md#approve-or-reject-a-new-user-account)을 받아야 합니다. 사용자는 관리자로부터 승인을 받은 후에만 계정을 사용할 수 있습니다.

관리자가 사용자 상한을 증가하거나 제거하면 승인 대기 중인 사용자는 자동으로 승인됩니다.

[청구 대상 사용자](../../subscriptions/manage_seats.md#billable-users) 수는 하루에 한 번 업데이트됩니다. 사용자 상한은 상한이 이미 초과된 후에만 소급적으로 적용될 수 있습니다. 상한이 현재 청구 대상 사용자 수보다 낮은 값으로 설정된 경우(예: `1`), 상한은 즉시 활성화됩니다.

[개별 그룹에 대한 사용자 상한](../../user/group/manage.md#user-cap-for-groups)을 설정할 수도 있습니다.

> [!note]
> LDAP 또는 OmniAuth를 사용하는 인스턴스의 경우 [새 사용자 계정에 대한 관리자 승인](#require-administrator-approval-for-new-user-accounts)이 활성화되거나 비활성화되면 Rails 구성의 변경으로 인해 다운타임이 발생할 수 있습니다. 사용자 상한을 설정하여 새 사용자의 승인을 강제할 수 있습니다.

### 사용자 상한 설정 {#set-a-user-cap}

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

사용자 상한을 설정하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **사용자 계정 생성 제한사항**을 확장합니다.
1. **User cap** 필드에 숫자를 입력하거나 무제한은 공백으로 두십시오.
1. **변경 사항 저장**을 선택합니다.

### 사용자 상한 제거 {#remove-the-user-cap}

사용자 상한을 제거하여 관리자 승인 없이 계정을 만들 수 있는 새 사용자 수를 제한하지 않습니다.

사용자 상한을 제거한 후 승인 대기 중인 사용자는 자동으로 승인됩니다.

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

사용자 상한을 제거하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **사용자 계정 생성 제한사항**을 확장합니다.
1. **User cap**에서 숫자를 제거합니다.
1. **변경 사항 저장**을 선택합니다.

## 사용자 상한에서 제한된 액세스로 변경 {#changing-from-user-cap-to-restricted-access}

사용자 상한에서 제한된 액세스로 변경할 때 모든 대기 중인 멤버(승인 대기 중인 멤버와 초대된 멤버 모두)가 자동으로 제거됩니다. 사용자가 멤버로 승인되도록 하려면 제한된 액세스를 활성화하기 전에 대기 중인 멤버를 승인하거나 제거해야 합니다.

## 암호 복잡성 요구사항 수정 {#modify-password-complexity-requirements}

기본적으로 사용자 암호에는 제한된 수의 [요구사항](../../user/profile/user_passwords.md#password-requirements)이 있습니다. 최소 길이를 늘리거나 특정 문자 유형을 요구하도록 요구사항을 수정할 수 있습니다.

암호 요구사항을 변경해도 기존 사용자 암호에는 영향을 주지 않습니다. 수정된 복잡성 요구사항은 다음의 경우에만 적용됩니다:

- 새 사용자가 계정을 만들 때
- 기존 사용자가 암호를 재설정할 때

암호 복잡성 요구사항을 수정하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **사용자 계정 생성 제한사항**을 확장합니다.
1. 복잡성 요구사항을 수정합니다:

   | 설정 | 설명 |
   |---------|-------------|
   | **Minimum password length** | 필요한 최소 문자 수를 설정합니다. 8자 미만이거나 128자를 초과할 수 없습니다. |
   | **숫자 필요** | 암호에 최소 하나의 숫자(0-9)가 포함되어야 합니다. Premium 및 Ultimate만 해당. |
   | **대문자 필요** | 암호에 최소 하나의 대문자(A-Z)가 포함되어야 합니다. Premium 및 Ultimate만 해당. |
   | **소문자 필요** | 암호에 최소 하나의 소문자(a-z)가 포함되어야 합니다. Premium 및 Ultimate만 해당. |
   | **기호 필요** | 암호에 최소 하나의 기호가 포함되어야 합니다. Premium 및 Ultimate만 해당. |

1. **변경 사항 저장**을 선택합니다.

## 특정 이메일 도메인을 사용하여 계정 생성 허용 또는 거부 {#allow-or-deny-account-creation-by-using-specific-email-domains}

새 사용자 계정에 사용할 수 있는 이메일 도메인의 포함 또는 제외 목록을 지정할 수 있습니다.

이러한 제한사항은 외부 사용자의 새 계정 생성 중에만 적용됩니다. 관리자는 관리자 패널을 통해 허용되지 않는 도메인을 가진 사용자를 추가할 수 있습니다. 사용자는 계정을 만든 후 이메일 주소를 허용되지 않는 도메인으로 변경할 수도 있습니다.

### 이메일 도메인 허용 목록 {#allowlist-email-domains}

제공된 도메인 목록과 일치하는 이메일 주소를 사용하여 사용자 계정을 만드는 것으로 사용자를 제한할 수 있습니다.

### 이메일 도메인 거부 목록 {#denylist-email-domains}

특정 도메인의 이메일 주소를 사용할 때 사용자가 가입하는 것을 차단할 수 있습니다. 이를 통해 악의적인 사용자가 임시 이메일 주소를 사용하여 스팸 계정을 만들 위험을 줄일 수 있습니다.

### 이메일 도메인 허용 목록 또는 거부 목록 생성 {#create-email-domain-allowlist-or-denylist}

이메일 도메인 허용 목록 또는 거부 목록을 만들려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **사용자 계정 생성 제한사항**을 확장합니다.
1. 허용 목록의 경우 목록을 수동으로 입력해야 합니다. 거부 목록의 경우 목록을 수동으로 입력하거나 목록 항목이 포함된 `.txt` 파일을 업로드할 수 있습니다.

   허용 목록과 거부 목록 모두 와일드카드를 지원합니다. 예를 들어 `*.company.com`를 사용하여 모든 `company.com` 하위 도메인을 허용하거나 `*.io`를 사용하여 `.io`로 끝나는 모든 도메인을 차단할 수 있습니다. 도메인은 공백, 세미콜론, 쉼표 또는 새 줄로 구분해야 합니다.

   ![도메인 거부 목록 설정과 파일 업로드 또는 거부 목록을 수동으로 입력하는 옵션](img/domain_denylist_v14_1.png)

## LDAP 사용자 필터 설정 {#set-up-ldap-user-filter}

LDAP 서버의 LDAP 사용자의 하위 집합에 대한 GitLab 액세스를 제한할 수 있습니다.

자세한 내용은 [LDAP 사용자 필터 설정에 대한 설명서](../auth/ldap/_index.md#set-up-ldap-user-filter)를 참조하세요.

## 역할 승격에 대한 관리자 승인 켜기 {#turn-on-administrator-approval-for-role-promotions}

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- `member_promotion_management`라는 이름의 [플래그와 함께](../feature_flags/_index.md) [GitLab 16.9에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/433166).
- 기능 플래그 `member_promotion_management`가 GitLab 17.5에서 `wip`에서 `beta`로 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/167757/)되었으며 기본적으로 활성화되었습니다.
- 기능 플래그 `member_promotion_management`가 GitLab 18.0에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/187888)되었습니다.

{{< /history >}}

기존 사용자가 프로젝트 또는 그룹의 청구 대상 역할로 승격되는 것을 방지하려면 역할 승격에 대한 관리자 승인을 켜십시오. 그러면 [승인 대기 중인](../moderate_users.md#view-users-pending-role-promotion) 승격 요청을 승인하거나 거부할 수 있습니다.

- 관리자가 사용자를 그룹 또는 프로젝트에 추가하는 경우:
  - 새 사용자 역할이 [청구 대상](../../subscriptions/manage_seats.md#billable-users)인 경우 해당 사용자에 대한 다른 모든 멤버십 요청은 자동으로 승인됩니다.
  - 새 사용자 역할이 청구 대상이 아닌 경우 해당 사용자에 대한 다른 요청은 관리자 승인을 받을 때까지 대기 상태로 유지됩니다.
- 관리자가 아닌 사용자가 사용자를 그룹 또는 프로젝트에 추가하는 경우:
  - 사용자가 그룹 또는 프로젝트에서 청구 대상 역할을 갖지 않고 있으며 청구 대상 역할로 추가되거나 승격되는 경우 해당 요청은 [관리자 승인을 받을 때까지 대기](../moderate_users.md#view-users-pending-role-promotion) 상태로 유지됩니다.
  - 사용자가 이미 청구 대상 역할을 가지고 있으면 관리자 승인이 필요하지 않습니다.

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

역할 승격에 대한 승인을 켜려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **사용자 계정 생성 제한사항**을 확장합니다.
1. **좌석 제어** 섹션에서 **역할 승격 승인**을 선택합니다.

> [!note]
> 이 승인 요구사항은 [LDAP 동기화](../auth/ldap/ldap_synchronization.md) 또는 [SAML 그룹 링크](../../user/group/saml_sso/group_sync.md)에 의해 부여된 멤버십에는 적용되지 않습니다. LDAP 또는 SAML을 통해 역할 승격을 받는 사용자는 이전에 청구 대상 역할을 가지고 있었는지 여부에 관계없이 관리자 승인이 필요하지 않습니다.
