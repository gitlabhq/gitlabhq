---
stage: Fulfillment
group: Provision
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "사용자를 차단, 비활성화, 계정정지하거나 신뢰할 수 있는 사용자로 설정하여 인스턴스 액세스 및 활동을 제어합니다."
gitlab_dedicated: yes
title: 사용자 조정
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

인스턴스 관리자이면 사용자 액세스를 조정하고 제어할 수 있는 여러 옵션이 있습니다.

> [!note]
> 이 항목은 GitLab Self-Managed의 사용자 조정과 관련이 있습니다. 그룹과 관련된 정보는 [그룹 설명서](../user/group/moderate_users.md)를 참조하세요.

## 사용자 보기 {#view-users}

인스턴스의 모든 사용자를 보려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **사용자**를 선택합니다.

사용자를 선택하여 계정 정보를 봅니다.

### 사용자를 유형별로 보기 {#view-users-by-type}

{{< history >}}

- 사용자를 유형별로 필터링하는 기능이 [GitLab 18.1에 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/541186).

{{< /history >}}

설정된 GitLab 인스턴스는 많은 수의 인간 사용자 및 봇 사용자를 보유할 수 있습니다. 사용자 목록을 필터링하여 인간 사용자 또는 [봇 사용자](internal_users.md)만 표시할 수 있습니다.

사용자를 유형별로 보려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **사용자**를 선택합니다.
1. 검색 상자에 필터를 입력합니다.
   - 인간 사용자를 표시하려면 **Type=Humans**를 입력합니다.
   - 봇 사용자를 표시하려면 **Type=Bots**를 입력합니다.
1. <kbd>Enter</kbd> 키를 누릅니다.

## 청구 대상 사용자 {#billable-users}

Rails 콘솔을 통해 인스턴스의 [청구 대상 사용자](../subscriptions/manage_seats.md#billable-users)를 보고 업데이트할 수 있습니다.

### 일일 및 과거 청구 대상 사용자 확인 {#check-daily-and-historical-billable-users}

GitLab 인스턴스의 일일 및 과거 청구 대상 사용자 목록을 가져오려면:

1. [Rails 콘솔 세션 시작](operations/rails_console.md#starting-a-rails-console-session).
1. 인스턴스의 사용자 수를 셉니다:

   ```ruby
   User.billable.count
   ```

1. 지난 1년 동안 인스턴스의 역사적 최대 사용자 수를 가져옵니다:

   ```ruby
   ::HistoricalData.max_historical_user_count(from: 1.year.ago.beginning_of_day, to: Time.current.end_of_day)
   ```

### 일일 및 과거 청구 대상 사용자 업데이트 {#update-daily-and-historical-billable-users}

GitLab 인스턴스의 일일 및 과거 청구 대상 사용자를 수동으로 업데이트하려면:

1. [Rails 콘솔 세션 시작](operations/rails_console.md#starting-a-rails-console-session).
1. 일일 청구 대상 사용자의 업데이트를 강제합니다:

   ```ruby
   identifier = Analytics::UsageTrends::Measurement.identifiers[:billable_users]
   ::Analytics::UsageTrends::CounterJobWorker.new.perform(identifier, User.minimum(:id), User.maximum(:id), Time.zone.now)
   ```

1. 과거 최대 청구 대상 사용자의 업데이트를 강제합니다:

   ```ruby
   ::HistoricalDataWorker.new.perform
   ```

## 승인 대기중 사용자 {#users-pending-approval}

승인 대기중 상태의 사용자는 관리자의 조치가 필요합니다. 관리자가 다음 옵션 중 하나를 활성화했기 때문에 사용자 가입이 승인 대기중 상태가 될 수 있습니다:

- [새로운 사용자 계정 생성을 위해 관리자 승인 필요](settings/sign_up_restrictions.md#require-administrator-approval-for-new-user-accounts) 설정.
- [사용자 제한](settings/sign_up_restrictions.md#user-cap).
- [제한된 액세스](settings/sign_up_restrictions.md#restricted-access) (사용 가능한 라이선스 좌석이 없을 때), [휴면 사용자](settings/sign_up_restrictions.md#dormant-user-reactivation)가 다시 로그인하려고 시도할 때.
- [자동 생성된 사용자 차단(OmniAuth)](../integration/omniauth.md#configure-common-settings)
- [자동 생성된 사용자 차단(LDAP)](auth/ldap/_index.md#basic-configuration-settings)

이 설정이 활성화된 상태에서 사용자가 계정을 등록하면:

- 사용자는 **승인 대기중** 상태로 설정됩니다.
- 사용자는 자신의 계정이 관리자의 승인을 대기 중이라는 메시지를 봅니다.

승인 대기중 사용자:

- [차단된](#block-a-user) 사용자와 기능상 동일합니다.
- 로그인할 수 없습니다.
- Git 리포지토리 또는 GitLab API에 액세스할 수 없습니다.
- GitLab에서 어떤 알림도 받지 않습니다.
- [사용자](../subscriptions/manage_seats.md#billable-users)를 소비하지 않습니다.

관리자는 [가입을 승인](#approve-or-reject-a-new-user-account)해야 로그인할 수 있습니다.

### 승인 대기중 사용자 가입 보기 {#view-user-sign-ups-pending-approval}

{{< history >}}

- 사용자를 상태별로 필터링하는 기능이 [GitLab 17.0에 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/238183).

{{< /history >}}

승인 대기중 사용자 가입을 보려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **사용자**를 선택합니다.
1. 검색 상자에서 **State=Pending approval**으로 필터링하고 <kbd>Enter</kbd> 키를 누릅니다.

### 새로운 사용자 계정 승인 또는 거부 {#approve-or-reject-a-new-user-account}

{{< history >}}

- 사용자를 상태별로 필터링하는 기능이 [GitLab 17.0에 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/238183).

{{< /history >}}

승인 대기중 사용자 가입은 **운영자** 영역에서 승인하거나 거부할 수 있습니다.

사용자 가입을 승인하거나 거부하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **사용자**를 선택합니다.
1. 검색 상자에서 **State=Pending approval**으로 필터링하고 <kbd>Enter</kbd> 키를 누릅니다.
1. 승인 또는 거부하려는 사용자 가입에 대해 세로 줄임표({{< icon name="ellipsis_v" >}})를 선택한 다음 **승인** 또는 **거부**를 선택합니다.

사용자 승인:

- 자신의 계정을 활성화합니다.
- 사용자의 상태를 활성 상태로 변경합니다.
- 구독 [사용자](../subscriptions/manage_seats.md#billable-users)를 소비합니다.

사용자 거부:

- 사용자가 로그인하거나 인스턴스 정보에 액세스하는 것을 방지합니다.
- 사용자를 삭제합니다.

## 역할 승격 대기중 사용자 보기 {#view-users-pending-role-promotion}

[역할 승격에 대한 관리자 승인](settings/sign_up_restrictions.md#turn-on-administrator-approval-for-role-promotions)이 켜져 있으면 기존 사용자를 청구 가능한 역할로 승격하는 멤버십 요청에 관리자 승인이 필요합니다.

역할 승격 대기중 사용자를 보려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **사용자**를 선택합니다.
1. **역할 승격**을 선택합니다.

가장 높은 역할이 요청된 사용자 목록이 표시됩니다. **승인** 또는 **거부** 요청을 할 수 있습니다.

## 사용자 차단 및 차단 해제 {#block-and-unblock-users}

GitLab 관리자는 사용자를 차단하고 차단을 해제할 수 있습니다. 인스턴스에 액세스하지 않도록 사용자를 차단하되 데이터를 유지하려면 사용자를 차단해야 합니다.

차단된 사용자:

- 로그인하거나 리포지토리에 액세스할 수 없습니다.
  - 관련 데이터는 이 리포지토리에 유지됩니다.
- [Slack의 슬래시 명령어](../user/project/integrations/gitlab_slack_application.md#slash-commands)를 사용할 수 없습니다.
- [사용자](../subscriptions/manage_seats.md#billable-users)를 차지하지 않습니다.

### 사용자 차단 {#block-a-user}

전제 조건:

- 인스턴스의 관리자여야 합니다.

사용자의 인스턴스 액세스를 차단할 수 있습니다.

사용자를 차단하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **사용자**를 선택합니다.
1. 차단하려는 사용자에 대해 세로 줄임표({{< icon name="ellipsis_v" >}})를 선택한 다음 **차단**을 선택합니다.

다른 사용자로부터의 남용을 신고하려면 [남용 신고](../user/report_abuse.md)를 참조하세요. **운영자** 영역의 남용 보고서에 대한 자세한 정보는 [남용 보고서 해결](review_abuse_reports.md#resolving-abuse-reports)을 참조하세요.

### 사용자 차단 해제 {#unblock-a-user}

{{< history >}}

- 사용자를 상태별로 필터링하는 기능이 [GitLab 17.0에 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/238183).

{{< /history >}}

사용자의 차단을 해제하여 인스턴스에 대한 액세스를 다시 얻을 수 있습니다.

사용자의 차단을 해제하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **사용자**를 선택합니다.
1. 검색 상자에서 **State=Blocked**로 필터링하고 <kbd>Enter</kbd> 키를 누릅니다.
1. 차단 해제하려는 사용자에 대해 세로 줄임표({{< icon name="ellipsis_v" >}})를 선택한 다음 **차단 해제**를 선택합니다.

사용자의 상태가 활성으로 설정되고 [사용자](../subscriptions/manage_seats.md#billable-users)를 소비합니다.

> [!note]
> 사용자는 [GitLab API](../api/user_moderation.md#unblock-access-to-a-user)를 사용하여 차단을 해제할 수도 있습니다.

LDAP 사용자의 경우 차단 해제 옵션을 사용할 수 없을 수 있습니다. 차단 해제 옵션을 활성화하려면 먼저 LDAP ID를 삭제해야 합니다:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **사용자**를 선택합니다.
1. 검색 상자에서 **State=Blocked**로 필터링하고 <kbd>Enter</kbd> 키를 누릅니다.
1. 사용자를 선택합니다.
1. **ID** 탭을 선택합니다.
1. LDAP 공급자를 찾아 **삭제**를 선택합니다.

## 사용자 비활성화 및 재활성화 {#deactivate-and-reactivate-users}

GitLab 관리자는 사용자를 비활성화하고 재활성화할 수 있습니다. 사용자가 최근 활동이 없고 인스턴스의 좌석을 차지하지 않도록 하려면 사용자를 비활성화해야 합니다.

GitLab은 `last_active_at` 타임스탬프를 기준으로 사용자의 최근 활동을 결정하며, 이는 다음 중 가장 최근입니다:

- `last_activity_on`:  사용자가 GitLab에서 마지막으로 기록한 활동의 타임스탬프입니다(문제, 머지 리퀘스트 또는 댓글 생성 등).
- `current_sign_in_at`:  사용자의 가장 최근 로그인 타임스탬프입니다.

사용자의 현재 로그인 타임스탬프가 마지막으로 기록한 활동보다 최신이면 로그인 후 GitLab 기능을 사용하지 않았더라도 사용자는 최근에 활동한 것으로 간주됩니다.

비활성화된 사용자:

- GitLab에 로그인할 수 있습니다.
  - 비활성화된 사용자가 로그인하면 자동으로 재활성화됩니다.
- 리포지토리 또는 API에 액세스할 수 없습니다.
- [Slack의 슬래시 명령어](../user/project/integrations/gitlab_slack_application.md#slash-commands)를 사용할 수 없습니다.
- 좌석을 차지하지 않습니다. 자세한 정보는 [청구 대상 사용자](../subscriptions/manage_seats.md#billable-users)를 참조하세요.

사용자를 비활성화하면 프로젝트, 그룹 및 기록이 유지됩니다.

### 사용자 비활성화 {#deactivate-a-user}

전제 조건:

- 사용자가 지난 90일 동안 활동이 없었습니다.

사용자를 비활성화하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **사용자**를 선택합니다.
1. 비활성화하려는 사용자에 대해 세로 줄임표({{< icon name="ellipsis_v" >}}) 다음 **비활성화**를 선택합니다.
1. 대화 상자에서 **비활성화**를 선택합니다.

사용자는 자신의 계정이 비활성화되었다는 이메일 알림을 받습니다. 이 이메일 이후 더 이상 알림을 받지 않습니다. 자세한 정보는 [사용자 비활성화 이메일](settings/email.md#user-deactivation-emails)을 참조하세요.

GitLab API로 사용자를 비활성화하려면 [사용자 비활성화](../api/user_moderation.md#deactivate-a-user)를 참조하세요. 영구적 사용자 제한에 대한 정보는 [사용자 차단 및 차단 해제](#block-and-unblock-users)를 참조하세요.

GitLab.com 구독에서 사용자를 제거하려면 [구독에서 사용자 제거](../subscriptions/manage_seats.md#remove-users-from-subscription)를 참조하세요.

### 휴면 사용자 자동 비활성화 {#automatically-deactivate-dormant-users}

{{< history >}}

- 사용자 정의 가능한 시간 기간이 [GitLab 15.4에 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/336747)
- 비활동 기간의 하한이 90일로 설정됨 [GitLab 15.5에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/100793)

{{< /history >}}

관리자는 다음 중 하나에 해당하는 사용자의 자동 비활성화를 활성화할 수 있습니다:

- 1주일 이상 전에 생성되었고 로그인하지 않았습니다.
- 지정된 기간(기본값 및 최소값은 90일) 동안 활동이 없습니다.

휴면 멤버를 자동으로 비활성화하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **계정과 제한** 섹션을 확장합니다.
1. **휴면 사용자** 아래에서 **비활동 기간 후 휴면 사용자 비활성화**를 확인합니다.
1. **비활성화되기 전의 비활동 기간** 아래에서 비활성화 전의 일 수를 입력합니다. 최소값은 90일입니다.
1. **변경 사항 저장**을 선택합니다.

이 기능이 활성화되면 GitLab은 휴면 사용자를 비활성화하는 일일 작업을 실행합니다.

하루에 최대 100,000명의 사용자를 비활성화할 수 있습니다.

기본적으로 사용자는 계정이 비활성화될 때 이메일 알림을 받습니다. [사용자 비활성화 이메일](settings/email.md#user-deactivation-emails)을 비활성화할 수 있습니다.

> [!note]
> GitLab에서 생성한 봇은 휴면 사용자의 자동 비활성화에서 제외됩니다.

### 확인되지 않은 사용자 자동 삭제 {#automatically-delete-unconfirmed-users}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [GitLab 16.1에서 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/352514) [플래그](feature_flags/_index.md) 이름 `delete_unconfirmed_users_setting`. 기본적으로 비활성화됨.
- [GitLab 16.2에서 기본적으로 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124982).

{{< /history >}}

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

다음 두 가지 조건을 모두 충족하는 사용자의 자동 삭제를 활성화할 수 있습니다:

- 이메일 주소를 확인한 적이 없습니다.
- 지정된 날 수보다 오래 전에 GitLab에 가입했습니다.

[설정 API](../api/settings.md)를 사용하거나 Rails 콘솔에서 이러한 설정을 구성할 수 있습니다:

```ruby
 Gitlab::CurrentSettings.update(delete_unconfirmed_users: true)
 Gitlab::CurrentSettings.update(unconfirmed_users_delete_after_days: 365)
```

`delete_unconfirmed_users` 설정이 활성화되면 GitLab은 확인되지 않은 사용자를 삭제하는 작업을 1시간에 한 번 실행합니다. 이 작업은 `unconfirmed_users_delete_after_days` 일 이상 전에 가입한 사용자만 삭제합니다.

이 작업은 `email_confirmation_setting`이 `soft` 또는 `hard`로 설정되어 있을 때만 실행됩니다.

하루에 최대 240,000명의 사용자를 삭제할 수 있습니다.

### 사용자 재활성화 {#reactivate-a-user}

{{< history >}}

- 사용자를 상태별로 필터링하는 기능이 [GitLab 17.0에 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/238183).

{{< /history >}}

사용자를 재활성화하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **사용자**를 선택합니다.
1. 검색 상자에서 **State=Deactivated**로 필터링하고 <kbd>Enter</kbd> 키를 누릅니다.
1. 재활성화하려는 사용자에 대해 세로 줄임표({{< icon name="ellipsis_v" >}}) 다음 **활성화**를 선택합니다.

사용자의 상태가 활성으로 설정되고 [사용자](../subscriptions/manage_seats.md#billable-users)를 소비합니다.

> [!note]
> 비활성화된 사용자는 UI를 통해 다시 로그인하여 자신의 계정을 재활성화할 수도 있습니다. 사용자는 [GitLab API](../api/user_moderation.md#reactivate-a-user)를 사용하여 재활성화할 수도 있습니다.
>
> [제한된 액세스](settings/sign_up_restrictions.md#restricted-access)가 활성화되어 있고 사용 가능한 라이선스 좌석이 없을 때, 다시 로그인하려는 휴면 사용자는 재활성화되지 않고 승인 대기중으로 설정됩니다.

## 사용자 계정정지 및 계정정지 해제 {#ban-and-unban-users}

{{< history >}}

- 계정정지된 사용자의 머지 리퀘스트 숨김 기능이 [GitLab 15.8에 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/107836) [플래그](feature_flags/_index.md) 이름 `hide_merge_requests_from_banned_users`. 기본적으로 비활성화됨.
- 계정정지된 사용자의 댓글 숨김 기능이 [GitLab 15.11에 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112973) [플래그](feature_flags/_index.md) 이름 `hidden_notes`. 기본적으로 비활성화됨.
- 계정정지된 사용자의 프로젝트 숨김 기능이 [GitLab 16.2에 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121488) [플래그](feature_flags/_index.md) 이름 `hide_projects_of_banned_users`. 기본적으로 비활성화됨.
- 계정정지된 사용자의 머지 리퀘스트 숨김 기능이 [GitLab 18.0에서 일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/188770)합니다. 기능 플래그 `hide_merge_requests_from_banned_users` 제거됨.

{{< /history >}}

GitLab 관리자는 사용자를 계정정지하고 계정정지를 해제할 수 있습니다. 사용자를 차단하고 인스턴스에서 해당 활동을 숨기려면 사용자를 계정정지해야 합니다.

계정정지된 사용자:

- 로그인하거나 리포지토리에 액세스할 수 없습니다.
  - 관련된 프로젝트, 이슈, 머지 리퀘스트 또는 댓글이 숨겨집니다.
- [Slack의 슬래시 명령어](../user/project/integrations/gitlab_slack_application.md#slash-commands)를 사용할 수 없습니다.
- [사용자](../subscriptions/manage_seats.md#billable-users)를 차지하지 않습니다.

### 사용자 계정정지 {#ban-a-user}

사용자를 차단하고 기여를 숨기기 위해 사용자를 계정정지할 수 있습니다.

사용자를 계정정지하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **사용자**를 선택합니다.
1. 계정정지하려는 멤버 옆에서 세로 줄임표({{< icon name="ellipsis_v" >}})를 선택합니다.
1. 드롭다운 목록에서 **멤버 계정정지**를 선택합니다.

### 사용자 계정정지 해제 {#unban-a-user}

{{< history >}}

- 사용자를 상태별로 필터링하는 기능이 [GitLab 17.0에 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/238183).

{{< /history >}}

사용자 계정정지를 해제하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **사용자**를 선택합니다.
1. 검색 상자에서 **State=Banned**로 필터링하고 <kbd>Enter</kbd> 키를 누릅니다.
1. 계정정지하려는 멤버 옆에서 세로 줄임표({{< icon name="ellipsis_v" >}})를 선택합니다.
1. 드롭다운 목록에서 **Unban member**를 선택합니다.

사용자의 상태가 활성으로 설정되고 [사용자](../subscriptions/manage_seats.md#billable-users)를 소비합니다.

## 사용자 삭제 {#delete-a-user}

사용자를 삭제하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **사용자**를 선택합니다.
1. 삭제하려는 사용자에 대해 세로 줄임표({{< icon name="ellipsis_v" >}})를 선택한 다음 **사용자 삭제**를 선택합니다.
1. 사용자 이름을 입력합니다.
1. 다음 중 하나를 선택합니다:
   - **사용자 삭제**는 사용자만 삭제합니다.
   - **사용자와 기여 삭제**를 사용하여 사용자와 머지 리퀘스트, 이슈, 자신이 유일한 그룹 소유자인 그룹 등의 기여를 삭제합니다.

> [!note]
> 사용자는 그룹의 상속된 소유자 또는 직접 소유자인 경우에만 삭제할 수 있습니다. 사용자가 유일한 그룹 소유자인 경우 삭제할 수 없습니다.

## 사용자 신뢰 및 신뢰 해제 {#trust-and-untrust-users}

{{< history >}}

- [GitLab 16.5에서 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132402).
- 사용자를 상태별로 필터링하는 기능이 [GitLab 17.0에 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/238183).

{{< /history >}}

기본적으로 사용자는 신뢰할 수 없으며 스팸으로 간주되는 이슈, 노트 및 스니펫을 만드는 것이 차단됩니다. 사용자를 신뢰하면 차단되지 않고 이슈, 노트 및 스니펫을 만들 수 있습니다.

### 사용자 신뢰 {#trust-a-user}

사용자를 신뢰하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **사용자**를 선택합니다.
1. 사용자를 선택합니다.
1. **사용자 관리** 드롭다운 목록에서 **신뢰할 수 있는 사용자**를 선택합니다.
1. 확인 대화 상자에서 **신뢰할 수 있는 사용자**를 선택합니다.

### 사용자 신뢰 해제 {#untrust-a-user}

사용자를 신뢰하지 않으려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **사용자**를 선택합니다.
1. 검색 상자에서 **State=Trusted**로 필터링하고 <kbd>Enter</kbd> 키를 누릅니다.
1. 사용자를 선택합니다.
1. **사용자 관리** 드롭다운 목록에서 **사용자 신뢰 해제**를 선택합니다.
1. 확인 대화 상자에서 **사용자 신뢰 해제**를 선택합니다.

## 문제 해결 {#troubleshooting}

{{< details >}}

- 제공 서비스: GitLab Self-Managed

{{< /details >}}

사용자를 조정할 때 특정 조건에 따라 대량 작업을 수행해야 할 수도 있습니다. 다음 Rails 콘솔 스크립트는 이에 대한 몇 가지 예를 보여줍니다. [Rails 콘솔 세션을 시작](operations/rails_console.md#starting-a-rails-console-session)하고 다음과 유사한 스크립트를 사용할 수 있습니다:

### 최근 활동이 없는 사용자 비활성화 {#deactivate-users-that-have-no-recent-activity}

관리자는 최근 활동이 없는 사용자를 비활성화할 수 있습니다.

> [!warning]
> 데이터를 변경하는 명령은 올바르게 실행되지 않거나 잘못된 조건에서 실행되면 손상을 초래할 수 있습니다. 항상 테스트 환경에서 먼저 명령을 실행하고 복원할 백업 인스턴스를 준비해 둡니다.

```ruby
days_inactive = 90
inactive_users = User.active.where("last_activity_on <= ?", days_inactive.days.ago)

inactive_users.each do |user|
    puts "user '#{user.username}': #{user.last_activity_on}"
    user.deactivate!
end
```

### 최근 활동이 없는 사용자 차단 {#block-users-that-have-no-recent-activity}

관리자는 최근 활동이 없는 사용자를 차단할 수 있습니다.

> [!warning]
> 데이터를 변경하는 명령은 올바르게 실행되지 않거나 잘못된 조건에서 실행되면 손상을 초래할 수 있습니다. 항상 테스트 환경에서 먼저 명령을 실행하고 복원할 백업 인스턴스를 준비해 둡니다.

```ruby
days_inactive = 90
inactive_users = User.active.where("last_activity_on <= ?", days_inactive.days.ago)

inactive_users.each do |user|
    puts "user '#{user.username}': #{user.last_activity_on}"
    user.block!
end
```

### 프로젝트 또는 그룹이 없는 사용자 차단 또는 삭제 {#block-or-delete-users-that-have-no-projects-or-groups}

관리자는 프로젝트 또는 그룹이 없는 사용자를 차단하거나 삭제할 수 있습니다.

> [!warning]
> 데이터를 변경하는 명령은 올바르게 실행되지 않거나 잘못된 조건에서 실행되면 손상을 초래할 수 있습니다. 항상 테스트 환경에서 먼저 명령을 실행하고 복원할 백업 인스턴스를 준비해 둡니다.

```ruby
users = User.where('id NOT IN (select distinct(user_id) from project_authorizations)')

# How many users are removed?
users.count

# If that count looks sane:

# You can either block the users:
users.each { |user|  user.blocked? ? nil  : user.block! }

# Or you can delete them:
  # need 'current user' (your user) for auditing purposes
current_user = User.find_by(username: '<your username>')

users.each do |user|
  DeleteUserWorker.perform_async(current_user.id, user.id)
end
```
