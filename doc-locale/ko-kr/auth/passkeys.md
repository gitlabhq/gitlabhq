---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 패스키
description: 패스키를 사용하는 비밀번호 없는 인증 및 2단계 인증
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.6에 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/206407) 됨 [플래그](../administration/feature_flags/_index.md) `passkeys` 이름. GitLab Self-Managed에서는 기본적으로 비활성화됩니다.
- GitLab 18.9에서 일반적으로 사용 가능합니다. 기능 플래그는 기본적으로 활성화됩니다.
- [GitLab 19.0에서 기능 플래그](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/230536) `passkeys`를 제거했습니다.

{{< /history >}}

패스키는 비밀번호를 사용하지 않고 GitLab 계정에 로그인하는 안전하고 편리한 방법을 제공합니다. 패스키는 피싱 저항형 로그인을 제공하면서 사용자를 약한 비밀번호 취약성 및 자격 증명 위반으로부터 보호합니다.

## 패스키 작동 방식 {#how-passkeys-work}

패스키는 공개 키 암호화를 사용하여 GitLab에 안전하게 인증합니다. 패스키를 생성하면:

- 기기에서 고유한 암호화 키 쌍을 생성합니다.
- 개인 키는 기기에 안전하게 유지되며 공유되지 않습니다.
- GitLab은 공개 키만 저장하며, 이 키는 사용자를 사칭하는 데 사용될 수 없습니다.
- 로그인할 때 기기는 생체 인증 또는 PIN을 사용하여 개인 키를 잠금 해제하고 신원을 증명합니다.

이 방식은 GitLab 서버가 손상되더라도 공격자가 패스키를 사용하여 계정에 액세스할 수 없도록 보장합니다.

### 보안 고려사항 {#security-considerations}

- 백업 인증 방법을 유지하세요: 복구 코드나 다른 2단계 인증 방법과 같이 계정에 액세스할 수 있는 대체 방법을 항상 유지하세요.
- 기기 보안을 유지하세요: 기기가 강력한 PIN, 비밀번호 또는 생체 인식 잠금으로 보호되는지 확인하세요.
- 정기적으로 검토하세요: 등록된 패스키를 정기적으로 검토하고 더 이상 사용하지 않는 기기의 패스키를 제거하세요.
- 공유 기기를 사용하지 마세요: 공유하거나 공용 기기에 패스키를 설정하지 마세요.

## 패스키 보기 {#view-your-passkeys}

패스키 이름, 기기 유형 및 사용 세부 정보를 포함하여 등록된 패스키에 대한 정보를 보려면:

1. 오른쪽 위 모서리에서 아바타를 선택합니다.
1. **프로필 편집**을 선택합니다.
1. 왼쪽 사이드바에서 **액세스** > **비밀번호와 인증**을 선택하세요.
1. **Passkey sign-in** 섹션에서 패스키를 보세요.

## 패스키 추가 {#add-a-passkey}

전제 조건:

- WebAuthn 표준을 지원하는 기기가 있어야 합니다.
  - 데스크톱 브라우저: Chrome, Firefox, Safari 및 Edge
  - 모바일 기기: iOS 16 이상 및 Android 9 이상(생체 인증 또는 기기 PIN이 켜져 있음)
  - 보안 키: FIDO2 또는 WebAuthn을 지원하는 하드웨어 보안 키
- 패스키로 로그인이 [그룹](../user/group/saml_sso/_index.md#disable-password-and-passkey-authentication-for-enterprise-users) 또는 [인스턴스](../administration/settings/sign_in_restrictions.md#password-and-passkey-authentication)에 대해 비활성화되지 않아야 합니다.

> [!note]
> 외부 ID 공급자를 통해 생성된 사용자 계정은 새 GitLab 비밀번호를 생성해야 할 수 있습니다. 자세한 내용은 [외부 인증 계정의 비밀번호](../user/profile/user_passwords.md#passwords-for-externally-authenticated-accounts)를 참조하세요.

패스키를 추가하려면:

1. 오른쪽 위 모서리에서 아바타를 선택합니다.
1. **프로필 편집**을 선택합니다.
1. 왼쪽 사이드바에서 **액세스** > **비밀번호와 인증**을 선택하세요.
1. **Passkey sign-in** 섹션에서 **패스키 추가**를 선택하세요.
1. 기기 또는 브라우저의 지시를 따르세요.
1. 신원을 확인하기 위해 현재 비밀번호를 입력하세요.
1. 패스키의 이름을 입력하세요.
1. **패스키 추가**를 선택하세요.

## 패스키로 로그인 {#sign-in-with-a-passkey}

비밀번호 대신 패스키를 사용하여 GitLab에 로그인하려면:

1. GitLab 로그인 페이지로 이동하세요.

   - GitLab.com에서 `https://gitlab.com/users/sign_in`로 이동하세요.
   - GitLab Self-Managed에서는 인스턴스 도메인을 사용하세요. 예를 들어, `https://gitlab.example.com/users/sign_in`입니다.

1. 추가 로그인 옵션 아래에서 **패스키**를 선택하세요.
1. 지문, 안면 인식 또는 기기 PIN을 사용하여 인증하는 기기의 지시를 따르세요.

## 2단계 인증을 위해 패스키 사용 {#use-a-passkey-for-two-factor-authentication}

계정에 [2단계 인증](../user/profile/account/two_factor_authentication.md) (2FA)을 활성화한 경우 패스키가 추가 및 기본 2FA 옵션으로 사용 가능하게 됩니다.

2FA 방법으로 패스키를 사용하려면:

1. GitLab 로그인 페이지로 이동하세요.

   - GitLab.com에서 `https://gitlab.com/users/sign_in`로 이동하세요.
   - GitLab Self-Managed에서는 인스턴스 도메인을 사용하세요. 예를 들어, `https://gitlab.example.com/users/sign_in`입니다.

1. 사용자 이름과 비밀번호를 입력하세요.
1. 메시지가 표시되면 패스키로 인증하세요.
1. 지문, 안면 인식 또는 기기 PIN을 사용하여 인증하는 기기의 지시를 따르세요.

> [!note]
> 현재 기기에서 패스키를 사용할 수 없으면 대신 백업 2단계 인증 방법을 사용하세요.

## 패스키 삭제 {#delete-a-passkey}

기기를 더 이상 사용하지 않거나 새 패스키로 교체하려는 경우 패스키를 삭제하세요. 유일한 패스키를 삭제하면 GitLab에서 계정에 대한 패스키 로그인도 비활성화됩니다.

패스키를 삭제하려면:

1. 오른쪽 위 모서리에서 아바타를 선택합니다.
1. **프로필 편집**을 선택합니다.
1. 왼쪽 사이드바에서 **액세스** > **비밀번호와 인증**을 선택하세요.
1. **Passkey sign-in** 섹션에서 삭제하려는 패스키를 찾으세요.
1. 패스키 옆에서 **삭제** ({{< icon name="remove" >}})를 선택하세요.
1. 확인 대화상자에서 삭제를 확인하세요.

   - 패스키가 여러 개 있으면 **패스키 삭제**를 선택하세요.
   - 패스키가 하나 있으면 **패스키로 로그인 비활성화**를 선택하세요.

> [!warning]
> 삭제된 패스키는 복구할 수 없습니다. 나중에 기기로 인증하려면 새 패스키를 추가해야 합니다.

## 문제 해결 {#troubleshooting}

### 패스키 추가 문제 {#problems-adding-a-passkey}

패스키를 추가할 수 없으면:

- 기기 및 브라우저가 WebAuthn 및 생체 인증을 지원하는지 확인하세요.
- 브라우저가 최신 버전인지 확인하세요.
- 기기에서 기기 PIN, 지문 또는 안면 인식을 설정했는지 확인하세요.
- 다른 브라우저나 기기를 사용해 보세요.
- 기기가 이미 WebAuthn 2단계 인증 방법으로 등록되어 있는지 확인하세요.
  - 기기가 이미 WebAuthn 2단계 인증 방법으로 등록된 경우:

    1. 2FA 방법에서 WebAuthn 기기를 삭제하세요.
    1. 패스키로 등록하세요.
    1. 2FA를 다시 활성화하려면 백업 2FA 방법(예: 인증기 앱)을 구성하세요. GitLab은 자동으로 패스키를 기본 2단계 인증으로 추가합니다.

### 패스키로 로그인할 수 없음 {#cannot-sign-in-with-passkey}

패스키를 사용하여 로그인할 수 없으면:

- 패스키를 만든 데 사용한 것과 같은 기기를 사용하고 있는지 확인하세요.
- 생체 인증 또는 기기 PIN이 작동하는지 확인하세요.
- 브라우저 캐시 및 쿠키를 지우세요.
- 백업 2단계 인증 방법 또는 비밀번호를 사용하여 로그인한 다음 패스키 설정을 확인하세요.

### 기기 분실 또는 교체 {#lost-or-replaced-device}

기기를 분실하거나 새 기기를 구매한 경우 비밀번호로 로그인하고 새 패스키를 설정하세요.

새 기기에 패스키를 설정하려면:

1. 비밀번호를 사용하여 GitLab에 로그인하세요.
1. 패스키를 2FA 방법으로 사용하면 백업 방법으로 로그인하세요.
1. 계정 설정에서 이전 패스키를 제거하세요.
1. 새 기기에 새 패스키를 설정하세요.

## 관련 항목 {#related-topics}

- [2단계 인증](../user/profile/account/two_factor_authentication.md)
- [사용자 비밀번호](../user/profile/user_passwords.md)
