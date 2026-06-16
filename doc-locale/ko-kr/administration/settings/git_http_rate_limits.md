---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Self-Managed의 Git HTTP 요청에 대한 속도 제한을 구성합니다.
title: Git HTTP의 속도 제한
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.0에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147112).

{{< /history >}}

Git HTTP를 리포지토리에서 사용하면 일반적인 Git 작업으로 인해 많은 Git HTTP 요청이 생성될 수 있습니다. GitLab은 인증되고 인증되지 않은 Git HTTP 요청 모두에 속도 제한을 적용하여 웹 애플리케이션의 보안과 내구성을 개선할 수 있습니다.

> [!note]
> [일반 사용자 및 IP 속도 제한](user_and_ip_rate_limits.md)은 Git HTTP 요청에 적용되지 않습니다.

## 전제 조건 {#prerequisites}

관리자 액세스 권한이 있어야 합니다.

## 인증되지 않은 Git HTTP 속도 제한 구성 {#configure-unauthenticated-git-http-rate-limits}

GitLab은 기본적으로 인증되지 않은 Git HTTP 요청에 대한 속도 제한을 비활성화합니다.

인증 매개변수가 포함되지 않은 Git HTTP 요청에 속도 제한을 적용하려면 다음 속도 제한을 활성화하고 구성합니다:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **네트워크**를 선택합니다.
1. **Git HTTP 속도 제한**을 확장합니다.
1. **인증되지 않은 Git HTTP 요청 속도 제한 활성화**를 선택합니다.
1. **Max unauthenticated Git HTTP requests per period per user**에 값을 입력합니다.
1. **인증되지 않은 Git HTTP 속도 제한 기간(초)**에 값을 입력합니다.
1. **변경 사항 저장**을 선택합니다.

## 인증된 Git HTTP 속도 제한 구성 {#configure-authenticated-git-http-rate-limits}

{{< history >}}

- 인증된 Git HTTP 속도 제한 [GitLab 18.1에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/191552) [플래그](../feature_flags/_index.md) `git_authenticated_http_limit`. 기본적으로 비활성화됨.
- [GitLab.com, GitLab Self-Managed, GitLab Dedicated에서 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/543768) GitLab 18.3.
- GitLab 18.4에서 [정식 버전(GA)으로 제공됩니다](https://gitlab.com/gitlab-org/gitlab/-/issues/561577). 기능 플래그 `git_authenticated_http_limit` 제거됨.

{{< /history >}}

GitLab은 기본적으로 인증된 Git HTTP 요청에 대한 속도 제한을 비활성화합니다.

인증 매개변수가 포함된 Git HTTP 요청에 속도 제한을 적용하려면 다음 속도 제한을 활성화하고 구성합니다:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **네트워크**를 선택합니다.
1. **Git HTTP 속도 제한**을 확장합니다.
1. **인증된 Git HTTP 요청 속도 제한 활성화**를 선택합니다.
1. **Max authenticated Git HTTP requests per period per user**에 값을 입력합니다.
1. **인증된 Git HTTP 속도 제한 기간(초)**에 값을 입력합니다.
1. **변경 사항 저장**을 선택합니다.

필요한 경우 [특정 사용자가 인증된 요청 속도 제한을 무시하도록 허용](user_and_ip_rate_limits.md#allow-specific-users-to-bypass-authenticated-request-rate-limiting)할 수 있습니다.

## GitLab.com {#on-gitlabcom}

GitLab.com에서 Git HTTP 요청은 [Git HTTPS 요청 속도 제한](../../user/gitlab_com/_index.md#rate-limits-on-gitlabcom)의 적용을 받습니다:

- 인증된 사용자의 경우 분당 10,000개 요청.
- 인증되지 않은 IP 주소에서 분당 15,000개 요청.

## 관련 항목 {#related-topics}

- [속도 제한](../../security/rate_limits.md)
- [사용자 및 IP 속도 제한](user_and_ip_rate_limits.md)
