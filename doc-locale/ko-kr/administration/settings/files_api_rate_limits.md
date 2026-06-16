---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
description: 리포지토리 파일 API에 대한 속도 제한을 구성합니다.
title: 리포지토리 파일 API의 속도 제한
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[리포지토리 파일 API](../../api/repository_files.md)를 사용하면 리포지토리의 파일을 가져오고, 생성하고, 업데이트하고, 삭제할 수 있습니다. 웹 애플리케이션의 보안과 내구성을 개선하기 위해 이 API에 [속도 제한](../../security/rate_limits.md)을 적용할 수 있습니다. Files API에 대해 생성하는 모든 속도 제한은 [일반 사용자 및 IP 속도 제한](user_and_ip_rate_limits.md)을 재정의합니다.

## Files API 속도 제한 정의 {#define-files-api-rate-limits}

Files API에 대한 속도 제한은 기본적으로 비활성화되어 있습니다. 활성화되면 [리포지토리 파일 API](../../api/repository_files.md)에 대한 요청의 일반 사용자 및 IP 속도 제한을 무시합니다. 이미 적용 중인 일반 사용자 및 IP 속도 제한은 유지하면서 Files API에 대한 속도 제한을 증가하거나 감소시킬 수 있습니다. 이 재정의에서 제공하는 다른 새로운 기능은 없습니다.

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

리포지토리 파일 API에 대한 요청의 일반 사용자 및 IP 속도 제한을 재정의하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **네트워크**를 선택합니다.
1. **Files API Rate Limits**을 펼칩니다.
1. 활성화할 속도 제한의 유형에 대한 확인란을 선택합니다:
   - **Unauthenticated API request rate limit**
   - **Authenticated API request rate limit**
1. **unauthenticated**을 선택한 경우:
   1. **Max unauthenticated API requests per period per IP**을 선택합니다.
   1. **인증되지 않은 API 속도 제한 기간(초)**을 선택합니다.
1. **authenticated**을 선택한 경우:
   1. **Max authenticated API requests per period per user**을 선택합니다.
   1. **인증된 API 속도 제한 기간(초)**을 선택합니다.

## 관련 항목 {#related-topics}

- [속도 제한](../../security/rate_limits.md)
- [리포지토리 파일 API](../../api/repository_files.md)
- [사용자 및 IP 속도 제한](user_and_ip_rate_limits.md)
