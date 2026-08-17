---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 2단계 인증 강제 적용
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[2단계 인증(2FA)](../user/profile/account/two_factor_authentication.md)는 사용자의 신원을 확인하기 위해 두 가지 다른 요소를 제공해야 하는 인증 방법입니다:

- 사용자 이름과 비밀번호입니다.
- 애플리케이션이 생성한 코드와 같은 두 번째 인증 방법입니다.

2FA는 두 가지 요소가 모두 필요하기 때문에 권한이 없는 사람이 계정에 액세스하기 어렵게 합니다.

> [!note]
> [SSO를 사용하고 강제 적용](../user/group/saml_sso/_index.md#sso-enforcement)하는 경우 ID 공급자(IdP) 측에서 이미 2FA를 강제 적용하고 있을 수 있습니다. GitLab에서 2FA를 강제 적용하는 것도 불필요할 수 있습니다.

## 모든 사용자에 대해 2FA 강제 적용 {#enforce-2fa-for-all-users}

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

관리자는 두 가지 방법으로 모든 사용자에 대해 2FA를 강제 적용할 수 있습니다:

- 다음 로그인 시 강제 적용합니다.
- 다음 로그인 시 제안하지만 강제 적용 전에 유예 기간을 허용합니다.

  구성된 유예 기간이 경과한 후 사용자는 로그인할 수 있지만 `/-/profile/two_factor_auth`의 2FA 구성 영역을 벗어날 수 없습니다.

UI 또는 API를 사용하여 모든 사용자에 대해 2FA를 강제 적용할 수 있습니다.

### UI 사용 {#use-the-ui}

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **로그인 제한**을(를) 확장합니다:
   - **2단계 인증 강제 적용**을(를) 선택하여 이 기능을 활성화합니다.
   - **2단계 인증 유예 기간**에 시간 수를 입력합니다. 다음 로그인 시도 시 2FA를 강제 적용하려면 `0`을(를) 입력합니다.

### API 사용 {#use-the-api}

[애플리케이션 설정 API](../api/settings.md)를 사용하여 다음 설정을 수정합니다:

- `require_two_factor_authentication`입니다.
- `two_factor_grace_period`입니다.

자세한 내용은 [API 호출을 통해 액세스할 수 있는 설정 목록](../api/settings.md#available-settings)을(를) 참조하세요.

## 관리자에 대해 2FA 강제 적용 {#enforce-2fa-for-administrators}

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.8에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/427549)되었습니다.
- 사용자 정의 관리자 역할이 있는 일반 사용자에 대해 2FA를 강제 적용하는 기능 지원이 [GitLab 18.3에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/556110)되었습니다.

{{< /history >}}

관리자는 다음 두 가지에 대해 2FA를 강제 적용할 수 있습니다:

- 관리자 사용자입니다.
- [사용자 정의 관리자 역할](../user/custom_roles/_index.md)이(가) 할당된 일반 사용자입니다.

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **로그인 제한** 섹션을 확장합니다:
   1. **운영자에 대해 2단계 인증 강제적용**을(를) 선택합니다.
   1. **2단계 인증 유예 기간**에 시간 수를 입력합니다. 다음 로그인 시도 시 2FA를 강제 적용하려면 `0`을(를) 입력합니다.
1. **변경 사항 저장**을 선택합니다.

> [!note]
> 외부 공급자를 사용하여 GitLab에 로그인하는 경우 이 설정은 사용자에 대해 2FA를 강제 적용하지 않습니다. 2FA는 해당 외부 공급자에서 활성화되어야 합니다.

## 그룹의 모든 사용자에 대해 2FA 강제 적용 {#enforce-2fa-for-all-users-in-a-group}

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

그룹 또는 하위 그룹의 모든 사용자에 대해 2FA를 강제 적용할 수 있습니다.

2FA 강제 적용은 [직접 및 상속된 멤버](../user/project/members/_index.md#membership-types) 그룹 멤버 모두에게 적용됩니다. 하위 그룹에서 2FA가 강제 적용되면 상속된 멤버는 인증 요소를 등록해야 합니다. 상속된 멤버는 상위 그룹의 멤버입니다.

> [!note]
> 이메일 OTP는 2FA 요구 사항을 충족하지 않습니다. 멤버는 앱 기반 TOTP 또는 WebAuthn을 구성해야 합니다.

전제 조건:

- 그룹의 Owner 역할이 있어야 합니다.

그룹에 대해 2FA를 강제 적용하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **Permissions and group features**를 확장합니다.
1. **이 그룹의 모든 사용자는 2단계 인증을 설정해야 합니다.**을(를) 선택합니다.
1. 선택 사항. **2FA 시행 지연 (시간)**에 유예 기간이 지속되기를 원하는 시간을 입력합니다. 최상위 그룹과 해당 하위 그룹 및 프로젝트에 여러 개의 서로 다른 유예 기간이 있으면 가장 짧은 유예 기간이 사용됩니다.
1. **변경 사항 저장**을 선택합니다.

액세스 토큰은 API 기반이기 때문에 인증을 위해 두 번째 요소를 제공할 필요가 없습니다. 2FA가 강제 적용되기 전에 생성된 토큰은 유효한 상태로 유지됩니다.

GitLab [수신 이메일](../administration/incoming_email.md) 기능은 2FA 강제 적용을 따르지 않습니다. 사용자는 먼저 2FA를 사용하여 자신을 인증할 필요 없이 이슈 생성 또는 머지 리퀘스트 댓글 달기와 같은 수신 이메일 기능을 사용할 수 있습니다. 2FA가 강제 적용되어도 이 적용됩니다.

### 하위 그룹의 2FA {#2fa-in-subgroups}

기본적으로 각 하위 그룹은 최상위 그룹과 다를 수 있는 2FA 요구 사항을 구성할 수 있습니다.

사용자가 계층의 여러 그룹의 멤버인 경우 가장 제한적인 2FA 요구 사항이 모든 수준에 적용됩니다.

예를 들어 최상위 그룹에서 2FA가 강제 적용되는 경우:

- 최상위 그룹의 모든 멤버는 2FA를 사용해야 합니다.
- 하위 그룹의 모든 멤버는 2FA를 사용해야 합니다.

최상위 그룹에서 2FA가 강제 적용되지 않는 경우:

- **하위 그룹에 대해 더 제한적인 2FA 적용 허용**이(가) 활성화되면 각 하위 그룹은 2FA 요구 사항을 독립적으로 강제 적용할 수 있습니다. 하위 그룹이 2FA 요구 사항을 활성화하면:
  - 최상위 그룹의 모든 멤버는 2FA를 사용해야 합니다.
  - 모든 형제 하위 그룹의 모든 멤버는 2FA를 사용해야 합니다.
- **하위 그룹에 대해 더 제한적인 2FA 적용 허용**이(가) 비활성화되면 하위 그룹은 2FA 요구 사항을 독립적으로 강제 적용할 수 없습니다. 계층의 어떤 멤버도 2FA가 필요하지 않습니다.

> [!note]
> **이 그룹의 모든 사용자는 2단계 인증을 설정해야 합니다.**이(가) 활성화되면 항상 **하위 그룹에 대해 더 제한적인 2FA 적용 허용**보다 우선합니다.

하위 그룹이 개별 2FA 요구 사항을 설정하지 못하도록 하려면:

1. 최상위 그룹의 **설정** > **일반**으로 이동합니다.
1. **권한 및 그룹 기능** 섹션을 확장합니다.
1. **하위 그룹에 대해 더 제한적인 2FA 적용 허용** 체크박스를 선택 해제합니다.

### 프로젝트의 2FA {#2fa-in-projects}

2FA를 활성화하거나 강제 적용하는 그룹에 속하는 프로젝트가 2FA를 활성화하거나 강제 적용하지 않는 그룹과 [공유](../user/project/members/sharing_projects_groups.md)되는 경우 비 2FA 그룹의 멤버는 2FA를 사용하지 않고 해당 프로젝트에 액세스할 수 있습니다. 예를 들어:

- 그룹 A는 2FA를 활성화하고 강제 적용합니다. 그룹 B는 2FA를 활성화하지 않습니다.
- 그룹 A에 속하는 프로젝트 P가 그룹 B와 공유되는 경우 그룹 B의 멤버는 2FA 없이 프로젝트 P에 액세스할 수 있습니다.

이러한 상황이 발생하지 않도록 하려면 2FA 그룹에 대해 [프로젝트 공유를 방지](../user/project/members/sharing_projects_groups.md#prevent-a-project-from-being-shared-with-groups)하세요.

> [!warning]
> 2FA가 활성화된 그룹 또는 하위 그룹의 프로젝트에 멤버를 추가하면 개별적으로 추가된 멤버에 대해 2FA가 필요하지 않습니다.

## 2FA 비활성화 {#disable-2fa}

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

단일 사용자 또는 모든 사용자에 대해 2FA를 비활성화할 수 있습니다.

이 작업은 영구적이며 되돌릴 수 없습니다. 사용자는 2FA를 다시 사용하려면 2FA를 다시 활성화해야 합니다.

> [!warning]
> 사용자에 대해 2FA를 비활성화해도 [모든 사용자에 대해 2FA 강제 적용](#enforce-2fa-for-all-users) 또는 [그룹의 모든 사용자에 대해 2FA 강제 적용](#enforce-2fa-for-all-users-in-a-group) 설정이 비활성화되지는 않습니다. 또한 사용자가 다음 번에 GitLab에 로그인할 때 2FA를 설정하도록 요청되지 않도록 강제 적용되는 모든 2FA 설정을 비활성화해야 합니다.

### 모든 사용자 {#for-all-users}

강제 2FA가 비활성화되어도 모든 사용자에 대해 2FA를 비활성화하려면 다음 Rake 작업을 사용합니다.

- Linux 패키지를 사용하는 설치의 경우:

  ```shell
  sudo gitlab-rake gitlab:two_factor:disable_for_all_users
  ```

- 자체 컴파일 설치의 경우:

  ```shell
  sudo -u git -H bundle exec rake gitlab:two_factor:disable_for_all_users RAILS_ENV=production
  ```

### 단일 사용자 {#for-a-single-user}

#### 관리자 {#administrators}

[Rails 콘솔](../administration/operations/rails_console.md)을(를) 사용하여 단일 관리자에 대해 2FA를 비활성화할 수 있습니다:

```ruby
admin = User.find_by_username('<USERNAME>')
user_to_disable = User.find_by_username('<USERNAME>')

TwoFactor::DestroyService.new(admin, user: user_to_disable).execute
```

관리자는 2FA가 비활성화되었다는 알림을 받습니다.

#### 관리자가 아닌 사용자 {#non-administrators}

Rails 콘솔 또는 [API 엔드포인트](../api/users.md#disable-two-factor-authentication-for-a-user)를 사용하여 관리자가 아닌 사용자에 대해 2FA를 비활성화할 수 있습니다.

자신의 계정에 대해 2FA를 비활성화할 수 있습니다.

API 엔드포인트를 사용하여 관리자에 대해 2FA를 비활성화할 수 없습니다.

#### 엔터프라이즈 사용자 {#enterprise-users}

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com

{{< /details >}}

최상위 그룹 소유자는 [엔터프라이즈 사용자](../user/enterprise_user/_index.md)에 대해 2FA(2단계 인증)를 비활성화할 수 있습니다.

2FA를 비활성화하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **관리** > **멤버**를 선택합니다.
1. **Enterprise** 및 **2단계 인증(2FA)** 배지가 있는 사용자를 찾습니다.
1. **추가 작업** ({{< icon name="ellipsis_v" >}}) 및 **2단계 인증 비활성화**를 선택합니다.

또한 [API를 사용](../api/group_enterprise_users.md#disable-two-factor-authentication-for-an-enterprise-user)하여 엔터프라이즈 사용자에 대해 2FA를 비활성화할 수 있습니다. 여기에는 더 이상 그룹의 멤버가 아닌 엔터프라이즈 사용자도 포함됩니다.

## Git over SSH 작업에 대한 2FA {#2fa-for-git-over-ssh-operations}

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

> [!flag]
> 기본적으로 이 기능은 사용할 수 없습니다. 사용 가능하게 하려면 관리자가 `two_factor_for_cli` [기능 플래그를 활성화](../administration/feature_flags/_index.md)할 수 있습니다. 이 기능은 프로덕션 사용을 위해 준비되지 않았습니다. 이 기능 플래그는 또한 [2FA가 활성화될 때 Git 작업의 세션 기간](../administration/settings/account_and_limit_settings.md#customize-session-duration-for-git-operations-when-2fa-is-enabled)에 영향을 미칩니다.

Git over SSH 작업에 대해 2FA를 강제 적용할 수 있습니다. 그러나 대신 `ED25519_SK` 또는 `ECDSA_SK` SSH 키를 사용해야 합니다. 자세한 내용은 [지원되는 SSH 키 유형](../user/ssh.md#supported-ssh-key-types)을(를) 참조하세요. 2FA는 Git 작업에만 강제 적용되며 `personal_access_token`와 같은 GitLab Shell의 내부 명령은 제외됩니다.

일회성 비밀번호(OTP) 인증을 수행하려면 다음을 실행합니다:

```shell
ssh git@<hostname> 2fa_verify
```

다음 중 하나로 인증합니다:

- 올바른 OTP를 입력합니다.
- [FortiAuthenticator가 활성화](../user/profile/account/two_factor_authentication.md#add-a-fortiauthenticator-authenticator)된 경우 기기 푸시 알림에 응답합니다.

성공적인 인증 후 관련 SSH 키를 사용하여 15분(기본값) 동안 Git over SSH 작업을 수행할 수 있습니다.

### 보안 제한 {#security-limitation}

2FA는 개인 SSH 키가 손상된 사용자를 보호하지 않습니다.

OTP가 인증된 후 누구든지 구성된 [세션 기간](../administration/settings/account_and_limit_settings.md#customize-session-duration-for-git-operations-when-2fa-is-enabled) 동안 해당 개인 SSH 키로 Git over SSH를 실행할 수 있습니다.
