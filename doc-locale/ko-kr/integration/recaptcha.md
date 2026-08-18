---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: reCAPTCHA
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab은 [reCAPTCHA](https://www.google.com/recaptcha/about/)를 사용하여 스팸과 악용으로부터 보호합니다. GitLab은 새 사용자 계정 페이지에 CAPTCHA 양식을 표시하여 실제 사용자(봇이 아님)가 계정을 생성하려고 시도하는 것을 확인합니다.

## 구성 {#configuration}

reCAPTCHA를 사용하려면 먼저 사이트 및 개인 키를 생성합니다.

1. [Google reCAPTCHA 페이지](https://www.google.com/recaptcha/admin)로 이동합니다.
1. reCAPTCHA v2 키를 얻으려면 양식을 작성하고 **제출**을 선택합니다.
1. 관리자로서 GitLab 서버에 로그인합니다.
1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **Reporting**을 선택합니다.
1. **Spam and Anti-bot Protection**을 펼칩니다.
1. reCAPTCHA 필드에 이전 단계에서 얻은 키를 입력합니다.
1. **reCAPCHA 활성화** 체크박스를 선택합니다.
1. 비밀번호를 통한 로그인에 reCAPTCHA를 활성화하려면 **Enable reCAPTCHA for login** 체크박스를 선택합니다.
1. **변경 사항 저장**을 선택합니다.
1. 스팸 검사를 우회하고 응답이 `recaptcha_html`을 반환하도록 트리거하려면:
   1. `app/services/spam/spam_verdict_service.rb`을 엽니다.
   1. `#execute` 메서드의 첫 번째 줄을 `return CONDITIONAL_ALLOW`로 변경합니다.

> [!note]
> 공개 프로젝트에서 작업 가능한 항목을 보고 있는지 확인합니다. 이슈로 작업하는 경우 이슈가 공개입니다.

## HTTP 헤더를 사용하여 사용자 로그인을 위해 reCAPTCHA 활성화 {#enable-recaptcha-for-user-logins-using-the-http-header}

비밀번호를 통한 사용자 로그인에 대해 reCAPTCHA를 활성화할 수 있습니다. [사용자 인터페이스](#configuration)에서 또는 `X-GitLab-Show-Login-Captcha` HTTP 헤더를 설정하여 활성화할 수 있습니다. 예를 들어 NGINX에서는 `proxy_set_header` 구성 변수를 통해 이를 수행할 수 있습니다:

```nginx
proxy_set_header X-GitLab-Show-Login-Captcha 1;
```

Linux 패키지 인스턴스의 경우 `/etc/gitlab/gitlab.rb`에서 구성합니다:

```ruby
nginx['proxy_set_headers'] = { 'X-GitLab-Show-Login-Captcha' => '1' }
```
