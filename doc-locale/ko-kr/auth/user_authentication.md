---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 사용자 인증
description: "비밀번호, 2단계 인증, SSH 키, 액세스 토큰, 자격 증명 인벤토리."
---

GitLab은 사용자가 자신의 계정에 액세스하고 리포지토리와 상호 작용하는 방식을 보호하기 위해 여러 인증 방법을 제공합니다. 웹 기반 액세스를 위해 선택적 2단계 인증이 포함된 비밀번호를 사용하고, Git 작업을 위해 SSH 키를 사용하며, API 상호 작용 및 자동화를 위해 다양한 유형의 액세스 토큰을 사용합니다.

GitLab Self-Managed 및 GitLab Dedicated에서 관리자는 인증 작동 방식을 구성하고, 자격 증명 사용을 모니터링하며, 인스턴스를 보호하기 위한 보안 정책을 구현할 수 있습니다. 사용자는 자신의 인증 방식을 관리하고, 활성 세션을 검토하며, 2단계 인증과 같은 추가 보안 조치를 구성할 수 있습니다.

{{< cards >}}

- [사용자 비밀번호](../user/profile/user_passwords.md)
- [2단계 인증](../user/profile/account/two_factor_authentication.md)
- [자격 증명 인벤토리](../administration/credentials_inventory.md)
- [SSH 키](../user/ssh.md)
- [액세스 토큰](../security/tokens/_index.md)
- [스마트 카드 인증](../administration/auth/smartcard.md)
- [계정 이메일 확인](../security/email_verification.md)

{{< /cards >}}
