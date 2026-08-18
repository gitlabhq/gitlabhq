---
stage: Production Engineering
group: Runners Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "GitLab Dedicated의 GitLab 호스팅 러너에 대한 컴퓨팅 분, 사용 추적, 할당량 관리입니다."
title: GitLab Dedicated의 GitLab 호스팅 러너에 대한 컴퓨팅 사용량
---

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Dedicated

{{< /details >}}

GitLab Dedicated 인스턴스 러너는 GitLab Self-Managed 인스턴스 러너와 GitLab 호스팅 인스턴스 러너를 모두 가질 수 있습니다.

GitLab Dedicated 인스턴스의 관리자는 두 유형의 인스턴스 러너에서 작업을 실행하는 네임스페이스가 사용한 컴퓨팅 분을 추적하고 모니터링할 수 있습니다.

GitLab 호스팅 러너의 경우:

- [GitLab 호스팅 러너 사용량 대시보드](#view-compute-usage)에서 예상 사용량을 확인할 수 있습니다.
- 할당량 적용 및 알림은 사용할 수 없습니다.

GitLab Dedicated 인스턴스에 등록된 GitLab Self-Managed 인스턴스 러너는 [인스턴스 러너 사용량 보기](instance_runner_compute_minutes.md#view-usage)를 참조하세요.

## 컴퓨팅 사용량 보기 {#view-compute-usage}

{{< history >}}

- GitLab 호스팅 러너의 컴퓨팅 사용량 데이터는 GitLab 18.0에 [도입되었습니다](https://gitlab.com/groups/gitlab-com/gl-infra/gitlab-dedicated/-/epics/524).

{{< /history >}}

전제 조건:

- GitLab Dedicated 인스턴스의 관리자여야 합니다.

컴퓨팅 사용량을 볼 수 있습니다:

- 당월 전체 컴퓨팅 사용량입니다.
- 월별(연도와 러너로 필터링할 수 있음)입니다.
- 네임스페이스별(월 및 러너로 필터링할 수 있음)입니다.

전체 GitLab 인스턴스의 모든 네임스페이스에 대한 GitLab 호스팅 러너 컴퓨팅 사용량을 보려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **사용 할당량**을 선택합니다.
