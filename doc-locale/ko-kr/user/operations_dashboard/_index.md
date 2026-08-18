---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 작업 대시보드
---

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

운영 대시보드는 각 프로젝트의 운영 상태에 대한 요약을 제공하며, 파이프라인 및 경고 상태를 포함합니다.

대시보드에 액세스하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택합니다.
1. **귀하의 작업**을 선택합니다.
1. **운영**을 선택합니다.

## 대시보드에 프로젝트 추가하기 {#adding-a-project-to-the-dashboard}

대시보드에 프로젝트를 추가하려면:

1. 경고가 `gitlab_environment_name` 레이블을 [Prometheus에서 설정한 경고](../../operations/incident_management/integrations.md#expected-prometheus-request-attributes)에 입력되는지 확인합니다. 이 값은 GitLab의 환경 이름과 일치해야 합니다. `production` 환경에 대해서만 경고를 표시할 수 있습니다.
1. 대시보드의 홈 화면에서 **프로젝트 추가**를 선택합니다.
1. **프로젝트 검색** 필드를 사용하여 하나 이상의 프로젝트를 검색하고 추가합니다.
1. **프로젝트 추가**를 선택합니다.

추가되면 대시보드는 프로젝트의 활성 경고 수, 마지막 커밋, 파이프라인 상태 및 마지막 배포 시점을 표시합니다.

운영 및 [환경](../../ci/environments/environments_dashboard.md) 대시보드는 동일한 프로젝트 목록을 공유합니다. 한쪽에서 프로젝트를 추가하거나 제거하면 다른 쪽에서도 프로젝트가 추가되거나 제거됩니다.

![프로젝트가 있는 운영 대시보드](img/index_operations_dashboard_with_projects_v11_10.png)

## 대시보드에서 프로젝트 정렬하기 {#arranging-projects-on-a-dashboard}

프로젝트 카드를 드래그하여 순서를 변경할 수 있습니다. 카드 순서는 현재 브라우저에만 저장되므로 다른 사용자의 대시보드는 변경되지 않습니다.

## 로그인할 때 기본 대시보드로 설정하기 {#making-it-the-default-dashboard-when-you-sign-in}

운영 대시보드는 로그인할 때 표시되는 기본 GitLab 대시보드로도 설정할 수 있습니다. 기본값으로 설정하려면 [프로필 기본 설정](../profile/preferences.md)을 참조하세요.
