---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Switchboard 사용자를 관리하고 SMTP 이메일 서비스 설정을 포함한 알림 기본 설정을 구성합니다.
title: GitLab Dedicated 사용자 및 알림
---

{{< details >}}

- 계층:  Ultimate
- 제공:  GitLab Dedicated

{{< /details >}}

Switchboard에 액세스할 수 있는 사용자를 관리하고 GitLab Dedicated 인스턴스에 대한 알림을 구성합니다.

Switchboard 사용자는 GitLab Dedicated 인스턴스의 사용자와 별도입니다.

Switchboard는 GitLab Dedicated 인스턴스와 별도의 자체 인증 시스템을 가지고 있습니다. GitLab Dedicated 인스턴스 사용자에 대한 인증 구성에 대한 정보는 [GitLab Dedicated 인증](authentication/_index.md)을 참조하세요.

## Switchboard 사용자 추가 {#add-switchboard-users}

관리자는 GitLab Dedicated 인스턴스를 관리하고 보기 위해 두 가지 유형의 Switchboard 사용자를 추가할 수 있습니다:

- **Read only**:  사용자는 인스턴스 데이터만 볼 수 있습니다.
- **운영자**:  사용자는 인스턴스 구성을 편집하고 사용자를 관리할 수 있습니다.

GitLab Dedicated 인스턴스를 위해 Switchboard에 새 사용자를 추가하려면:

1. [Switchboard](https://console.gitlab-dedicated.com/)에 로그인합니다.
1. 페이지 상단에서 **사용자**를 선택합니다.
1. **새 사용자**를 선택합니다.
1. **이메일**을 입력하고 사용자의 **역할**을 선택합니다.
1. **생성**을 선택합니다.

Switchboard를 사용하기 위한 초대가 사용자에게 전송됩니다.

## 비밀번호 재설정 {#reset-your-password}

Switchboard 비밀번호를 재설정하려면:

1. Switchboard 로그인 페이지에서 이메일 주소를 입력한 후 **계속**을 선택합니다.
1. **비밀번호를 잊어버리셨나요?**를 선택합니다.
1. **Send verification code**을 선택합니다.
1. 이메일에서 확인 코드를 확인합니다.
1. 확인 코드를 입력한 후 **계속**을 선택합니다.
1. 새 비밀번호를 입력하고 확인합니다.
1. **비밀번호 저장**을 선택합니다.

비밀번호를 재설정한 후 자동으로 Switchboard에 로그인됩니다. 계정에 다중 인증(MFA)이 설정된 경우 MFA 확인 코드를 입력하도록 표시됩니다.

## 다중 인증 재설정 {#reset-multi-factor-authentication}

Switchboard에 대한 MFA를 재설정하려면 [지원 티켓을 제출](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)하세요. 지원 팀에서 계정에 대한 액세스를 복구하는 데 도움을 드립니다.

## 알림 {#notifications}

GitLab은 Switchboard를 통해 인스턴스 장애, 유지 관리, 성능 이슈 및 보안 업데이트에 대한 알림을 보냅니다.

알림은 다음으로 전송됩니다:

- Switchboard 사용자:  Switchboard에 액세스할 수 있는 사용자입니다. 이들은 알림 설정에 따라 알림을 받습니다.
- 운영 연락처:  운영 문제에 대한 주요 통신 지점으로 지정된 개인 또는 그룹입니다. 이들은 알림 설정에 관계없이 중요한 인스턴스 이벤트 및 서비스 업데이트에 대한 알림을 받습니다.

운영 연락처는 수신자가 다음의 경우에도 알림을 받습니다:

- Switchboard 사용자가 아닙니다.
- Switchboard에 로그인하지 않았습니다.
- 알림을 해제했습니다.

### 운영 연락처의 이메일 주소 관리 {#manage-email-addresses-for-operational-contacts}

여러 이메일 주소 또는 배포 목록을 운영 연락처로 추가합니다.

운영 연락처의 이메일 주소를 관리하려면:

1. [Switchboard](https://console.gitlab-dedicated.com/)에 로그인합니다.
1. 페이지 맨 위에서 **구성**을 선택합니다.
1. **Contact information**를 확장합니다.
1. **Operational email addresses** 아래:
   - 새 주소를 추가하려면:
     1. **이메일 주소 추가**를 선택합니다.
     1. 이메일 주소를 입력합니다.
     1. **저장**을 선택합니다.
   - 기존 주소를 편집하려면:
     1. 주소 옆의 연필 아이콘({{< icon name="pencil" >}})을 선택합니다.
     1. 이메일 주소를 편집합니다.
     1. **저장**을 선택합니다.
   - 주소를 삭제하려면:
     1. 주소 옆의 휴지통 아이콘({{< icon name="remove" >}})을 선택합니다.
     1. 확인 대화상자에서 **삭제**를 선택합니다.

### 알림 설정 관리 {#manage-notification-settings}

Switchboard 사용자는 개인 알림 설정을 제어할 수 있습니다.

알림을 받으려면 먼저 다음을 수행해야 합니다:

- 초대를 받고 Switchboard에 로그인합니다.
- 비밀번호 및 2단계 인증(2FA)을 설정합니다.

개인 알림을 켜거나 끄려면:

1. 사용자 이름 옆의 드롭다운 목록을 선택합니다.
1. **Toggle email notifications off** 또는 **Toggle email notifications on**를 선택합니다.

## SMTP 이메일 서비스 {#smtp-email-service}

GitLab Dedicated 인스턴스에 대해 [SMTP](../../../subscriptions/gitlab_dedicated/_index.md#email-service) 이메일 서비스를 구성할 수 있습니다.

SMTP 이메일 서비스를 구성하려면 SMTP 서버의 자격 증명 및 설정과 함께 [지원 티켓을 제출](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)하세요.
