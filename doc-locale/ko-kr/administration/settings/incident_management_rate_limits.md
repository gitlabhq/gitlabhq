---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 인바운드 인시던트 관리 알림에 대한 속도 제한을 구성합니다. 알림 과부하를 방지하기 위해 프로젝트당 최대 요청 수와 시간 범위를 설정합니다.
gitlab_dedicated: yes
title: 인시던트 관리 속도 제한
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

일정 기간 내에 생성할 수 있는 [인시던트](../../operations/incident_management/incidents.md)에 대한 인바운드 알림 수를 제한할 수 있습니다. 인바운드 [인시던트 관리](../../operations/incident_management/_index.md) 알림 제한은 알림 또는 중복된 이슈 수를 줄여 인시던트 대응자의 과부하를 방지하는 데 도움이 될 수 있습니다.

예를 들어 `10` 초마다 `60` 요청의 제한을 설정하고 `11` 요청이 1분 이내에 [알림 통합 엔드포인트](../../operations/incident_management/integrations.md)로 전송되면 11번째 요청이 차단됩니다. 1분 후 엔드포인트에 다시 액세스할 수 있습니다.

이 제한은 다음과 같습니다:

- 프로젝트별로 독립적으로 적용됩니다.
- IP 주소별로 적용되지 않습니다.
- 기본적으로 비활성화됨.

제한을 초과하는 요청은 `auth.log`에 기록됩니다.

## 인바운드 알림에 대한 제한 설정 {#set-a-limit-on-inbound-alerts}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

인바운드 인시던트 관리 알림 제한을 설정하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **네트워크**를 선택합니다.
1. **인시던트 관리 제한**을 확장합니다.
1. **Enable Incident Management inbound alert limit** 체크박스를 선택합니다.
1. 선택사항. **Maximum requests per project per rate limit period**에 대한 사용자 정의 값을 입력합니다. 기본값은 3600입니다.
1. 선택사항. **Rate limit period**에 대한 사용자 정의 값을 입력합니다. 기본값은 3600초입니다.
