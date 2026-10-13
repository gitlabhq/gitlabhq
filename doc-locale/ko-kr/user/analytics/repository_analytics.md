---
stage: Analytics
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 프로젝트의 리포지토리 분석
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

리포지토리 분석은 [GitLab Community Edition](https://gitlab.com/gitlab-org/gitlab-foss)의 일부이며 리포지토리를 복제할 수 있는 권한이 있는 사용자가 사용할 수 있습니다.

리포지토리 분석을 사용하여 프로젝트의 Git 리포지토리에 대한 정보를 확인합니다. 예를 들어:

- 리포지토리의 기본 브랜치에 사용된 프로그래밍 언어입니다.
- 지난 3개월간의 코드 커버리지 통계입니다.
- 지난 한 달간의 커밋 통계입니다.
- 월별 일자, 요일별, 시간별 커밋 수입니다.

## 차트 데이터 처리 {#chart-data-processing}

차트의 데이터는 대기 중입니다. 백그라운드 작업자는 기본 브랜치에 대한 각 커밋으로부터 10분 후에 차트를 업데이트합니다. GitLab 설치 크기 및 백그라운드 작업 대기열에 따라 데이터 새로 고침에 더 오래 걸릴 수 있습니다.

## 리포지토리 분석 보기 {#view-repository-analytics}

전제 조건:

- 초기화된 Git 리포지토리가 있어야 합니다.
- 기본 브랜치(`main` 기본값)에 최소 하나의 커밋이 있어야 하며, 분석에 포함되지 않는 프로젝트의 [wiki](../project/wiki/_index.md#track-wiki-events)의 커밋은 제외됩니다.

프로젝트의 리포지토리 분석을 보려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **분석** > **리포지토리 분석**을 선택합니다.
1. 카테고리에 대한 세부 정보를 보려면 차트의 막대 위에 마우스를 올립니다.
1. 특정 브랜치의 코드 커버리지 및 커밋 통계를 보려면 **Commit statistics** 옆의 드롭다운 목록에서 브랜치를 선택합니다.
