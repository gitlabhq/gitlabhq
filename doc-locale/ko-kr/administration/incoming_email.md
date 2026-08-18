---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
title: 수신 이메일
description: 수신 이메일을 구성합니다.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

GitLab은 수신 이메일 메시지를 받는 것에 기반한 여러 기능을 제공합니다:

- [이메일로 답글](reply_by_email.md): GitLab 사용자가 알림 이메일에 답글을 보내 이슈 및 머지 리퀘스트에 댓글을 달 수 있습니다.
- [이메일로 새 이슈 생성](../user/project/issues/create_issues.md#by-sending-an-email): GitLab 사용자가 사용자 지정 이메일 주소로 이메일을 전송하여 새 이슈를 생성할 수 있습니다.
- [이메일로 새 머지 리퀘스트 생성](../user/project/merge_requests/creating_merge_requests.md#by-sending-an-email): GitLab 사용자가 사용자 지정 이메일 주소로 이메일을 전송하여 새 머지 리퀘스트를 생성할 수 있습니다.
- [Service Desk](../user/project/service_desk/_index.md): GitLab을 통해 고객에게 이메일 지원을 제공합니다.

## 요구 사항 {#requirements}

GitLab 인스턴스를 위해 의도된 **only** 수신하는 이메일 주소를 사용합니다. GitLab용이 아닌 수신 이메일 메시지는 거부 알림을 받습니다.

수신 이메일 메시지를 처리하려면 [IMAP](https://en.wikipedia.org/wiki/Internet_Message_Access_Protocol)를 사용하는 이메일 계정이 필요합니다. GitLab에는 다음 세 가지 전략 중 하나가 필요합니다:

- 이메일 서브 주소 지정 (권장)
- 캐치올 메일박스
- 전용 이메일 주소 (이메일로 답글만 지원)

각 옵션을 차근차근 살펴보겠습니다.

### 이메일 서브 주소 지정 {#email-sub-addressing}

[서브 주소 지정](https://en.wikipedia.org/wiki/Email_address#Sub-addressing)은 `user+arbitrary_tag@example.com`로 전송된 모든 이메일이 `user@example.com` 메일박스에서 끝나는 메일 서버 기능입니다. Gmail, Google Apps, Yahoo! Mail, Outlook.com, iCloud 및 온프레미스에서 실행할 수 있는 [Postfix 메일 서버](reply_by_email_postfix_setup.md)와 같은 공급자가 지원합니다. Microsoft Exchange Server는 [서브 주소 지정을 지원하지 않으며](#microsoft-exchange-server) , Microsoft Office 365는 [기본적으로 서브 주소 지정을 지원하지 않습니다](#microsoft-office-365).

> [!note]
> 이메일 서브 주소 지정을 지원하는 공급자 또는 서버가 있으면 이를 사용해야 합니다. 전용 이메일 주소는 이메일로 답글 기능만 지원합니다. 캐치올 메일박스는 서브 주소 지정과 동일한 기능을 지원하지만, 하나의 이메일 주소만 사용되므로 서브 주소 지정이 여전히 선호되며, 캐치올은 GitLab 외의 다른 목적으로 사용 가능합니다.

### 캐치올 메일박스 {#catch-all-mailbox}

도메인의 [캐치올 메일박스](https://en.wikipedia.org/wiki/Catch-all)는 메일 서버에 존재하는 주소와 일치하지 않는 도메인에 주소가 지정된 모든 이메일 메시지를 수신합니다.

캐치올 메일박스는 이메일 서브 주소 지정과 동일한 기능을 지원하지만, 이메일 서브 주소 지정을 계속 권장하므로 캐치올 메일박스를 다른 목적으로 예약할 수 있습니다.

### 전용 이메일 주소 {#dedicated-email-address}

이 솔루션을 설정하려면 GitLab 알림에 대한 사용자의 답글을 수신하기 위해 전용 이메일 주소를 생성해야 합니다. 그러나 이 방법은 답글만 지원하며 수신 이메일의 다른 기능은 지원하지 않습니다.

## 허용된 헤더 {#accepted-headers}

{{< history >}}

- `Cc` 헤더 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/348572) GitLab 16.5.
- `X-Original-To` 헤더 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149874) GitLab 17.0.
- `X-Forwarded-To` 헤더 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/168716) GitLab 17.6.
- `X-Delivered-To` 헤더 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/170221) GitLab 17.6.

{{< /history >}}

이메일은 다음 헤더 중 하나에 구성된 이메일 주소가 있을 때 올바르게 처리됩니다 (확인되는 순서로 정렬):

- `To`
- `Delivered-To`
- `X-Delivered-To`
- `Envelope-To` 또는 `X-Envelope-To`
- `Received`
- `X-Original-To`
- `X-Forwarded-To`
- `Cc`

`References` 헤더도 허용되지만, 기존 토론 스레드와 이메일 응답을 연결하는 데 특별히 사용됩니다. 이메일로 이슈를 생성하는 데 사용되지 않습니다.

GitLab 14.6 이상에서 [Service Desk](../user/project/service_desk/_index.md)도 허용된 헤더를 확인합니다.

일반적으로 `To` 필드는 주요 수신자의 이메일 주소를 포함합니다. 그러나 다음과 같은 경우 구성된 GitLab 이메일 주소가 포함되지 않을 수 있습니다:

- 주소가 `BCC` 필드에 있습니다.
- 이메일이 전달되었습니다.

`Received` 헤더는 여러 이메일 주소를 포함할 수 있습니다. 이들은 나타나는 순서대로 확인됩니다. 첫 번째 일치 항목이 사용됩니다.

## 거부된 헤더 {#rejected-headers}

자동 이메일 시스템으로부터의 원치 않는 이슈 생성을 방지하기 위해 GitLab은 다음 헤더를 포함하는 모든 수신 이메일을 무시합니다:

- `Auto-Submitted` `no` 이외의 값으로
- `X-Autoreply` `yes` 값으로

## 설정 {#set-it-up}

Gmail/Google Workspace에 수신 이메일을 사용하려면 [IMAP 액세스 활성화](https://support.google.com/mail/answer/7126229) 및 [덜 안전한 앱이 계정에 액세스하도록 허용](https://support.google.com/accounts/answer/6010255) 또는 [2단계 인증 활성화](https://support.google.com/accounts/answer/185839) 및 [앱 비밀번호](https://support.google.com/mail/answer/185833)를 사용해야 합니다.

Office 365를 사용하려고 하고 2단계 인증이 활성화되어 있으면 메일박스의 일반 비밀번호 대신 [앱 비밀번호](https://support.microsoft.com/en-us/account-billing/app-passwords-for-a-work-or-school-account-d6dc8c6d-4bf7-4851-ad95-6d07799387e9)를 사용해야 합니다.

Ubuntu에서 IMAP 액세스를 사용하여 기본 Postfix 메일 서버를 설정하려면 [Postfix 설치 설명서](reply_by_email_postfix_setup.md)를 따르세요.

### 보안 문제 {#security-concerns}

> [!warning]
> 수신 이메일에 사용되는 도메인을 선택할 때 주의하세요.

예를 들어 최상위 회사 도메인이 `hooli.com`이라고 가정합니다. 회사의 모든 직원은 Google Workspace를 통해 해당 도메인의 이메일 주소를 가지며, 회사의 전용 Slack 인스턴스는 가입하기 위해 유효한 `@hooli.com` 이메일 주소가 필요합니다.

`hooli.com`에서 공개 GitLab 인스턴스를 호스팅하고 수신 이메일 도메인을 `hooli.com`로 설정하면, 공격자는 Slack에 가입할 때 프로젝트의 고유 주소를 이메일로 사용하여 [새 머지 리퀘스트 생성](../user/project/merge_requests/creating_merge_requests.md#by-sending-an-email) 기능이나 이메일로 새 이슈 생성 기능을 악용할 수 있습니다. 그러면 확인 이메일이 전송되어 공격자가 소유한 프로젝트에 새 이슈나 머지 리퀘스트가 생성되며, 이를 통해 확인 링크를 선택하고 회사의 전용 Slack 인스턴스에서 계정을 검증할 수 있습니다.

`incoming.hooli.com`과 같은 서브도메인에서 수신 이메일을 받고 `*.hooli.com.`과 같은 이메일 도메인에 대한 액세스만을 기반으로 인증하는 서비스를 사용하지 않도록 보장할 것을 권장합니다. 또는 `hooli-gitlab.com`과 같은 GitLab 이메일 통신용 전용 도메인을 사용합니다.

이 악용의 실제 예제를 보려면 GitLab 이슈 [\#30366](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/30366)를 참조하세요.

> [!warning]
> 스팸을 줄이도록 구성된 메일 서버를 사용합니다. 예를 들어, 기본 구성에서 실행 중인 Postfix 메일 서버는 악용을 초래할 수 있습니다. 구성된 메일박스에서 수신된 모든 메시지가 처리되고 GitLab 인스턴스를 위해 의도되지 않은 메시지는 거부 알림을 받습니다. 발신자 주소가 위조된 경우, 거부 알림이 위조된 `FROM` 주소로 전달되어 메일 서버의 IP 또는 도메인이 차단 목록에 나타날 수 있습니다.

사용자는 먼저 자신을 인증하기 위해 2단계 인증(2FA)을 사용할 필요 없이 수신 이메일 기능을 사용할 수 있습니다. 이는 인스턴스에 [2단계 인증 적용](../security/two_factor_authentication.md)된 경우에도 적용됩니다.

### Linux 패키지 설치 {#linux-package-installations}

1. `incoming_email` 섹션을 `/etc/gitlab/gitlab.rb`에서 찾아 기능을 활성화하고 특정 IMAP 서버 및 이메일 계정에 대한 세부 정보를 입력합니다 (아래 [예제](#configuration-examples) 참조).

1. 변경 사항을 적용하려면 GitLab을 다시 구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure

   # Needed when enabling or disabling for the first time but not for password changes.
   # See https://gitlab.com/gitlab-org/gitlab-foss/-/issues/23560#note_61966788
   sudo gitlab-ctl restart
   ```

1. 모든 것이 올바르게 구성되었는지 확인합니다:

   ```shell
   sudo gitlab-rake gitlab:incoming_email:check
   ```

이메일로 답글이 이제 작동해야 합니다.

### 자체 컴파일된 설치 {#self-compiled-installations}

1. GitLab 설치 디렉토리로 이동합니다:

   ```shell
   cd /home/git/gitlab
   ```

1. `gitlab-mail_room` gem을 수동으로 설치합니다:

   ```shell
   gem install gitlab-mail_room
   ```

   > [!note]
   > 이 단계는 스레드 교착 상태를 방지하고 최신 MailRoom 기능을 지원하는 데 필요합니다.

1. `incoming_email` 섹션을 `config/gitlab.yml`에서 찾아 기능을 활성화하고 특정 IMAP 서버 및 이메일 계정에 대한 세부 정보를 입력합니다 (아래 [예제](#configuration-examples) 참조).

systemd 단위를 사용하여 GitLab을 관리하는 경우:

1. `gitlab-mailroom.service`을 `gitlab.target`의 종속성으로 추가합니다:

   ```shell
   sudo systemctl edit gitlab.target
   ```

   열리는 편집기에서 다음을 추가하고 파일을 저장합니다:

   ```plaintext
   [Unit]
   Wants=gitlab-mailroom.service
   ```

1. 같은 머신에서 Redis 및 PostgreSQL을 실행하는 경우 Redis에 대한 종속성을 추가해야 합니다. 실행합니다:

   ```shell
   sudo systemctl edit gitlab-mailroom.service
   ```

   열리는 편집기에서 다음을 추가하고 파일을 저장합니다:

   ```plaintext
   [Unit]
   Wants=redis-server.service
   After=redis-server.service
   ```

1. `gitlab-mailroom.service`을 시작합니다:

   ```shell
   sudo systemctl start gitlab-mailroom.service
   ```

1. 모든 것이 올바르게 구성되었는지 확인합니다:

   ```shell
   sudo -u git -H bundle exec rake gitlab:incoming_email:check RAILS_ENV=production
   ```

SysV init 스크립트를 사용하여 GitLab을 관리하는 경우:

1. `mail_room`을 `/etc/default/gitlab`에서 init 스크립트에서 활성화합니다:

   ```shell
   sudo mkdir -p /etc/default
   echo 'mail_room_enabled=true' | sudo tee -a /etc/default/gitlab
   ```

1. GitLab을 다시 시작합니다:

   ```shell
   sudo service gitlab restart
   ```

1. 모든 것이 올바르게 구성되었는지 확인합니다:

   ```shell
   sudo -u git -H bundle exec rake gitlab:incoming_email:check RAILS_ENV=production
   ```

이메일로 답글이 이제 작동해야 합니다.

### 구성 예제 {#configuration-examples}

#### Postfix {#postfix}

Postfix 메일 서버의 예제 구성입니다. 메일박스 `incoming@gitlab.example.com`을 가정합니다.

Linux 패키지 설치의 예제:

```ruby
gitlab_rails['incoming_email_enabled'] = true

# The email address including the %{key} placeholder that will be replaced to reference the
# item being replied to. This %{key} should be included in its entirety within the email
# address and not replaced by another value.
# For example: emailaddress+%{key}@gitlab.example.com.
# The placeholder must appear in the "user" part of the address (before the `@`).
gitlab_rails['incoming_email_address'] = "incoming+%{key}@gitlab.example.com"

# Email account username
# With third party providers, this is usually the full email address.
# With self-hosted email servers, this is usually the user part of the email address.
gitlab_rails['incoming_email_email'] = "incoming"
# Email account password
gitlab_rails['incoming_email_password'] = "[REDACTED]"

# IMAP server host
gitlab_rails['incoming_email_host'] = "gitlab.example.com"
# IMAP server port
gitlab_rails['incoming_email_port'] = 143
# Whether the IMAP server uses SSL
gitlab_rails['incoming_email_ssl'] = false
# Whether the IMAP server uses StartTLS
gitlab_rails['incoming_email_start_tls'] = false

# The mailbox where incoming mail will end up. Usually "inbox".
gitlab_rails['incoming_email_mailbox_name'] = "inbox"
# The IDLE command timeout.
gitlab_rails['incoming_email_idle_timeout'] = 60

# If you are using Microsoft Graph instead of IMAP, set this to false to retain
# messages in the inbox because deleted messages are auto-expunged after some time.
gitlab_rails['incoming_email_delete_after_delivery'] = true

# Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
# Only applies to IMAP. Microsoft Graph will auto-expunge any deleted messages.
gitlab_rails['incoming_email_expunge_deleted'] = true
```

자체 컴파일된 설치의 예제:

```yaml
incoming_email:
    enabled: true

    # The email address including the %{key} placeholder that will be replaced to reference the
    # item being replied to. This %{key} should be included in its entirety within the email
    # address and not replaced by another value.
    # For example: emailaddress+%{key}@gitlab.example.com.
    # The placeholder must appear in the "user" part of the address (before the `@`).
    address: "incoming+%{key}@gitlab.example.com"

    # Email account username
    # With third party providers, this is usually the full email address.
    # With self-hosted email servers, this is usually the user part of the email address.
    user: "incoming"
    # Email account password
    password: "[REDACTED]"

    # IMAP server host
    host: "gitlab.example.com"
    # IMAP server port
    port: 143
    # Whether the IMAP server uses SSL
    ssl: false
    # Whether the IMAP server uses StartTLS
    start_tls: false

    # The mailbox where incoming mail will end up. Usually "inbox".
    mailbox: "inbox"
    # The IDLE command timeout.
    idle_timeout: 60

    # If you are using Microsoft Graph instead of IMAP, set this to false to retain
    # messages in the inbox because deleted messages are auto-expunged after some time.
    delete_after_delivery: true

    # Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
    # Only applies to IMAP. Microsoft Graph will auto-expunge any deleted messages.
    expunge_deleted: true
```

#### Gmail {#gmail}

Gmail/Google Workspace의 예제 구성입니다. 메일박스 `gitlab-incoming@gmail.com`을 가정합니다.

> [!note]
> `incoming_email_email`은 Gmail 별칭 계정이 될 수 없습니다.

Linux 패키지 설치의 예제:

```ruby
gitlab_rails['incoming_email_enabled'] = true

# The email address including the %{key} placeholder that will be replaced to reference the
# item being replied to. This %{key} should be included in its entirety within the email
# address and not replaced by another value.
# For example: emailaddress+%{key}@gmail.com.
# The placeholder must appear in the "user" part of the address (before the `@`).
gitlab_rails['incoming_email_address'] = "gitlab-incoming+%{key}@gmail.com"

# Email account username
# With third party providers, this is usually the full email address.
# With self-hosted email servers, this is usually the user part of the email address.
gitlab_rails['incoming_email_email'] = "gitlab-incoming@gmail.com"
# Email account password
gitlab_rails['incoming_email_password'] = "[REDACTED]"

# IMAP server host
gitlab_rails['incoming_email_host'] = "imap.gmail.com"
# IMAP server port
gitlab_rails['incoming_email_port'] = 993
# Whether the IMAP server uses SSL
gitlab_rails['incoming_email_ssl'] = true
# Whether the IMAP server uses StartTLS
gitlab_rails['incoming_email_start_tls'] = false

# The mailbox where incoming mail will end up. Usually "inbox".
gitlab_rails['incoming_email_mailbox_name'] = "inbox"
# The IDLE command timeout.
gitlab_rails['incoming_email_idle_timeout'] = 60

# If you are using Microsoft Graph instead of IMAP, set this to false if you want to retain
# messages in the inbox because deleted messages are auto-expunged after some time.
gitlab_rails['incoming_email_delete_after_delivery'] = true

# Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
# Only applies to IMAP. Microsoft Graph will auto-expunge any deleted messages.
gitlab_rails['incoming_email_expunge_deleted'] = true
```

자체 컴파일된 설치의 예제:

```yaml
incoming_email:
    enabled: true

    # The email address including the %{key} placeholder that will be replaced to reference the
    # item being replied to. This %{key} should be included in its entirety within the email
    # address and not replaced by another value.
    # For example: emailaddress+%{key}@gmail.com.
    # The placeholder must appear in the "user" part of the address (before the `@`).
    address: "gitlab-incoming+%{key}@gmail.com"

    # Email account username
    # With third party providers, this is usually the full email address.
    # With self-hosted email servers, this is usually the user part of the email address.
    user: "gitlab-incoming@gmail.com"
    # Email account password
    password: "[REDACTED]"

    # IMAP server host
    host: "imap.gmail.com"
    # IMAP server port
    port: 993
    # Whether the IMAP server uses SSL
    ssl: true
    # Whether the IMAP server uses StartTLS
    start_tls: false

    # The mailbox where incoming mail will end up. Usually "inbox".
    mailbox: "inbox"
    # The IDLE command timeout.
    idle_timeout: 60

    # If you are using Microsoft Graph instead of IMAP, set this to falseto retain
    # messages in the inbox because deleted messages are auto-expunged after some time.
    delete_after_delivery: true

    # Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
    # Only applies to IMAP. Microsoft Graph will auto-expunge any deleted messages.
    expunge_deleted: true
```

#### Microsoft Exchange Server {#microsoft-exchange-server}

IMAP을 사용한 Microsoft Exchange Server의 예제 구성입니다. Exchange는 서브 주소 지정을 지원하지 않으므로 두 가지 옵션만 존재합니다:

- [캐치올 메일박스](#catch-all-mailbox) (Exchange 전용 권장)
- [전용 이메일 주소](#dedicated-email-address) (이메일로 답글만 지원)

##### 캐치올 메일박스 {#catch-all-mailbox-1}

캐치올 메일박스 `incoming@exchange.example.com`을 가정합니다.

Linux 패키지 설치의 예제:

```ruby
gitlab_rails['incoming_email_enabled'] = true

# The email address including the %{key} placeholder that will be replaced to reference the
# item being replied to. This %{key} should be included in its entirety within the email
# address and not replaced by another value.
# For example: emailaddress-%{key}@exchange.example.com.
# The placeholder must appear in the "user" part of the address (before the `@`).
# Exchange does not support sub-addressing, so a catch-all mailbox must be used.
gitlab_rails['incoming_email_address'] = "incoming-%{key}@exchange.example.com"

# Email account username
# Typically this is the userPrincipalName (UPN)
gitlab_rails['incoming_email_email'] = "incoming@ad-domain.example.com"
# Email account password
gitlab_rails['incoming_email_password'] = "[REDACTED]"

# IMAP server host
gitlab_rails['incoming_email_host'] = "exchange.example.com"
# IMAP server port
gitlab_rails['incoming_email_port'] = 993
# Whether the IMAP server uses SSL
gitlab_rails['incoming_email_ssl'] = true

# Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
# Only applies to IMAP. Microsoft Graph will auto-expunge any deleted messages.
gitlab_rails['incoming_email_expunge_deleted'] = true
```

자체 컴파일된 설치의 예제:

```yaml
incoming_email:
    enabled: true

    # The email address including the %{key} placeholder that will be replaced to reference the
    # item being replied to. This %{key} should be included in its entirety within the email
    # address and not replaced by another value.
    # For example: emailaddress-%{key}@exchange.example.com.
    # The placeholder must appear in the "user" part of the address (before the `@`).
    # Exchange does not support sub-addressing, so a catch-all mailbox must be used.
    address: "incoming-%{key}@exchange.example.com"

    # Email account username
    # Typically this is the userPrincipalName (UPN)
    user: "incoming@ad-domain.example.com"
    # Email account password
    password: "[REDACTED]"

    # IMAP server host
    host: "exchange.example.com"
    # IMAP server port
    port: 993
    # Whether the IMAP server uses SSL
    ssl: true

    # If you are using Microsoft Graph instead of IMAP, set this to false to retain
    # messages in the inbox because deleted messages are auto-expunged after some time.
    delete_after_delivery: true

    # Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
    expunge_deleted: true
```

##### 전용 이메일 주소 {#dedicated-email-address-1}

> [!note]
> [이메일로 답글](reply_by_email.md)만 지원합니다. [Service Desk](../user/project/service_desk/_index.md)를 지원할 수 없습니다.

전용 이메일 주소 `incoming@exchange.example.com`을 가정합니다.

Linux 패키지 설치의 예제:

```ruby
gitlab_rails['incoming_email_enabled'] = true

# Exchange does not support sub-addressing, and we're not using a catch-all mailbox so %{key} is not used here
gitlab_rails['incoming_email_address'] = "incoming@exchange.example.com"

# Email account username
# Typically this is the userPrincipalName (UPN)
gitlab_rails['incoming_email_email'] = "incoming@ad-domain.example.com"
# Email account password
gitlab_rails['incoming_email_password'] = "[REDACTED]"

# IMAP server host
gitlab_rails['incoming_email_host'] = "exchange.example.com"
# IMAP server port
gitlab_rails['incoming_email_port'] = 993
# Whether the IMAP server uses SSL
gitlab_rails['incoming_email_ssl'] = true

# Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
gitlab_rails['incoming_email_expunge_deleted'] = true
```

자체 컴파일된 설치의 예제:

```yaml
incoming_email:
    enabled: true

    # Exchange does not support sub-addressing,
    # and we're not using a catch-all mailbox so %{key} is not used here
    address: "incoming@exchange.example.com"

    # Email account username
    # Typically this is the userPrincipalName (UPN)
    user: "incoming@ad-domain.example.com"
    # Email account password
    password: "[REDACTED]"

    # IMAP server host
    host: "exchange.example.com"
    # IMAP server port
    port: 993
    # Whether the IMAP server uses SSL
    ssl: true

    # If you are using Microsoft Graph instead of IMAP, set this to false to retain
    # messages in the inbox because deleted messages are auto-expunged after some time.
    delete_after_delivery: true

    # Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
    expunge_deleted: true
```

#### Microsoft Office 365 {#microsoft-office-365}

IMAP을 사용한 Microsoft Office 365의 예제 구성입니다.

##### 서브 주소 지정 메일박스 {#sub-addressing-mailbox}

> [!note]
> 2020년 9월부터 서브 주소 지정 지원이 [Office 365에 추가되었습니다](https://support.microsoft.com/en-us/office/uservoice-pages-430e1a78-e016-472a-a10f-dc2a3df3450a). 이 기능은 기본적으로 활성화되지 않으며 PowerShell을 통해 활성화해야 합니다.

이 PowerShell 명령 시리즈는 Office 365에서 [서브 주소 지정](#email-sub-addressing)을 조직 수준에서 활성화합니다. 이를 통해 조직의 모든 메일박스에서 서브 주소 지정된 메일을 수신할 수 있습니다.

서브 주소 지정을 활성화하려면:

1. `ExchangeOnlineManagement` 모듈을 [PowerShell 갤러리](https://www.powershellgallery.com/packages/ExchangeOnlineManagement/3.7.1)에서 다운로드 및 설치합니다.
1. PowerShell에서 다음 명령을 실행합니다:

   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   Import-Module ExchangeOnlineManagement
   Connect-ExchangeOnline
   Set-OrganizationConfig -DisablePlusAddressInRecipients $false
   Disconnect-ExchangeOnline
   ```

Linux 패키지 설치의 이 예제는 메일박스 `incoming@office365.example.com`을 가정합니다:

```ruby
gitlab_rails['incoming_email_enabled'] = true

# The email address including the %{key} placeholder that will be replaced to reference the
# item being replied to. This %{key} should be included in its entirety within the email
# address and not replaced by another value.
# For example: emailaddress+%{key}@office365.example.com.
# The placeholder must appear in the "user" part of the address (before the `@`).
gitlab_rails['incoming_email_address'] = "incoming+%{key}@office365.example.com"

# Email account username
# Typically this is the userPrincipalName (UPN)
gitlab_rails['incoming_email_email'] = "incoming@office365.example.com"
# Email account password
gitlab_rails['incoming_email_password'] = "[REDACTED]"

# IMAP server host
gitlab_rails['incoming_email_host'] = "outlook.office365.com"
# IMAP server port
gitlab_rails['incoming_email_port'] = 993
# Whether the IMAP server uses SSL
gitlab_rails['incoming_email_ssl'] = true

# Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
gitlab_rails['incoming_email_expunge_deleted'] = true
```

자체 컴파일된 설치의 이 예제는 메일박스 `incoming@office365.example.com`을 가정합니다:

```yaml
incoming_email:
    enabled: true

    # The email address including the %{key} placeholder that will be replaced to reference the
    # item being replied to. This %{key} should be included in its entirety within the email
    # address and not replaced by another value.
    # For example: emailaddress+%{key}@office365.example.com.
    # The placeholder must appear in the "user" part of the address (before the `@`).
    address: "incoming+%{key}@office365.example.comm"

    # Email account username
    # Typically this is the userPrincipalName (UPN)
    user: "incoming@office365.example.comm"
    # Email account password
    password: "[REDACTED]"

    # IMAP server host
    host: "outlook.office365.com"
    # IMAP server port
    port: 993
    # Whether the IMAP server uses SSL
    ssl: true

    # Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
    expunge_deleted: true
```

##### 캐치올 메일박스 {#catch-all-mailbox-2}

Linux 패키지 설치의 이 예제는 캐치올 메일박스 `incoming@office365.example.com`을 가정합니다:

```ruby
gitlab_rails['incoming_email_enabled'] = true

# The email address including the %{key} placeholder that will be replaced to reference the
# item being replied to. This %{key} should be included in its entirety within the email
# address and not replaced by another value.
# For example: emailaddress-%{key}@office365.example.com.
# The placeholder must appear in the "user" part of the address (before the `@`).
gitlab_rails['incoming_email_address'] = "incoming-%{key}@office365.example.com"

# Email account username
# Typically this is the userPrincipalName (UPN)
gitlab_rails['incoming_email_email'] = "incoming@office365.example.com"
# Email account password
gitlab_rails['incoming_email_password'] = "[REDACTED]"

# IMAP server host
gitlab_rails['incoming_email_host'] = "outlook.office365.com"
# IMAP server port
gitlab_rails['incoming_email_port'] = 993
# Whether the IMAP server uses SSL
gitlab_rails['incoming_email_ssl'] = true

# Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
gitlab_rails['incoming_email_expunge_deleted'] = true
```

자체 컴파일된 설치의 이 예제는 캐치올 메일박스 `incoming@office365.example.com`을 가정합니다:

```yaml
incoming_email:
    enabled: true

    # The email address including the %{key} placeholder that will be replaced to reference the
    # item being replied to. This %{key} should be included in its entirety within the email
    # address and not replaced by another value.
    # For example: emailaddress+%{key}@office365.example.com.
    # The placeholder must appear in the "user" part of the address (before the `@`).
    address: "incoming-%{key}@office365.example.com"

    # Email account username
    # Typically this is the userPrincipalName (UPN)
    user: "incoming@ad-domain.example.com"
    # Email account password
    password: "[REDACTED]"

    # IMAP server host
    host: "outlook.office365.com"
    # IMAP server port
    port: 993
    # Whether the IMAP server uses SSL
    ssl: true

    # Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
    expunge_deleted: true
```

##### 전용 이메일 주소 {#dedicated-email-address-2}

> [!note]
> [이메일로 답글](reply_by_email.md)만 지원합니다. [Service Desk](../user/project/service_desk/_index.md)를 지원할 수 없습니다.

Linux 패키지 설치의 이 예제는 전용 이메일 주소 `incoming@office365.example.com`을 가정합니다:

```ruby
gitlab_rails['incoming_email_enabled'] = true

gitlab_rails['incoming_email_address'] = "incoming@office365.example.com"

# Email account username
# Typically this is the userPrincipalName (UPN)
gitlab_rails['incoming_email_email'] = "incoming@office365.example.com"
# Email account password
gitlab_rails['incoming_email_password'] = "[REDACTED]"

# IMAP server host
gitlab_rails['incoming_email_host'] = "outlook.office365.com"
# IMAP server port
gitlab_rails['incoming_email_port'] = 993
# Whether the IMAP server uses SSL
gitlab_rails['incoming_email_ssl'] = true

# Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
gitlab_rails['incoming_email_expunge_deleted'] = true
```

자체 컴파일된 설치의 이 예제는 전용 이메일 주소 `incoming@office365.example.com`을 가정합니다:

```yaml
incoming_email:
    enabled: true

    address: "incoming@office365.example.com"

    # Email account username
    # Typically this is the userPrincipalName (UPN)
    user: "incoming@office365.example.com"
    # Email account password
    password: "[REDACTED]"

    # IMAP server host
    host: "outlook.office365.com"
    # IMAP server port
    port: 993
    # Whether the IMAP server uses SSL
    ssl: true

    # Whether to expunge (permanently remove) messages from the mailbox when they are marked as deleted after delivery
    expunge_deleted: true
```

#### Microsoft Graph {#microsoft-graph}

GitLab은 IMAP 대신 Microsoft Graph API를 사용하여 수신 이메일을 읽을 수 있습니다. [Microsoft는 기본 인증과 함께 IMAP 사용을 중단](https://techcommunity.microsoft.com/blog/exchange/announcing-oauth-2-0-support-for-imap-and-smtp-auth-protocols-in-exchange-online/1330432)하고 있으므로, Microsoft Graph API는 새로운 Microsoft Exchange Online 메일박스에 필요합니다.

GitLab을 Microsoft Graph용으로 구성하려면 `Mail.ReadWrite` 권한이 있는 Azure Active Directory에 OAuth 2.0 애플리케이션을 등록해야 합니다. 자세한 내용은 [MailRoom 단계별 가이드](https://github.com/tpitale/mail_room/#microsoft-graph-configuration) 및 [Microsoft 지침](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app)을 참조하세요.

OAuth 2.0 애플리케이션을 구성할 때 다음을 기록합니다:

- Azure Active Directory의 테넌트 ID
- OAuth 2.0 애플리케이션의 클라이언트 ID
- OAuth 2.0 애플리케이션의 클라이언트 비밀

##### 메일박스 액세스 제한 {#restrict-mailbox-access}

MailRoom이 서비스 계정으로 작동하려면 Azure Active Directory에서 생성하는 애플리케이션에서 `Mail.ReadWrite` 속성을 모든 메일박스의 메일을 읽기/쓰기로 설정해야 합니다.

보안 문제를 완화하기 위해 [Microsoft 설명서](https://learn.microsoft.com/en-us/graph/auth-limit-mailbox-access)에 설명된 대로 모든 계정의 메일박스 액세스를 제한하는 애플리케이션 액세스 정책을 구성할 것을 권장합니다.

Linux 패키지 설치의 이 예제는 다음 메일박스를 사용한다고 가정합니다: `incoming@example.onmicrosoft.com`:

##### Microsoft Graph 구성 {#configure-microsoft-graph}

{{< history >}}

- 대체 Azure 배포는 [도입됨](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/5978) GitLab 14.9.

{{< /history >}}

```ruby
gitlab_rails['incoming_email_enabled'] = true

# The email address including the %{key} placeholder that will be replaced to reference the
# item being replied to. This %{key} should be included in its entirety within the email
# address and not replaced by another value.
# For example: emailaddress+%{key}@example.onmicrosoft.com.
# The placeholder must appear in the "user" part of the address (before the `@`).
gitlab_rails['incoming_email_address'] = "incoming+%{key}@example.onmicrosoft.com"

# Email account username
gitlab_rails['incoming_email_email'] = "incoming@example.onmicrosoft.com"
gitlab_rails['incoming_email_delete_after_delivery'] = false

gitlab_rails['incoming_email_inbox_method'] = 'microsoft_graph'
gitlab_rails['incoming_email_inbox_options'] = {
   'tenant_id': '<YOUR-TENANT-ID>',
   'client_id': '<YOUR-CLIENT-ID>',
   'client_secret': '<YOUR-CLIENT-SECRET>',
   'poll_interval': 60  # Optional
}
```

Microsoft Cloud for US Government 또는 [다른 Azure 배포](https://learn.microsoft.com/en-us/graph/deployments)의 경우 `azure_ad_endpoint` 및 `graph_endpoint` 설정을 구성합니다.

- Microsoft Cloud for US Government의 예제:

```ruby
gitlab_rails['incoming_email_inbox_options'] = {
   'azure_ad_endpoint': 'https://login.microsoftonline.us',
   'graph_endpoint': 'https://graph.microsoft.us',
   'tenant_id': '<YOUR-TENANT-ID>',
   'client_id': '<YOUR-CLIENT-ID>',
   'client_secret': '<YOUR-CLIENT-SECRET>',
   'poll_interval': 60  # Optional
}
```

Microsoft Graph API는 아직 자체 컴파일된 설치에서 지원되지 않습니다. 자세한 내용은 [이슈 326169](https://gitlab.com/gitlab-org/gitlab/-/issues/326169)를 참조하세요.

### 암호화된 자격 증명 사용 {#use-encrypted-credentials}

{{< history >}}

- [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/108279) GitLab 15.9.

{{< /history >}}

구성 파일에 평문으로 저장된 수신 이메일 자격 증명 대신 수신 이메일 자격 증명을 위해 암호화된 파일을 선택적으로 사용할 수 있습니다.

전제 조건:

- 암호화된 자격 증명을 사용하려면 먼저 [암호화된 구성](encrypted_configuration.md)을 활성화해야 합니다.

암호화된 파일에 대해 지원되는 구성 항목은 다음과 같습니다:

- `user`
- `password`

{{< tabs >}}

{{< tab title="Linux 패키지 (Omnibus)" >}}

1. 처음에 `/etc/gitlab/gitlab.rb`의 수신 이메일 구성이 다음과 같이 보였다면:

   ```ruby
   gitlab_rails['incoming_email_email'] = "incoming-email@mail.example.com"
   gitlab_rails['incoming_email_password'] = "examplepassword"
   ```

1. 암호화된 비밀을 편집합니다:

   ```shell
   sudo gitlab-rake gitlab:incoming_email:secret:edit EDITOR=vim
   ```

1. 수신 이메일 비밀의 암호화되지 않은 내용을 입력합니다:

   ```yaml
   user: 'incoming-email@mail.example.com'
   password: 'examplepassword'
   ```

1. `/etc/gitlab/gitlab.rb`을 편집하고 `incoming_email` 설정에서 `email` 및 `password`을 제거합니다.
1. 파일을 저장하고 GitLab을 다시 구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm 차트 (Kubernetes)" >}}

Kubernetes 비밀을 사용하여 수신 이메일 비밀번호를 저장합니다. 자세한 내용은 [Helm IMAP 비밀](https://docs.gitlab.com/charts/installation/secrets/#imap-password-for-incoming-emails)을 참조하세요.

{{< /tab >}}

{{< tab title="Docker" >}}

1. 처음에 `docker-compose.yml`의 수신 이메일 구성이 다음과 같이 보였다면:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       image: 'gitlab/gitlab-ee:latest'
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['incoming_email_email'] = "incoming-email@mail.example.com"
           gitlab_rails['incoming_email_password'] = "examplepassword"
   ```

1. 컨테이너 내부로 이동하고 암호화된 비밀을 편집합니다:

   ```shell
   sudo docker exec -t <container_name> bash
   gitlab-rake gitlab:incoming_email:secret:edit EDITOR=editor
   ```

1. 수신 이메일 비밀의 암호화되지 않은 내용을 입력합니다:

   ```yaml
   user: 'incoming-email@mail.example.com'
   password: 'examplepassword'
   ```

1. `docker-compose.yml`을 편집하고 `incoming_email` 설정에서 `email` 및 `password`을 제거합니다.
1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="자체 컴파일됨 (소스)" >}}

1. 처음에 `/home/git/gitlab/config/gitlab.yml`의 수신 이메일 구성이 다음과 같이 보였다면:

   ```yaml
   production:
     incoming_email:
       user: 'incoming-email@mail.example.com'
       password: 'examplepassword'
   ```

1. 암호화된 비밀을 편집합니다:

   ```shell
   bundle exec rake gitlab:incoming_email:secret:edit EDITOR=vim RAILS_ENVIRONMENT=production
   ```

1. 수신 이메일 비밀의 암호화되지 않은 내용을 입력합니다:

   ```yaml
   user: 'incoming-email@mail.example.com'
   password: 'examplepassword'
   ```

1. `/home/git/gitlab/config/gitlab.yml`을 편집하고 `incoming_email:` 설정에서 `user` 및 `password`을 제거합니다.
1. 파일을 저장하고 GitLab 및 Mailroom을 다시 시작합니다

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

## 문제 해결 {#troubleshooting}

### 이메일 수집이 16.6.0에서 작동하지 않음 {#email-ingestion-doesnt-work-in-1660}

GitLab 16.6에서 회귀로 인해 `mail_room` (이메일 수집)이 시작되지 않습니다. Service Desk 및 기타 이메일로 답글 기능이 작동하지 않습니다. 이 문제는 16.6.1에서 수정되었습니다. 자세한 내용은 [이슈 432257](https://gitlab.com/gitlab-org/gitlab/-/issues/432257)을 참조하세요.

해결 방법은 GitLab 설치에서 다음 명령을 실행하여 영향을 받은 파일을 패치하는 것입니다:

{{< tabs >}}

{{< tab title="Linux 패키지 (Omnibus)" >}}

```shell
curl --output /tmp/mailroom.patch --url "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137279.diff"
patch -p1 -d /opt/gitlab/embedded/service/gitlab-rails < /tmp/mailroom.patch
gitlab-ctl restart mailroom
```

{{< /tab >}}

{{< tab title="Docker" >}}

```shell
curl --output /tmp/mailroom.patch --url "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137279.diff"
cd /opt/gitlab/embedded/service/gitlab-rails
patch -p1 < /tmp/mailroom.patch
gitlab-ctl restart mailroom
```

{{< /tab >}}

{{< /tabs >}}

### 이메일 주소 제한이 있는 공급자에 의해 수신 이메일이 거부됨 {#incoming-emails-are-rejected-by-providers-with-email-address-limit}

일부 이메일 공급자가 이메일 주소의 로컬 부분 (앞의 `@`)에 64자 제한을 부과하기 때문에 GitLab 인스턴스가 수신 이메일을 받지 못할 수 있습니다. 이 제한을 초과하는 주소의 모든 이메일은 거부됩니다.

해결 방법으로 더 짧은 경로를 유지합니다:

- `%{key}` 앞에 구성된 로컬 부분이 `incoming_email_address`에서 가능한 한 짧으며 31자를 초과하지 않는지 확인합니다.
- 지정된 프로젝트를 더 높은 그룹 계층에 배치합니다.
- [그룹](../user/group/manage.md#change-a-groups-path) 및 [프로젝트](../user/project/working_with_projects.md#rename-a-repository)의 이름을 더 짧은 이름으로 바꿉니다.

이 기능을 [이슈 460206](https://gitlab.com/gitlab-org/gitlab/-/issues/460206)에서 추적합니다.
