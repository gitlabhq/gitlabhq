---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: 로그인 제한
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

로그인 제한을 사용하여 웹 인터페이스 및 HTTP(S)를 통한 Git에 대한 인증 제한을 사용자 지정합니다.

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

## 비밀번호 및 패스키 인증 {#password-and-passkey-authentication}

### 웹 인터페이스에 대한 비밀번호 및 패스키 인증 허용 {#allow-password-and-passkey-authentication-for-the-web-interface}

이 설정은 기본적으로 활성화되어 있습니다. 비활성화되면 사용자는 표준 로그인 화면을 사용할 수 없으며 대신 [외부 인증 공급자](../auth/_index.md)를 사용해야 합니다. 이것은 또한 2단계 인증을 위해 패스키를 사용하는 것을 비활성화합니다.

웹 인터페이스에 대한 비밀번호 및 패스키 인증을 허용하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **로그인 제한** 섹션을 확장합니다.
1. **웹 인터페이스에 대한 비밀번호 및 패스키 인증 허용** 확인란을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

> [!note]
> 외부 인증 공급자에 장애가 발생한 경우 [GitLab Rails 콘솔](../operations/rails_console.md) 을 사용하여 [표준 웹 로그인 양식을 다시 활성화](#re-enable-standard-web-sign-in-form-in-rails-console)합니다. 또한 [Application settings API](../../api/settings.md#update-application-settings)를 사용하여 `password_authentication_enabled_for_web` 설정을 구성할 수 있습니다.

### HTTP(S)를 통한 Git 비밀번호 인증 허용 {#allow-password-authentication-for-git-over-https}

이 설정은 기본적으로 활성화되어 있습니다. 비활성화되면 사용자는 [개인 액세스 토큰](../../user/profile/personal_access_tokens.md) 또는 LDAP 비밀번호로 인증해야 합니다.

HTTP(S)를 통한 Git 비밀번호 인증을 허용하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **로그인 제한** 섹션을 확장합니다.
1. **HTTP(S)를 통한 Git 비밀번호 인증 허용** 확인란을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

### SSO ID를 사용하는 사용자에 대해 비밀번호 및 패스키 인증 비활성화 {#disable-password-and-passkey-authentication-for-users-with-an-sso-identity}

조직에서는 SSO 사용자가 비밀번호 또는 패스키로 로그인하는 것을 제한하고 대신 외부 인증 공급자를 사용하도록 요구할 수 있습니다. 이것은 웹 인터페이스 및 HTTP(S)를 통한 Git에 대한 비밀번호 인증과 웹 인터페이스에 대한 패스키 인증을 제한합니다. 패스키는 HTTP(S)를 통한 Git과 함께 사용될 수 없습니다.

SSO ID를 사용하는 사용자에 대해 비밀번호 및 패스키 인증을 비활성화하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **로그인 제한** 섹션을 확장합니다.
1. **SSO ID를 사용하는 사용자에 대해 비밀번호 및 패스키 인증 비활성화** 확인란을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

## 2단계 인증 {#two-factor-authentication}

사용자에게 계정에 대한 2단계 인증(2FA) 방법을 등록하도록 요구할 수 있습니다.

### 모든 사용자에 대해 2단계 인증 강제 적용 {#enforce-two-factor-authentication-for-all-users}

이것은 관리자를 포함한 모든 사용자가 2FA 방법을 등록해야 합니다.

모든 사용자에 대해 2단계 인증을 강제 적용하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **로그인 제한** 섹션을 확장합니다.
1. **2단계 인증 강제 적용** 확인란을 선택합니다.
1. 선택사항. **2단계 인증 유예 기간**에서 시간 수를 입력합니다. 사용자는 이 시간이 끝나면 2FA 방법을 등록해야 합니다. 다음 로그인 시 등록을 강제 적용하려면 `0`로 설정합니다.
1. **변경 사항 저장**을 선택합니다.

### 관리자에 대해 2단계 인증 강제 적용 {#enforce-two-factor-authentication-for-administrators}

이것은 관리자만 2FA 방법을 등록해야 합니다. 이것은 또한 [사용자 지정 관리자 역할](../../user/custom_roles/_index.md)이 있는 사용자를 포함합니다.

관리자에 대해 2단계 인증을 강제 적용하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **로그인 제한** 섹션을 확장합니다.
1. **운영자에 대해 2단계 인증 강제적용** 확인란을 선택합니다.
1. 선택사항. **2단계 인증 유예 기간**에서 시간 수를 입력합니다. 사용자는 이 시간이 끝나면 2FA 방법을 등록해야 합니다. 다음 로그인 시 등록을 강제 적용하려면 `0`로 설정합니다.
1. **변경 사항 저장**을 선택합니다.

### 이메일 OTP 활성화 {#enable-email-otp}

사용자가 [이메일 일회용 비밀번호](../../user/profile/account/two_factor_authentication.md#enable-email-otp)를 구성할 수 있도록 허용하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **로그인 제한** 섹션을 확장합니다.
1. **Enable email-based one-time passwords** 확인란과 **Require email verification when account is locked** 확인란을 모두 선택합니다.
1. **변경 사항 저장**을 선택합니다.

## 운영자 모드 {#admin-mode}

관리자인 경우 관리자 액세스 권한 없이 GitLab에서 작업하고 싶을 수도 있습니다. 관리자 액세스 권한이 없는 별도의 사용자 계정을 생성하거나 운영자 모드를 사용할 수 있습니다.

운영자 모드를 사용하면 계정에 기본적으로 관리자 액세스 권한이 없습니다. 구성원인 그룹 및 프로젝트에 계속 액세스할 수 있습니다. 그러나 관리 작업의 경우 인증해야 합니다([특정 기능](#known-issues) 제외).

운영자 모드가 활성화되면 인스턴스의 모든 관리자에게 적용됩니다.

인스턴스에 대해 운영자 모드가 활성화되면 관리자는:

- 구성원인 그룹 및 프로젝트에 액세스할 수 있습니다.
- **운영자** 영역에 액세스할 수 없습니다.

### 인스턴스에 대해 운영자 모드 활성화 {#enable-admin-mode-for-your-instance}

관리자는 API, Rails 콘솔 또는 UI를 통해 운영자 모드를 활성화할 수 있습니다.

#### API를 사용하여 운영자 모드 활성화 {#use-the-api-to-enable-admin-mode}

인스턴스 엔드포인트에 다음 요청을 합니다:

```shell
curl --request PUT --header "PRIVATE-TOKEN:$ADMIN_TOKEN" "<gitlab.example.com>/api/v4/application/settings?admin_mode=true"
```

`<gitlab.example.com>`을 인스턴스 URL로 바꿉니다.

자세한 내용은 [API 호출을 통해 액세스할 수 있는 설정 목록](../../api/settings.md)을 참조하세요.

#### Rails 콘솔을 사용하여 운영자 모드 활성화 {#use-the-rails-console-to-enable-admin-mode}

{{< details >}}

- 제공 서비스: GitLab Self-Managed

{{< /details >}}

[Rails 콘솔](../operations/rails_console.md)을 열고 다음을 실행합니다:

```ruby
::Gitlab::CurrentSettings.update!(admin_mode: true)
```

#### UI를 사용하여 운영자 모드 활성화 {#use-the-ui-to-enable-admin-mode}

UI를 통해 운영자 모드를 활성화하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **로그인 제한**을 확장합니다.
1. **운영자 모드 활성화**를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

### 세션에 대해 운영자 모드 활성화 {#turn-on-admin-mode-for-your-session}

현재 세션에 대해 운영자 모드를 활성화하고 잠재적으로 위험한 리소스에 액세스하려면:

1. 오른쪽 상단 모서리에서 아바타를 선택합니다.
1. **운영자 모드 시작**을 선택합니다.
1. URL에 `/admin`이 있는 UI의 모든 부분에 액세스해 봅니다(관리자 액세스 권한이 필요함).

운영자 모드 상태가 비활성화되거나 꺼져 있으면 관리자는 명시적으로 액세스 권한이 부여되지 않은 리소스에 액세스할 수 없습니다. 예를 들어 관리자가 해당 그룹 또는 프로젝트의 구성원이 아닌 경우 비공개 그룹 또는 프로젝트를 열려고 하면 `404` 오류가 발생합니다.

관리자에 대해 2FA를 활성화해야 합니다. 2FA, OmniAuth 공급자 및 LDAP 인증은 운영자 모드에서 지원됩니다. 운영자 모드 상태는 현재 사용자 세션에 저장되며 다음 중 하나가 될 때까지 활성 상태를 유지합니다:

- 명시적으로 비활성화됩니다.
- 6시간 후 자동으로 비활성화됩니다.

### 세션에서 운영자 모드가 활성화되어 있는지 확인 {#check-if-your-session-has-admin-mode-enabled}

{{< history >}}

- GitLab 16.10에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/438674) [플래그](../feature_flags/_index.md) `show_admin_mode_within_active_sessions` 이름으로. 기본적으로 비활성화됨.
- GitLab 16.10에서 [GitLab.com에서 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/444188).
- GitLab 17.0에서 [일반 공급 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/438674). 기능 플래그 `show_admin_mode_within_active_sessions` 제거됨.

{{< /history >}}

활성 세션 목록으로 이동합니다:

1. 오른쪽 상단 모서리에서 아바타를 선택합니다.
1. **프로필 편집**을 선택합니다.
1. 왼쪽 사이드바에서 **액세스** > **활성 세션**을 선택합니다.

운영자 모드가 켜져 있는 세션은 **`date of session`에 로그인된 운영자 모드** 텍스트를 표시합니다.

### 세션에 대해 운영자 모드 비활성화 {#turn-off-admin-mode-for-your-session}

현재 세션에 대해 운영자 모드를 비활성화하려면:

1. 오른쪽 상단 모서리에서 아바타를 선택합니다.
1. **운영자 모드 나가기**를 선택합니다.

### 알려진 이슈 {#known-issues}

운영자 모드는 6시간 후 시간 초과되며 이 시간 제한을 변경할 수 없습니다.

다음 액세스 방법은 운영자 모드로 보호되지 않습니다:

- Git 클라이언트 액세스(퍼블릭 키를 사용한 SSH 또는 개인 액세스 토큰을 사용한 HTTPS).

즉, 운영자 모드로 제한된 관리자는 추가 인증 단계 없이 Git 클라이언트를 계속 사용할 수 있습니다.

GitLab REST 또는 GraphQL API를 사용하려면 관리자는 [개인 액세스 토큰 생성](../../user/profile/personal_access_tokens.md#create-a-personal-access-token) 또는 [OAuth 토큰 생성](../../api/oauth2.md)을 [`admin_mode` 범위](../../user/profile/personal_access_tokens.md#personal-access-token-scopes)로 해야 합니다.

`admin_mode` 범위를 가진 개인 액세스 토큰이 있는 관리자가 관리자 액세스 권한을 잃으면 `admin_mode` 범위를 가진 토큰이 여전히 있더라도 해당 사용자는 관리자로 API에 액세스할 수 없습니다. 자세한 내용은 [에픽 2158](https://gitlab.com/groups/gitlab-org/-/epics/2158)을 참조하세요.

또한 GitLab Geo가 활성화되면 보조 노드에 있는 동안 프로젝트 및 디자인의 복제 상태를 볼 수 없습니다. 프로젝트([이슈 367926](https://gitlab.com/gitlab-org/gitlab/-/issues/367926) ) 및 디자인([이슈 355660](https://gitlab.com/gitlab-org/gitlab/-/issues/355660))이 새로운 Geo 프레임워크로 이동할 때 수정이 제안됩니다.

### 운영자 모드 문제 해결 {#troubleshooting-admin-mode}

필요한 경우 다음 두 가지 방법 중 하나를 사용하여 관리자가 **운영자 모드**를 비활성화할 수 있습니다:

- API: 

  ```shell
  curl --request PUT --header "PRIVATE-TOKEN:$ADMIN_TOKEN" "<gitlab-url>/api/v4/application/settings?admin_mode=false"
  ```

- [Rails 콘솔](../operations/rails_console.md#starting-a-rails-console-session):

  ```ruby
  ::Gitlab::CurrentSettings.update!(admin_mode: false)
  ```

## 알려지지 않은 로그인에 대한 이메일 알림 {#email-notification-for-unknown-sign-ins}

활성화되면 GitLab은 사용자에게 알려지지 않은 IP 주소 또는 장치에서의 로그인을 알립니다. 자세한 내용은 [알려지지 않은 로그인에 대한 이메일 알림](../../user/profile/notifications.md#notifications-for-unknown-sign-ins)을 참조하세요.

![알려지지 않은 로그인에 대해 이메일 알림이 활성화되었습니다.](img/email_notification_for_unknown_sign_ins_v13_2.png)

## 로그인 정보 {#sign-in-information}

{{< history >}}

- **Sign-in text** 설정이 GitLab 17.0에서 [더 이상 사용되지 않습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/410885).

{{< /history >}}

로그인하지 않은 모든 사용자는 구성된 **홈페이지 URL**로 표시되는 페이지로 리디렉션됩니다(값이 비어 있지 않은 경우).

모든 사용자는 구성된 **로그아웃 페이지 URL**로 표시되는 페이지로 로그아웃 후 리디렉션됩니다(값이 비어 있지 않은 경우).

로그인 페이지에 도움말 메시지를 추가하려면 [로그인 및 등록 페이지 사용자 지정](../appearance.md#customize-your-sign-in-and-register-pages)을 참조하세요.

## 문제 해결 {#troubleshooting}

### Rails 콘솔에서 표준 웹 로그인 양식 다시 활성화 {#re-enable-standard-web-sign-in-form-in-rails-console}

{{< details >}}

- 제공 서비스: GitLab Self-Managed

{{< /details >}}

[로그인 제한](#password-and-passkey-authentication)으로 비활성화된 경우 표준 사용자 이름 및 비밀번호 기반 로그인 양식을 다시 활성화합니다.

구성된 외부 인증 공급자(SSO 또는 LDAP 구성을 통해)가 중단되고 GitLab에 직접 로그인 액세스가 필요한 경우 [Rails 콘솔](../operations/rails_console.md#starting-a-rails-console-session)을 통해 이 방법을 사용할 수 있습니다.

```ruby
Gitlab::CurrentSettings.update!(password_authentication_enabled_for_web: true)
```
