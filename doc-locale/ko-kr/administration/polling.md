---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: 폴링 간격 배수
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab UI는 리소스에 적합한 일정에 따라 다양한 리소스(예: 이슈 메모, 이슈 제목, 파이프라인 상태)의 업데이트를 폴링합니다.

GitLab UI가 업데이트를 폴링하는 빈도를 조정하기 위해 이러한 일정의 배수를 조정합니다. 배수를 다음으로 설정하면:

- `1`보다 큰 값으로 설정하면 UI 폴링이 느려집니다. 많은 클라이언트가 업데이트를 폴링하기 때문에 데이터베이스 로드 문제가 표시되는 경우, 배수를 늘리는 것이 폴링을 완전히 비활성화하는 대신 좋은 방법이 될 수 있습니다. 예를 들어 값을 `2`로 설정하면 모든 폴링 간격에 2를 곱합니다. 즉, 폴링이 절반의 빈도로 발생합니다.
- `0`과(와) `1` 사이의 값으로 설정하면 UI가 더 자주 폴링하므로 업데이트가 더 자주 발생합니다. **Not recommended**.
- `0`로 설정하면 모든 폴링이 비활성화됩니다. 다음 폴링 시 클라이언트가 업데이트 폴링을 중지합니다.

기본값(`1`)은 대부분의 GitLab 설치에 권장됩니다.

## 구성 {#configure}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

폴링 간격 배수를 조정하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **환경설정**을 선택합니다.
1. **폴링 간격 배수**를 확장합니다.
1. 폴링 간격 배수의 값을 설정합니다. 이 배수는 모든 리소스에 한 번에 적용됩니다.
1. **변경 사항 저장**을 선택합니다.
