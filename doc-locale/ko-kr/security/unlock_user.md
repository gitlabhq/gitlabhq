---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 실패한 인증 시도로 인해 잠긴 계정의 잠금을 해제합니다.
title: 잠긴 사용자 계정
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- 구성 가능한 잠긴 사용자 정책이 GitLab 16.5에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/27048).

{{< /history >}}

GitLab은 여러 번 실패한 인증 시도 후 사용자 계정을 잠급니다. 계정의 잠금을 해제하려면 자동 잠금 해제 기간이 끝날 때까지 기다리거나 [비밀번호를 재설정하세요](https://gitlab.com/users/password/new).

다음 상황으로 인해 인증 시도가 실패할 수 있습니다:

- 로그인 중 잘못된 비밀번호.
- 로그인 중 잘못된 패스키.
- 2단계 인증(2FA) 챌린지 중 잘못된 일회용 비밀번호(OTP) 또는 패스키 코드.
- 프로필 설정을 업데이트할 때 잘못된 비밀번호.
- 비밀번호를 변경할 때 잘못된 현재 비밀번호.
- 관리자 모드를 활성화할 때 잘못된 2FA 코드.

잠금 및 잠금 해제 동작은 제공 서비스와 사용자의 2FA 상태에 따라 달라집니다:

- GitLab.com 또는 [계정 이메일 검증](email_verification.md)을 사용하는 GitLab 인스턴스에서:
  - 2FA 또는 외부 ID(SAML, OAuth)가 있는 계정은 10회 이상 실패한 후 잠깁니다. 이러한 계정은 10분 후 자동으로 잠금 해제됩니다.
  - 2FA 또는 외부 ID가 없는 계정은 24시간 내에 3회 이상 실패한 후 잠깁니다. 이러한 계정은 24시간 후 또는 이메일 검증으로 신원을 확인하여 자동으로 잠금 해제됩니다.
- 계정 이메일 검증이 없는 GitLab 인스턴스에서:
  - 모든 계정은 10회 이상 실패한 후 잠깁니다. 이러한 계정은 10분 후 자동으로 잠금 해제됩니다.

GitLab Self-Managed 및 GitLab Dedicated에서 [애플리케이션 설정 API](../api/settings.md#update-application-settings)를 사용하여 `max_login_attempts` 및 `failed_login_attempts_unlock_period_in_minutes` 잠금 제한을 구성합니다.

## 사용자 계정 수동으로 잠금 해제 {#manually-unlock-user-accounts}

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

전제 조건

- 인스턴스에 대한 관리자 액세스.

GitLab Self-Managed 및 GitLab Dedicated 인스턴스에서 관리자는 잠금 해제 기간이 끝나기 전에 계정의 잠금을 수동으로 해제할 수 있습니다.

{{< tabs >}}

{{< tab title="관리자 영역" >}}

관리자 영역에서 계정의 잠금을 해제하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **사용자**를 선택합니다.
1. 검색 표시줄을 사용하여 잠긴 사용자를 찾습니다.
1. **사용자 관리** 드롭다운 목록에서 **잠금 해제**를 선택합니다.

사용자는 이제 로그인할 수 있습니다.

{{< /tab >}}

{{< tab title="Rails 콘솔" >}}

Rails 콘솔에서 사용자 계정의 잠금을 해제하려면:

1. [Rails 콘솔 세션](../administration/operations/rails_console.md#starting-a-rails-console-session)을 시작합니다.
1. 잠금을 해제할 사용자를 찾습니다:

   - 사용자 이름별:

     ```ruby
     user = User.find_by_username('exampleuser')
     ```

   - 사용자 ID별:

     ```ruby
     user = User.find(123)
     ```

   - 이메일 주소별:

     ```ruby
     user = User.find_by(email: 'user@example.com')
     ```

1. 사용자의 잠금을 해제합니다:

   ```ruby
   user.unlock_access!
   ```

1. 콘솔을 종료합니다:

   ```ruby
   exit
   ```

사용자는 이제 로그인할 수 있습니다.

{{< /tab >}}

{{< /tabs >}}
