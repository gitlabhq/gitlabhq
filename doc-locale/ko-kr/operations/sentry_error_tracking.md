---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 프로젝트에서 오류 추적을 위해 Sentry를 GitLab에 연결합니다.
title: Sentry 오류 추적
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[Sentry](https://sentry.io/)는 오픈소스 오류 추적 시스템입니다. GitLab을 통해 관리자가 Sentry를 GitLab에 연결할 수 있으므로 사용자는 GitLab에서 Sentry 오류 목록을 볼 수 있습니다.

GitLab은 클라우드 호스팅 [Sentry](https://sentry.io)와 [온프레미스 인스턴스](https://github.com/getsentry/self-hosted)에 배포된 Sentry 모두와 통합됩니다.

## 프로젝트에 대해 Sentry 통합 활성화 {#enable-sentry-integration-for-a-project}

GitLab은 Sentry를 프로젝트에 연결하는 방법을 제공합니다.

전제 조건:

- 프로젝트에 대해 Maintainer 또는 Owner 역할이 필요합니다.

Sentry 통합을 활성화하려면:

1. Sentry.io에 가입하거나 자신의 [온프레미스 Sentry 인스턴스](https://github.com/getsentry/self-hosted)를 배포합니다.
1. [새로운 Sentry 프로젝트 생성](https://docs.sentry.io/product/sentry-basics/integrate-frontend/create-new-project/). 통합하려는 각 GitLab 프로젝트에 대해 새로운 Sentry 프로젝트를 생성합니다.
1. [Sentry 인증 토큰](https://docs.sentry.io/api/auth/#auth-tokens)을 찾거나 생성합니다. Sentry의 SaaS 버전의 경우 <https://sentry.io/api/>에서 인증 토큰을 찾거나 생성할 수 있습니다. 토큰에 최소한 다음 범위를 지정합니다: `project:read`, `event:read`, `event:write` (이벤트 해결용).
1. GitLab에서 오류 추적을 활성화하고 구성합니다:
   1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
   1. **설정** > **모니터링**을 선택한 후 **오류 추적**을 확장합니다.
   1. **오류 추적 활성화**에서 **활성**을 선택합니다.
   1. **오류 추적 백엔드**에서 **Sentry**를 선택합니다.
   1. **Sentry API URL**에 Sentry 호스트명을 입력합니다. 예를 들어 `https://sentry.example.com`을 입력합니다. Sentry의 SaaS 버전의 경우 호스트명은 `https://sentry.io`입니다. EU에서 호스팅되는 Sentry의 SaaS 버전의 경우 호스트명은 `https://de.sentry.io`입니다.
   1. **인증 토큰**에 이전에 생성한 토큰을 입력합니다.
   1. Sentry에 대한 연결을 테스트하고 **프로젝트** 드롭다운 목록을 채우려면 **연결**을 선택합니다.
   1. **프로젝트** 목록에서 GitLab 프로젝트에 링크할 Sentry 프로젝트를 선택합니다.
   1. **변경 사항 저장**을 선택합니다.

Sentry 오류 목록을 보려면 프로젝트의 사이드바에서 **모니터링** > **오류 추적**으로 이동합니다.

## GitLab과의 Sentry 통합 활성화 {#enable-sentrys-integration-with-gitlab}

[Sentry 설명서](https://docs.sentry.io/organization/integrations/source-code-mgmt/gitlab/)의 단계를 따라 Sentry의 GitLab 통합을 활성화할 수도 있습니다.

## 문제 해결 {#troubleshooting}

오류 추적 작업 시 다음 이슈가 발생할 수 있습니다.

### 오류 `Connection failed. Check auth token and try again` {#error-connection-failed-check-auth-token-and-try-again}

**모니터링** 기능이 [프로젝트 설정](../user/project/settings/_index.md#configure-project-features-and-permissions)에서 비활성화된 경우, [프로젝트에 대해 Sentry 통합을 활성화](#enable-sentry-integration-for-a-project)하려고 할 때 오류가 표시될 수 있습니다. `/project/path/-/error_tracking/projects.json?api_host=https:%2F%2Fsentry.example.com%2F&token=<token>`에 대한 결과 요청이 404 오류를 반환합니다.

이 이슈를 해결하려면 프로젝트에 대해 **모니터링** 기능을 활성화합니다.

### 오류 `Connection has failed. Re-check Auth Token and try again` {#error-connection-has-failed-re-check-auth-token-and-try-again}

온프레미스 Sentry 통합은 연결을 시도할 때 이 이슈가 발생할 수 있습니다.

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

이 이슈를 해결하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **네트워크**를 선택합니다.
1. **아웃바운드 요청**을 확장합니다.
1. **웹후크 및 통합에서 로컬 네트워크에 대한 요청 허용** 및 **시스템 후크에서 로컬 네트워크로의 요청 허용** 확인란을 선택합니다.
1. **변경 사항 저장**을 선택합니다.
