---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 계정 이메일 인증
description: 이메일 인증으로 사용자 신원을 확인합니다.
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.1에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/519123)합니다. `require_email_verification` 기능 플래그가 제거되었습니다.

{{< /history >}}

계정 이메일 인증은 GitLab 계정 보안에 추가 보호 계층을 제공합니다. 이메일 인증은 다음과 같은 상황에서 필요합니다:

- 여러 번의 실패한 로그인 시도로 인해 계정이 [잠겨 있습니다](unlock_user.md).
- 이메일 기반 일회용 비밀번호(OTP)가 계정에 [활성화되어 있습니다](../user/profile/account/two_factor_authentication.md#enable-email-otp).
- 새로운 IP 주소 또는 신뢰할 수 없는 IP 주소에서 로그인합니다.

> [!note]
> GitLab Self-Managed 및 GitLab Dedicated에서는 이 기능이 기본적으로 비활성화되어 있습니다. [application settings API](../api/settings.md)를 사용하여 `require_email_verification_on_account_locked` 속성을 활성화합니다.

<i class="fa-youtube-play" aria-hidden="true"></i> 데모를 보려면 [Require email verification - demo](https://www.youtube.com/watch?v=wU6BVEGB3Y0)를 참조하세요.

이메일 인증을 완료하려면 계정에 로그인하고 기본 이메일 주소로 발송된 6자리 인증 코드를 입력합니다. 기본 이메일 주소에 액세스할 수 없으면 대신 보조 이메일 주소 중 하나로 인증 코드를 보낼 수 있습니다.

인증 코드는 60분 후 만료됩니다.

GitLab.com에서 인증 이메일을 받지 못한 경우, 지원 팀에 연락하기 전에 **Resend Code**를 선택합니다.
