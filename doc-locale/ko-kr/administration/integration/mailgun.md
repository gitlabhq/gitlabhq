---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
title: Mailgun
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab 인스턴스에서 Mailgun을 사용하여 이메일을 보내고 [Mailgun](https://www.mailgun.com/) 통합이 활성화되고 GitLab에서 구성되면 배송 실패를 추적하기 위한 웹후크를 받을 수 있습니다. 통합을 설정하려면 다음을 수행해야 합니다:

1. [Mailgun 도메인 구성](#configure-your-mailgun-domain).
1. [Mailgun 통합 활성화](#enable-mailgun-integration).

통합을 완료한 후 Mailgun `temporary_failure` 및 `permanent_failure` 웹후크가 GitLab 인스턴스로 전송됩니다.

## Mailgun 도메인 구성 {#configure-your-mailgun-domain}

{{< history >}}

- [더 이상 사용하지 않음](https://gitlab.com/gitlab-org/gitlab/-/issues/359113) GitLab 15.0에서 `/-/members/mailgun/permanent_failures` URL.
- [변경됨](https://gitlab.com/gitlab-org/gitlab/-/issues/359113) GitLab 15.0에서 임시 및 영구 오류를 모두 처리하기 위해 URL.

{{< /history >}}

GitLab에서 Mailgun을 활성화하기 전에 웹후크를 받기 위해 자신의 Mailgun 끝점을 설정합니다.

[Mailgun 웹후크 가이드](https://www.mailgun.com/blog/product/a-guide-to-using-mailguns-webhooks/) 사용:

1. **Event type**을 **Permanent Failure**로 설정하여 웹후크를 추가합니다.
1. 인스턴스의 URL을 입력하고 `/-/mailgun/webhooks` 경로를 포함합니다.

   예를 들어:

   ```plaintext
   https://myinstance.gitlab.com/-/mailgun/webhooks
   ```

1. **Event type**을 **Temporary Failure**로 설정하여 다른 웹후크를 추가합니다.
1. 인스턴스의 URL을 입력하고 동일한 `/-/mailgun/webhooks` 경로를 사용합니다.

## Mailgun 통합 활성화 {#enable-mailgun-integration}

웹후크 끝점에 대해 Mailgun 도메인을 구성한 후 Mailgun 통합을 활성화할 준비가 되었습니다:

1. [운영자](../../user/permissions.md) 사용자로 GitLab에 로그인합니다.
1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **일반**으로 이동하고 **Mailgun** 섹션을 확장합니다.
1. **Enable Mailgun** 확인란을 선택합니다.
1. [Mailgun 설명서](https://documentation.mailgun.com/docs/mailgun/user-manual/get-started/)에 설명된 대로 Mailgun HTTP 웹후크 서명 키를 입력하고 Mailgun 계정의 API 보안(`https://app.mailgun.com/app/account/security/api_keys`) 섹션에 표시된 대로 입력합니다.
1. **변경 사항 저장**을 선택합니다.
