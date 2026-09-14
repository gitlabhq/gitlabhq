---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Analytics dashboards
description: 프로젝트와 그룹의 DevSecOps 및 AI 기능에 대한 메트릭을 시각화하고 성능 추세를 추적합니다.
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.9에서 [실험](../../policy/development_stages_support.md#experiment) 기능으로 [기능 플래그](../../administration/feature_flags/_index.md)와 함께 도입되었으며 이름은 `combined_analytics_dashboards`입니다. 기본적으로 비활성화되었습니다.
- `combined_analytics_dashboards`은 GitLab 16.11에서 [기본적으로 활성화되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/389067).
- `combined_analytics_dashboards`은 GitLab 17.1에서 [제거되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/454350).
- `filters` 구성은 GitLab 17.9에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/505317). 기본적으로 비활성화되었습니다.
- 인라인 시각화 구성은 GitLab 17.9에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/509111).
- GitLab 18.2에서 [GitLab Ultimate에서 GitLab Premium으로 이동](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/195086)되었습니다.

{{< /history >}}

분석 대시보드는 기본 제공 대시보드에서 수집된 데이터를 시각화할 수 있습니다.

향상된 대시보드 경험은 [에픽 13801](https://gitlab.com/groups/gitlab-org/-/epics/13801)과 [에픽 19430](https://gitlab.com/groups/gitlab-org/-/work_items/19430)에서 제안되었습니다.

## 데이터 소스 {#data-sources}

{{< history >}}

- 제품 분석 및 사용자 정의 시각화 데이터 소스는 GitLab 17.7에서 [제거되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/497577).

{{< /history >}}

데이터 소스는 대시보드 필터와 시각화에서 사용하여 쿼리하고 결과를 검색할 수 있는 데이터베이스 또는 데이터 컬렉션에 대한 연결입니다.

## 기본 제공 대시보드 {#built-in-dashboards}

분석을 시작하는 데 도움이 되도록 GitLab은 미리 정의된 시각화가 포함된 기본 제공 대시보드를 제공합니다. 이러한 대시보드는 **By GitLab**으로 표시됩니다.

다음 기본 제공 대시보드를 사용할 수 있습니다:

- [**가치 흐름 대시보드**](value_streams_dashboard.md)는 DevOps 성능, 보안 노출 및 작업 흐름 최적화와 관련된 메트릭을 표시합니다.
- [**GitLab Duo and SDLC trends**](duo_and_sdlc_trends.md)는 프로젝트 또는 그룹의 소프트웨어 개발 수명 주기(SDLC) 메트릭에 대한 AI 도구의 영향을 표시합니다.
- [**DORA Metrics Dashboard**](dora_metrics_charts.md)는 시간에 따른 각 DORA 메트릭의 진화를 표시합니다.
- [**머지 리퀘스트 분석**](merge_request_analytics.md)은 머지 리퀘스트 처리량 및 머지까지의 평균 시간에 대한 메트릭을 표시합니다.

## 프로젝트 대시보드 보기 {#view-project-dashboards}

전제 조건:

- 프로젝트에 대해 Reporter, Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

프로젝트의 대시보드 목록을 보려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **분석** > **분석 대시보드**를 선택합니다.
1. 사용 가능한 대시보드 목록에서 보려는 대시보드를 선택합니다.

## 그룹 대시보드 보기 {#view-group-dashboards}

전제 조건:

- 그룹에 대해 Reporter, Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

그룹의 대시보드 목록을 보려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **분석** > **분석 대시보드**를 선택합니다.
1. 사용 가능한 대시보드 목록에서 보려는 대시보드를 선택합니다.
