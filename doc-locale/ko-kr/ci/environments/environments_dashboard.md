---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "여러 프로젝트 전체의 환경을 모니터링하며, 최신 커밋, 파이프라인 상태 및 배포 시간을 포함합니다."
title: 환경 대시보드
---

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

환경 대시보드는 각 환경에서 일어나고 있는 전체 상황을 볼 수 있도록 프로젝트 간 환경 기반 뷰를 제공합니다. 한 위치에서 개발에서 스테이징으로, 그리고 프로덕션으로 변경 사항이 흐르는 진행 상황을 추적할 수 있습니다(또는 설정할 수 있는 일련의 사용자 지정 환경 플로우를 통해). 여러 프로젝트를 한눈에 볼 수 있으므로, 어느 파이프라인이 정상(녹색)이고 어느 것이 오류(적색)인지 즉시 확인할 수 있어 특정 지점의 문제 여부를 진단하거나 더 심각한 문제가 있는지 조사할 수 있습니다.

1. 상단 표시줄에서 **검색 또는 이동**을 선택합니다.
1. **귀하의 작업**을(를) 선택합니다.
1. **환경**을(를) 선택합니다.

![배포 환경 및 파이프라인 상태가 표시된 두 행의 프로젝트를 보여주는 환경 대시보드입니다.](img/environments_dashboard_v18_8.png)

환경 대시보드는 프로젝트당 최대 3개의 환경을 포함하는 페이지가 매겨진 프로젝트 목록을 표시합니다.

각 프로젝트는 구성된 환경을 표시합니다. 검토 앱 및 기타 그룹화된 환경은 표시되지 않습니다.

## 대시보드에 프로젝트 추가 {#adding-a-project-to-the-dashboard}

대시보드에 프로젝트를 추가하려면:

1. 대시보드의 홈 화면에서 **프로젝트 추가**를 선택합니다.
1. **프로젝트 검색** 필드를 사용하여 하나 이상의 프로젝트를 검색하고 추가합니다.
1. **프로젝트 추가**를 선택합니다.

추가되면, 최신 커밋, 파이프라인 상태 및 배포 시간을 포함한 각 프로젝트의 환경 운영 상태 요약을 볼 수 있습니다.

환경 및 [작업](../../user/operations_dashboard/_index.md) 대시보드는 동일한 프로젝트 목록을 공유합니다. 한 대시보드에서 프로젝트를 추가하거나 제거하면 GitLab이 다른 대시보드에서도 프로젝트를 추가하거나 제거합니다.

이 대시보드에 표시할 최대 150개의 프로젝트를 추가할 수 있습니다.

## GitLab.com의 환경 대시보드 {#environment-dashboards-on-gitlabcom}

GitLab.com 사용자는 환경 대시보드에 공개 프로젝트를 무료로 추가할 수 있습니다. 프로젝트가 비공개인 경우, 해당 그룹은 [GitLab Premium](https://about.gitlab.com/pricing/) 플랜을 가져야 합니다.
