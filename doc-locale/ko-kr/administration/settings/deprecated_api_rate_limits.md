---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab의 사용 중단된 API에 대한 제한을 정의합니다.
gitlab_dedicated: yes
title: 사용 중단된 API 속도 제한
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

사용 중단된 API 엔드포인트는 대체 기능으로 교체되었지만 역호환성을 손상시키지 않고는 제거할 수 없습니다. 사용자가 대체 기능으로 전환하도록 권장하려면 사용 중단된 엔드포인트에 제한적인 속도 제한을 설정하세요.

## 사용 중단된 API 엔드포인트 {#deprecated-api-endpoints}

이 속도 제한에는 모든 사용 중단된 API 엔드포인트가 포함되지 않으며, 성능에 영향을 미칠 가능성이 높은 엔드포인트만 포함됩니다:

- [`GET /groups/:id`](../../api/groups.md#retrieve-a-group) 쿼리 매개변수 없음 `with_projects=0`

## 사용 중단된 API 속도 제한 정의 {#define-deprecated-api-rate-limits}

사용 중단된 API 엔드포인트에 대한 속도 제한은 기본적으로 비활성화됩니다. 활성화하면 사용 중단된 엔드포인트에 대한 요청의 일반 사용자 및 IP 속도 제한을 무시합니다. 기존의 일반 사용자 및 IP 속도 제한을 유지하고 사용 중단된 API 엔드포인트의 속도 제한을 늘리거나 줄일 수 있습니다. 이 재정의에서 제공하는 다른 새로운 기능은 없습니다.

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 필요합니다.

사용 중단된 API 엔드포인트에 대한 요청의 일반 사용자 및 IP 속도 제한을 무시하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **네트워크**를 선택하세요.
1. **Deprecated API Rate Limits**을 확장하세요.
1. 활성화할 속도 제한의 유형에 대한 체크박스를 선택하세요:
   - **Unauthenticated API request rate limit**
   - **Authenticated API request rate limit**
1. **unauthenticated**를 선택한 경우:
   1. **Maximum unauthenticated API requests per period per IP**를 선택하세요.
   1. **인증되지 않은 API 속도 제한 기간(초)**를 선택하세요.
1. **authenticated**를 선택한 경우:
   1. **Maximum authenticated API requests per period per user**를 선택하세요.
   1. **인증된 API 속도 제한 기간(초)**를 선택하세요.

## 관련 항목 {#related-topics}

- [속도 제한](../../security/rate_limits.md)
- [사용자 및 IP 속도 제한](user_and_ip_rate_limits.md)
