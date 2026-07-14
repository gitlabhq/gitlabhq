---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: 패키지 레지스트리 속도 제한
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[GitLab 패키지 레지스트리](../../user/packages/package_registry/_index.md)를 사용하면 GitLab을 다양한 일반 패키지 관리자의 비공개 또는 공개 레지스트리로 사용할 수 있습니다. 패키지를 게시하고 공유하면 다른 사용자가 [Packages API](../../api/packages.md)를 통해 다운스트림 프로젝트의 종속성으로 이를 사용할 수 있습니다.

다운스트림 프로젝트에서 이러한 종속성을 자주 다운로드하면 Packages API를 통해 많은 요청이 수행됩니다. 따라서 적용된 [사용자 및 IP 속도 제한](user_and_ip_rate_limits.md)에 도달할 수 있습니다. 이 문제를 해결하려면 Packages API에 대한 특정 속도 제한을 정의할 수 있습니다:

- [인증되지 않은 요청(IP당)](#enable-unauthenticated-request-rate-limit-for-packages-api).
- [인증된 API 요청(사용자당)](#enable-authenticated-api-request-rate-limit-for-packages-api).

이러한 제한은 기본적으로 비활성화되어 있습니다.

활성화하면 Packages API에 대한 요청에 대해 일반 사용자 및 IP 속도 제한을 대체합니다. 따라서 일반 사용자 및 IP 속도 제한을 유지하면서 Packages API에 대한 속도 제한을 늘릴 수 있습니다. 이러한 우선 순위를 제외하고는 일반 사용자 및 IP 속도 제한과 비교하여 기능에 차이가 없습니다.

## Packages API의 인증되지 않은 요청 속도 제한 활성화 {#enable-unauthenticated-request-rate-limit-for-packages-api}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

인증되지 않은 요청 속도 제한을 활성화하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **네트워크**를 선택합니다.
1. **패키지 레지스트리 속도 제한**을 확장합니다.
1. **Enable unauthenticated request rate limit**를 선택합니다.

   - 선택사항. **Maximum unauthenticated requests per rate limit period per IP** 값을 업데이트합니다. 기본값은 `800`입니다.
   - 선택사항. **Unauthenticated rate limit period in seconds** 값을 업데이트합니다. 기본값은 `15`입니다.

## Packages API의 인증된 API 요청 속도 제한 활성화 {#enable-authenticated-api-request-rate-limit-for-packages-api}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

인증된 API 요청 속도 제한을 활성화하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **네트워크**를 선택합니다.
1. **패키지 레지스트리 속도 제한**을 확장합니다.
1. **인증된 API 요청 속도 제한 활성화**를 선택합니다.

   - 선택사항. **사용자당 속도 제한 기간당 인증된 최대 API 요청** 값을 업데이트합니다. 기본값은 `1000`입니다.
   - 선택사항. **인증된 API 속도 제한 기간(초)** 값을 업데이트합니다. 기본값은 `15`입니다.
