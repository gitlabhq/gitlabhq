---
stage: Production Engineering
group: Networking and Incident Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: 보호된 경로
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

속도 제한은 웹 애플리케이션의 보안 및 안정성을 개선하는 기술입니다. 자세한 내용은 [속도 제한](../../security/rate_limits.md)을 참조하세요.

지정된 경로에 속도 제한을 적용(보호)할 수 있습니다. 이러한 경로의 경우 GitLab은 분당 10개 요청을 초과하는 POST 요청 및 보호된 경로에서 분당 10개 요청을 초과하는 GET 요청에 HTTP 상태 코드 `429`로 응답합니다.

예를 들어 다음은 분당 최대 10개 요청으로 제한됩니다:

- 사용자 로그인
- 새 사용자 계정 생성(활성화된 경우)
- 사용자 암호 재설정

10개 요청 후 클라이언트는 다시 시도하기 전에 60초 동안 기다려야 합니다.

참고 항목:

- [기본적으로 보호된](../instance_limits.md#by-protected-path) 경로 목록입니다.
- [속도 제한 응답 헤더](user_and_ip_rate_limits.md#response-headers)(차단된 요청으로 반환됨)

## 보호된 경로 구성 {#configure-protected-paths}

보호된 경로의 제한은 기본적으로 활성화되어 있으며 비활성화하거나 사용자 지정할 수 있습니다.

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **네트워크**를 선택합니다.
1. **보호된 경로**를 확장하세요.

속도 제한을 초과하는 요청은 `auth.log`에 기록됩니다.
